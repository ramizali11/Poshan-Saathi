from fastapi import APIRouter, HTTPException, Header, Query, status
from datetime import datetime, timezone, timedelta
import re
from typing import Optional, List

from ..database import get_db
from ..security import (
    generate_salt,
    hash_password,
    verify_password,
    generate_token,
    verify_token,
    generate_otp_code,
    hash_otp,
    verify_otp,
)
from ..email_service import send_otp_email
from ..schemas import (
    UserRegisterRequest,
    UserLoginRequest,
    VerifyOtpRequest,
    ResendOtpRequest,
    UserResponse,
    AuthResponse,
)

router = APIRouter(prefix="/auth", tags=["Authentication"])

def clean_phone(phone: str) -> str:
    """Removes all non-digit characters and strips +91 country code if present."""
    digits = re.sub(r"\D", "", phone)
    if digits.startswith("91") and len(digits) > 10:
        digits = digits[2:]
    return digits

def parse_iso_utc(ts: str) -> datetime:
    """Safely parses an ISO-8601 string into a timezone-aware UTC datetime."""
    clean_ts = ts.replace("Z", "+00:00")
    dt = datetime.fromisoformat(clean_ts)
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt

@router.post("/register", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
def register(req: UserRegisterRequest):
    """
    Registers a new caregiver, persists profile with unverified status into SQLite,
    generates a cryptographically secure 5-minute OTP, and sends verification email via Resend.
    """
    norm_phone = clean_phone(req.phone)
    if len(norm_phone) < 10:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Please provide a valid 10-digit mobile number."
        )

    norm_email = req.email.strip().lower()
    if "@" not in norm_email or "." not in norm_email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Please provide a valid email address for OTP verification."
        )

    with get_db() as conn:
        cursor = conn.cursor()

        # Check if phone number already exists
        cursor.execute("SELECT id FROM users WHERE phone = ?", (norm_phone,))
        if cursor.fetchone():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"User with mobile number {norm_phone} is already registered. Please log in."
            )

        # Check if email already exists
        cursor.execute("SELECT id FROM users WHERE email = ?", (norm_email,))
        if cursor.fetchone():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"User with email {norm_email} is already registered. Please log in."
            )

        # Hash password securely
        salt = generate_salt()
        pwd_hash = hash_password(req.password, salt)
        now = datetime.now(timezone.utc)
        created_at = now.isoformat()

        # Insert new user into SQLite with is_verified = 0
        cursor.execute("""
            INSERT INTO users (name, phone, email, password_hash, salt, role, language, state, district, is_verified, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?)
        """, (
            req.name.strip(),
            norm_phone,
            norm_email,
            pwd_hash,
            salt,
            req.role or "parent",
            req.language or "ગુજરાતી (Gujarati)",
            req.state or "Gujarat (ગુજરાત)",
            req.district or "Ahmedabad (અમદાવાદ)",
            created_at
        ))
        user_id = cursor.lastrowid

        # Generate 6-digit cryptographically secure OTP
        otp = generate_otp_code()
        otp_salt = generate_salt()
        otp_hash = hash_otp(otp, otp_salt)

        expires_at = (now + timedelta(minutes=5)).isoformat()
        last_sent_at = now.isoformat()

        # Invalidate any old OTP records for this email
        cursor.execute("UPDATE email_otps SET is_used = 1 WHERE email = ? AND is_used = 0", (norm_email,))

        # Save secure OTP hash with expiry, attempt counters and cooldown timestamp
        cursor.execute("""
            INSERT INTO email_otps (user_id, email, otp_hash, salt, expires_at, attempts_count, max_attempts, created_at, last_sent_at, is_used)
            VALUES (?, ?, ?, ?, ?, 0, 5, ?, ?, 0)
        """, (user_id, norm_email, otp_hash, otp_salt, expires_at, created_at, last_sent_at))

        # Send email via Resend API
        email_sent, email_err = send_otp_email(norm_email, req.name.strip(), otp)

        user_data = UserResponse(
            id=user_id,
            name=req.name.strip(),
            phone=norm_phone,
            email=norm_email,
            role=req.role or "parent",
            language=req.language or "ગુજરાતી (Gujarati)",
            state=req.state or "Gujarat (ગુજરાત)",
            district=req.district or "Ahmedabad (અમદાવાદ)",
            is_verified=False,
            created_at=created_at
        )

        success_msg = f"Account created! A 6-digit verification code has been sent to {norm_email}."
        if not email_sent:
            success_msg = f"Account created! Note on email: {email_err or 'Please click resend code on the verification screen.'}"

        return AuthResponse(
            success=True,
            message=success_msg,
            token=None,  # No token until verified
            user=user_data,
            requires_verification=True,
            email=norm_email,
            cooldown_seconds=60
        )

@router.post("/verify-otp", response_model=AuthResponse)
def verify_otp_endpoint(req: VerifyOtpRequest):
    """
    Verifies the 6-digit OTP code against the salted hash in SQLite, enforces 5-min expiry,
    limits maximum attempts to 5, and marks the user as verified.
    """
    norm_email = req.email.strip().lower()
    clean_code = req.otp.strip()

    if len(clean_code) != 6 or not clean_code.isdigit():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Please enter a valid 6-digit numeric verification code."
        )

    with get_db() as conn:
        cursor = conn.cursor()

        # Find user record
        cursor.execute("""
            SELECT id, name, phone, email, role, language, state, district, is_verified, created_at
            FROM users
            WHERE email = ?
        """, (norm_email,))
        user_row = cursor.fetchone()

        if not user_row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"No account registered with email {norm_email}."
            )

        if user_row["is_verified"] == 1:
            token = generate_token(user_row["id"], user_row["phone"])
            return AuthResponse(
                success=True,
                message="Your email is already verified. You can proceed.",
                token=token,
                user=UserResponse(
                    id=user_row["id"],
                    name=user_row["name"],
                    phone=user_row["phone"],
                    email=user_row["email"],
                    role=user_row["role"] or "parent",
                    language=user_row["language"] or "ગુજરાતી (Gujarati)",
                    state=user_row["state"] or "Gujarat (ગુજરાત)",
                    district=user_row["district"] or "Ahmedabad (અમદાવાદ)",
                    is_verified=True,
                    created_at=user_row["created_at"]
                ),
                requires_verification=False,
                email=norm_email
            )

        # Retrieve active OTP
        cursor.execute("""
            SELECT id, user_id, otp_hash, salt, expires_at, attempts_count, max_attempts, is_used
            FROM email_otps
            WHERE email = ? AND is_used = 0
            ORDER BY id DESC
            LIMIT 1
        """, (norm_email,))
        otp_row = cursor.fetchone()

        if not otp_row:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No active verification code found for this email. Please request a new code."
            )

        # Check maximum attempts (limit: 5)
        if otp_row["attempts_count"] >= otp_row["max_attempts"]:
            cursor.execute("UPDATE email_otps SET is_used = 1 WHERE id = ?", (otp_row["id"],))
            conn.commit()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Maximum incorrect attempts (5) reached. This code is invalidated. Please request a new code."
            )

        # Check 5-minute expiry
        expires_at_dt = parse_iso_utc(otp_row["expires_at"])
        if datetime.now(timezone.utc) > expires_at_dt:
            cursor.execute("UPDATE email_otps SET is_used = 1 WHERE id = ?", (otp_row["id"],))
            conn.commit()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="This verification code has expired (validity: 5 minutes). Please click resend for a fresh code."
            )

        # Verify constant-time OTP hash
        is_correct = verify_otp(clean_code, otp_row["salt"], otp_row["otp_hash"])

        if not is_correct:
            new_attempts = otp_row["attempts_count"] + 1
            cursor.execute("UPDATE email_otps SET attempts_count = ? WHERE id = ?", (new_attempts, otp_row["id"]))
            remaining = max(0, otp_row["max_attempts"] - new_attempts)

            if remaining == 0:
                cursor.execute("UPDATE email_otps SET is_used = 1 WHERE id = ?", (otp_row["id"],))
                conn.commit()
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Incorrect verification code. Maximum attempts reached. Please request a fresh code."
                )

            conn.commit()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Incorrect verification code. {remaining} attempt(s) remaining."
            )

        # OTP verified! Mark OTP as used and user as verified
        cursor.execute("UPDATE email_otps SET is_used = 1 WHERE id = ?", (otp_row["id"],))
        cursor.execute("UPDATE users SET is_verified = 1 WHERE id = ?", (user_row["id"],))

        token = generate_token(user_row["id"], user_row["phone"])
        user_data = UserResponse(
            id=user_row["id"],
            name=user_row["name"],
            phone=user_row["phone"],
            email=user_row["email"],
            role=user_row["role"] or "parent",
            language=user_row["language"] or "ગુજરાતી (Gujarati)",
            state=user_row["state"] or "Gujarat (ગુજરાત)",
            district=user_row["district"] or "Ahmedabad (અમદાવાદ)",
            is_verified=True,
            created_at=user_row["created_at"]
        )

        return AuthResponse(
            success=True,
            message="Email verified successfully! Welcome to PoshanSaathi.",
            token=token,
            user=user_data,
            requires_verification=False,
            email=norm_email
        )

@router.post("/resend-otp", response_model=AuthResponse)
def resend_otp(req: ResendOtpRequest):
    """
    Enforces a 60-second resend cooldown, generates a new 5-minute cryptographically secure OTP,
    hashes and stores it in SQLite, and dispatches via Resend email API.
    """
    norm_email = req.email.strip().lower()

    with get_db() as conn:
        cursor = conn.cursor()

        # Find user
        cursor.execute("SELECT id, name, is_verified FROM users WHERE email = ?", (norm_email,))
        user_row = cursor.fetchone()

        if not user_row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"No account found registered with email {norm_email}."
            )

        if user_row["is_verified"] == 1:
            return AuthResponse(
                success=True,
                message="Your email is already verified. You can log in directly.",
                requires_verification=False,
                email=norm_email
            )

        # Check 60-second resend cooldown
        cursor.execute("""
            SELECT last_sent_at FROM email_otps
            WHERE email = ?
            ORDER BY id DESC
            LIMIT 1
        """, (norm_email,))
        last_otp = cursor.fetchone()

        now = datetime.now(timezone.utc)
        if last_otp:
            last_sent_dt = parse_iso_utc(last_otp["last_sent_at"])
            elapsed = (now - last_sent_dt).total_seconds()
            if elapsed < 60:
                wait_seconds = int(60 - elapsed)
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail=f"Please wait {wait_seconds} seconds before requesting another verification code."
                )

        # Invalidate previous active OTPs
        cursor.execute("UPDATE email_otps SET is_used = 1 WHERE email = ? AND is_used = 0", (norm_email,))

        # Generate fresh OTP
        new_otp = generate_otp_code()
        otp_salt = generate_salt()
        otp_hash = hash_otp(new_otp, otp_salt)

        expires_at = (now + timedelta(minutes=5)).isoformat()
        last_sent_at = now.isoformat()

        cursor.execute("""
            INSERT INTO email_otps (user_id, email, otp_hash, salt, expires_at, attempts_count, max_attempts, created_at, last_sent_at, is_used)
            VALUES (?, ?, ?, ?, ?, 0, 5, ?, ?, 0)
        """, (user_row["id"], norm_email, otp_hash, otp_salt, expires_at, last_sent_at, last_sent_at))

        # Send via Resend API
        sent, err = send_otp_email(norm_email, user_row["name"], new_otp)

        msg = f"A fresh 6-digit verification code has been sent to {norm_email}."
        if not sent:
            msg = f"Code generated! Email delivery note: {err}"

        return AuthResponse(
            success=True,
            message=msg,
            requires_verification=True,
            email=norm_email,
            cooldown_seconds=60
        )

@router.post("/login", response_model=AuthResponse)
def login(req: UserLoginRequest):
    """
    Authenticates a user against SQLite credentials and strictly enforces email verification.
    Unverified users receive a 403 Forbidden with instructions to verify.
    """
    raw_id = req.identifier.strip()
    norm_phone = clean_phone(raw_id)
    norm_email = raw_id.lower()

    with get_db() as conn:
        cursor = conn.cursor()

        # Query user by phone or email
        cursor.execute("""
            SELECT id, name, phone, email, password_hash, salt, role, language, state, district, is_verified, created_at
            FROM users
            WHERE phone = ? OR email = ?
        """, (norm_phone, norm_email))
        row = cursor.fetchone()

        if not row:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="No registered account found with this mobile number or email."
            )

        # Verify password
        if not verify_password(req.password, row["salt"], row["password_hash"]):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect password. Please verify and try again."
            )

        # Requirement 7: Prevent unverified users from logging in
        if row["is_verified"] != 1:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Email not verified. Please verify your email ({row['email']}) with the 6-digit code before logging in."
            )

        user_id = row["id"]
        token = generate_token(user_id, row["phone"])

        user_data = UserResponse(
            id=user_id,
            name=row["name"],
            phone=row["phone"],
            email=row["email"],
            role=row["role"] or "parent",
            language=row["language"] or "ગુજરાતી (Gujarati)",
            state=row["state"] or "Gujarat (ગુજરાત)",
            district=row["district"] or "Ahmedabad (અમદાવાદ)",
            is_verified=bool(row["is_verified"]),
            created_at=row["created_at"]
        )

        return AuthResponse(
            success=True,
            message="Login successful.",
            token=token,
            user=user_data,
            requires_verification=False,
            email=row["email"]
        )

@router.get("/me", response_model=UserResponse)
def get_current_user(
    authorization: Optional[str] = Header(None),
    user_id: Optional[int] = Query(None)
):
    """
    Retrieves the currently authenticated user details either by bearer token or user_id query.
    """
    uid: Optional[int] = user_id

    if authorization and authorization.startswith("Bearer "):
        token = authorization.split(" ")[1]
        payload = verify_token(token)
        if payload:
            uid = payload.get("uid")

    if not uid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication token or user_id is required."
        )

    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT id, name, phone, email, role, language, state, district, is_verified, created_at
            FROM users
            WHERE id = ?
        """, (uid,))
        row = cursor.fetchone()

        if not row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User profile not found in database."
            )

        return UserResponse(
            id=row["id"],
            name=row["name"],
            phone=row["phone"],
            email=row["email"],
            role=row["role"] or "parent",
            language=row["language"] or "ગુજરાતી (Gujarati)",
            state=row["state"] or "Gujarat (ગુજરાત)",
            district=row["district"] or "Ahmedabad (અમદાવાદ)",
            is_verified=bool(row["is_verified"]),
            created_at=row["created_at"]
        )

@router.get("/users", response_model=List[UserResponse])
def list_users():
    """
    Lists registered users from SQLite database (admin / verification endpoint).
    """
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT id, name, phone, email, role, language, state, district, is_verified, created_at
            FROM users
            ORDER BY id DESC
        """)
        rows = cursor.fetchall()
        return [
            UserResponse(
                id=r["id"],
                name=r["name"],
                phone=r["phone"],
                email=r["email"],
                role=r["role"] or "parent",
                language=r["language"] or "ગુજરાતી (Gujarati)",
                state=r["state"] or "Gujarat (ગુજરાત)",
                district=r["district"] or "Ahmedabad (અમદાવાદ)",
                is_verified=bool(r["is_verified"]),
                created_at=r["created_at"]
            )
            for r in rows
        ]
