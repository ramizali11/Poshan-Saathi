import os
import logging
from fastapi import APIRouter, HTTPException, Header, Query, status
from fastapi.responses import HTMLResponse
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
    generate_reset_token,
    hash_reset_token,
)
from ..email_service import send_otp_email, send_password_reset_email, mask_email
from ..oauth_service import verify_google_id_token, verify_apple_identity_token
from ..schemas import (
    UserRegisterRequest,
    UserLoginRequest,
    VerifyOtpRequest,
    ResendOtpRequest,
    ForgotPasswordRequest,
    ResetPasswordRequest,
    GoogleAuthRequest,
    AppleAuthRequest,
    UpdateProfileRequest,
    GenericMessageResponse,
    UserResponse,
    AuthResponse,
)

logger = logging.getLogger("poshan_saathi.auth")
router = APIRouter(prefix="/auth", tags=["Authentication"])

def clean_phone(phone: str) -> str:
    """Removes all non-digit characters and strips +91 country code if present."""
    digits = re.sub(r"\D", "", phone)
    if digits.startswith("91") and len(digits) > 10:
        digits = digits[2:]
    return digits

def is_valid_phone(phone: Optional[str]) -> bool:
    """
    Validates that a phone string is a genuine 10-digit mobile number,
    never a generated identifier (e.g., g_..., a_...) or arbitrary string.
    """
    if not phone:
        return False
    str_val = str(phone).strip()
    if str_val.startswith(("g_", "a_", "sub_", "id_")):
        return False
    clean = clean_phone(str_val)
    return len(clean) == 10 and clean.isdigit() and clean[0] in "6789"

def sanitize_phone_value(phone: Optional[str]) -> Optional[str]:
    """Sanitizes phone: returns genuine 10-digit phone or None if placeholder/identifier/invalid."""
    if is_valid_phone(phone):
        return clean_phone(str(phone))
    return None

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
    if req.phone.strip().startswith(("g_", "a_", "sub_", "id_")) or not is_valid_phone(req.phone):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Please provide a valid 10-digit mobile number starting with 6, 7, 8, or 9."
        )
    norm_phone = clean_phone(req.phone)

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
        email_sent, email_err, email_msg_id = send_otp_email(norm_email, req.name.strip(), otp)

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
            safe_phone = sanitize_phone_value(user_row["phone"])
            token = generate_token(user_row["id"], safe_phone)
            return AuthResponse(
                success=True,
                message="Your email is already verified. You can proceed.",
                token=token,
                user=UserResponse(
                    id=user_row["id"],
                    name=user_row["name"],
                    phone=safe_phone,
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

        safe_phone = sanitize_phone_value(user_row["phone"])
        token = generate_token(user_row["id"], safe_phone)
        user_data = UserResponse(
            id=user_row["id"],
            name=user_row["name"],
            phone=safe_phone,
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
        sent, err, msg_id = send_otp_email(norm_email, user_row["name"], new_otp)

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
            SELECT id, name, phone, email, password_hash, salt, role, language, state, district,
                   dob, gender, address, city, pin_code, avatar_url, auth_provider, is_verified, created_at
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
        safe_phone = sanitize_phone_value(row["phone"])
        if row["phone"] and not safe_phone:
            cursor.execute("UPDATE users SET phone = NULL WHERE id = ?", (user_id,))
            conn.commit()

        token = generate_token(user_id, safe_phone)

        user_data = UserResponse(
            id=user_id,
            name=row["name"],
            phone=safe_phone,
            email=row["email"],
            role=row["role"] or "parent",
            language=row["language"] or "ગુજરાતી (Gujarati)",
            state=row["state"],
            district=row["district"],
            dob=row["dob"],
            gender=row["gender"],
            address=row["address"],
            city=row["city"],
            pin_code=row["pin_code"],
            avatar_url=row["avatar_url"],
            auth_provider=row["auth_provider"] or "local",
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

@router.post("/forgot-password", response_model=GenericMessageResponse)
def forgot_password(req: ForgotPasswordRequest):
    """
    Initiates a password reset request.
    Always returns a neutral confirmation message to prevent account enumeration.
    If the account exists, generates a single-use token expiring in 15 minutes,
    stores its cryptographic hash, and sends an email via Resend.
    """
    generic_msg = "If an account exists for this email, you will receive a password reset link."
    norm_email = req.email.strip().lower()
    if not norm_email or "@" not in norm_email or "." not in norm_email:
        logger.info(f"[FORGOT-PASSWORD] Malformed email requested. Returning anti-enumeration response.")
        return GenericMessageResponse(success=True, message=generic_msg)

    logger.info(f"[FORGOT-PASSWORD] Received password reset request for: {mask_email(norm_email)}")

    with get_db() as conn:
        cursor = conn.cursor()

        cursor.execute("SELECT id, name FROM users WHERE email = ?", (norm_email,))
        user_row = cursor.fetchone()

        if not user_row:
            logger.info(f"[FORGOT-PASSWORD] Account not found for {mask_email(norm_email)}. Returning anti-enumeration response.")
            return GenericMessageResponse(success=True, message=generic_msg)

        now = datetime.now(timezone.utc)

        # Rate limit check: enforce 60-second cooldown between reset requests for this email
        cursor.execute("""
            SELECT created_at FROM password_resets
            WHERE email = ?
            ORDER BY id DESC LIMIT 1
        """, (norm_email,))
        last_reset = cursor.fetchone()
        if last_reset:
            last_dt = parse_iso_utc(last_reset["created_at"])
            if (now - last_dt).total_seconds() < 60:
                logger.info(f"[FORGOT-PASSWORD] Cooldown active (<60s) for {mask_email(norm_email)}. Throttling duplicate email.")
                # Return generic message without dispatching duplicate email to prevent spamming
                return GenericMessageResponse(success=True, message=generic_msg)

        # Invalidate any prior unused reset tokens for this email
        cursor.execute("UPDATE password_resets SET is_used = 1 WHERE email = ? AND is_used = 0", (norm_email,))

        # Generate unpredictable 256-bit URL-safe reset token
        token = generate_reset_token()
        token_hash = hash_reset_token(token)
        salt = generate_salt()
        expires_at = (now + timedelta(minutes=15)).isoformat()
        created_at = now.isoformat()

        # Store only the token hash, user ID, expiry, and unused status
        cursor.execute("""
            INSERT INTO password_resets (user_id, email, token_hash, salt, expires_at, created_at, is_used)
            VALUES (?, ?, ?, ?, ?, ?, 0)
        """, (user_row["id"], norm_email, token_hash, salt, expires_at, created_at))

        # Construct the reset URL using environment variable
        base_url = os.getenv("PASSWORD_RESET_URL", "https://poshan-saathi-1.onrender.com/api/auth/reset-password").strip().rstrip("/")
        reset_url = f"{base_url}?token={token}"

        # Dispatch email via Resend (never logging the token)
        sent, err, msg_id = send_password_reset_email(norm_email, user_row["name"], reset_url)

        if not sent:
            logger.error(f"❌ [FORGOT-PASSWORD ERROR]: Resend failed for {mask_email(norm_email)}: {err}")
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Unable to dispatch password reset email through the email provider. Please verify server email configuration or try again later."
            )

        logger.info(f"✅ [FORGOT-PASSWORD SUCCESS]: Reset email dispatched to {mask_email(norm_email)} | Provider Msg ID: {msg_id}")
        return GenericMessageResponse(success=True, message=generic_msg)

@router.post("/reset-password", response_model=GenericMessageResponse)
def reset_password(req: ResetPasswordRequest):
    """
    Validates single-use reset token hash, checks 15-minute expiry, validates new password,
    hashes password using PBKDF2-HMAC-SHA256, updates user credentials, and invalidates the token.
    """
    new_pwd = req.new_password.strip()
    if len(new_pwd) < 6:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="New password must be at least 6 characters long."
        )

    clean_token = req.token.strip()
    token_hash = hash_reset_token(clean_token)

    with get_db() as conn:
        cursor = conn.cursor()

        cursor.execute("""
            SELECT id, user_id, email, expires_at, is_used
            FROM password_resets
            WHERE token_hash = ?
            ORDER BY id DESC LIMIT 1
        """, (token_hash,))
        reset_record = cursor.fetchone()

        if not reset_record:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid or expired password reset link. Please request a new one."
            )

        if reset_record["is_used"] == 1:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="This password reset link has already been used. Please request a new link."
            )

        # Check 15-minute expiry
        expires_dt = parse_iso_utc(reset_record["expires_at"])
        if datetime.now(timezone.utc) > expires_dt:
            cursor.execute("UPDATE password_resets SET is_used = 1 WHERE id = ?", (reset_record["id"],))
            conn.commit()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="This password reset link has expired (15-minute limit). Please request a fresh reset link."
            )

        # Concurrency-safe atomic invalidation
        cursor.execute("""
            UPDATE password_resets
            SET is_used = 1
            WHERE id = ? AND is_used = 0
        """, (reset_record["id"],))
        if cursor.rowcount == 0:
            conn.commit()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="This password reset link was already used in another request."
            )

        # Securely hash new password with fresh salt
        new_salt = generate_salt()
        pwd_hash = hash_password(new_pwd, new_salt)

        # Update user in database & mark email verified
        cursor.execute("""
            UPDATE users
            SET password_hash = ?, salt = ?, is_verified = 1
            WHERE id = ?
        """, (pwd_hash, new_salt, reset_record["user_id"]))

        conn.commit()

        return GenericMessageResponse(
            success=True,
            message="Your password has been successfully reset! You can now log in with your new password."
        )

@router.get("/reset-password", response_class=HTMLResponse)
def reset_password_web_page(token: Optional[str] = Query(None)):
    """
    Serves an interactive web reset page that allows users to reset their password
    directly in any browser or open the mobile app via deep-link.
    """
    token_val = token.strip() if token else ""
    return f"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Reset Password - PoshanSaathi</title>
      <style>
        * {{ box-sizing: border-box; }}
        body {{
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
          background-color: #EEF2E9;
          margin: 0;
          padding: 24px 16px;
          display: flex;
          justify-content: center;
          align-items: center;
          min-height: 100vh;
          color: #181D17;
        }}
        .card {{
          background: #ffffff;
          border-radius: 20px;
          padding: 32px 24px;
          max-width: 440px;
          width: 100%;
          box-shadow: 0 10px 25px rgba(0,0,0,0.06);
          border: 1px solid #C3C8BF;
        }}
        .logo {{
          text-align: center;
          margin-bottom: 20px;
        }}
        .logo h1 {{
          margin: 0;
          font-size: 22px;
          color: #344C38;
          font-weight: 800;
        }}
        .logo p {{
          margin: 4px 0 0;
          font-size: 12px;
          color: #6B4F3A;
          font-weight: 600;
        }}
        h2 {{
          font-size: 18px;
          margin: 0 0 8px;
          color: #181D17;
        }}
        p.subtitle {{
          font-size: 13px;
          color: #434842;
          margin: 0 0 20px;
          line-height: 1.4;
        }}
        .form-group {{
          margin-bottom: 16px;
        }}
        label {{
          display: block;
          font-size: 12px;
          font-weight: 700;
          margin-bottom: 6px;
          color: #181D17;
        }}
        .input-wrap {{
          position: relative;
        }}
        input[type="password"], input[type="text"] {{
          width: 100%;
          padding: 12px 40px 12px 14px;
          border: 1px solid #C3C8BF;
          border-radius: 10px;
          font-size: 14px;
          outline: none;
          transition: border-color 0.2s;
        }}
        input:focus {{
          border-color: #526B55;
          box-shadow: 0 0 0 2px rgba(82, 107, 85, 0.2);
        }}
        .toggle-btn {{
          position: absolute;
          right: 12px;
          top: 50%;
          transform: translateY(-50%);
          background: none;
          border: none;
          cursor: pointer;
          font-size: 13px;
          color: #737871;
          padding: 0;
        }}
        .checklist {{
          background: #f7fafc;
          border-radius: 8px;
          padding: 10px 12px;
          margin-bottom: 18px;
          font-size: 11px;
          color: #737871;
        }}
        .check-item {{
          display: flex;
          align-items: center;
          margin-bottom: 4px;
        }}
        .check-item:last-child {{ margin-bottom: 0; }}
        .check-item.valid {{ color: #2E7D32; font-weight: 600; }}
        .btn-submit {{
          width: 100%;
          background: #526B55;
          color: #ffffff;
          border: none;
          border-radius: 10px;
          padding: 14px;
          font-size: 15px;
          font-weight: 700;
          cursor: pointer;
          transition: background 0.2s;
        }}
        .btn-submit:hover {{
          background: #344C38;
        }}
        .btn-submit:disabled {{
          background: #A8ADA4;
          cursor: not-allowed;
        }}
        .alert {{
          padding: 12px;
          border-radius: 8px;
          font-size: 13px;
          margin-bottom: 16px;
          display: none;
        }}
        .alert-error {{
          background: #FFEBEE;
          color: #D32F2F;
          border: 1px solid #FFCDD2;
        }}
        .alert-success {{
          background: #E8F5E9;
          color: #2E7D32;
          border: 1px solid #C8E6C9;
        }}
        .app-link-btn {{
          display: inline-block;
          margin-top: 14px;
          padding: 10px 16px;
          background: #CEEACE;
          color: #344C38;
          text-decoration: none;
          border-radius: 8px;
          font-size: 13px;
          font-weight: 700;
          text-align: center;
          width: 100%;
        }}
      </style>
    </head>
    <body>
      <div class="card">
        <div class="logo">
          <h1>🌱 PoshanSaathi</h1>
          <p>પોષણ સાથી • Child Nutrition Care</p>
        </div>

        <div id="alertBox" class="alert"></div>

        <div id="formSection">
          <h2>Create New Password</h2>
          <p class="subtitle">Enter your new secure password below to regain access to your caregiver account.</p>

          <form id="resetForm">
            <input type="hidden" id="token" value="{token_val}">

            <div class="form-group">
              <label for="newPassword">New Password</label>
              <div class="input-wrap">
                <input type="password" id="newPassword" placeholder="Minimum 6 characters" required autocomplete="new-password">
                <button type="button" class="toggle-btn" onclick="togglePass('newPassword')">Show</button>
              </div>
            </div>

            <div class="form-group">
              <label for="confirmPassword">Confirm New Password</label>
              <div class="input-wrap">
                <input type="password" id="confirmPassword" placeholder="Re-enter new password" required autocomplete="new-password">
                <button type="button" class="toggle-btn" onclick="togglePass('confirmPassword')">Show</button>
              </div>
            </div>

            <div class="checklist">
              <div id="cLen" class="check-item">● At least 6 characters</div>
              <div id="cMatch" class="check-item">● Passwords must match</div>
            </div>

            <button type="submit" id="submitBtn" class="btn-submit">Reset Password</button>
          </form>

          {f'<a href="poshansaathi://reset-password?token={token_val}" class="app-link-btn">📱 Open in PoshanSaathi App</a>' if token_val else ''}
        </div>

        <div id="successSection" style="display: none; text-align: center;">
          <h2 style="color: #2E7D32;">🎉 Password Reset Complete!</h2>
          <p class="subtitle">Your password has been successfully updated in the secure SQLite database. You can now log in using your new credentials.</p>
          <a href="poshansaathi://reset-password?completed=true" class="app-link-btn" style="background: #526B55; color: #fff;">Open App & Log In</a>
        </div>
      </div>

      <script>
        const tokenInput = document.getElementById('token');
        const newPass = document.getElementById('newPassword');
        const confirmPass = document.getElementById('confirmPassword');
        const cLen = document.getElementById('cLen');
        const cMatch = document.getElementById('cMatch');
        const submitBtn = document.getElementById('submitBtn');
        const alertBox = document.getElementById('alertBox');
        const formSection = document.getElementById('formSection');
        const successSection = document.getElementById('successSection');

        function togglePass(id) {{
          const input = document.getElementById(id);
          input.type = input.type === 'password' ? 'text' : 'password';
        }}

        function validate() {{
          const p1 = newPass.value;
          const p2 = confirmPass.value;

          const isLenValid = p1.length >= 6;
          const isMatchValid = p1.length > 0 && p1 === p2;

          cLen.className = isLenValid ? 'check-item valid' : 'check-item';
          cLen.textContent = (isLenValid ? '✓' : '●') + ' At least 6 characters';

          cMatch.className = isMatchValid ? 'check-item valid' : 'check-item';
          cMatch.textContent = (isMatchValid ? '✓' : '●') + ' Passwords match';

          return isLenValid && isMatchValid;
        }}

        newPass.addEventListener('input', validate);
        confirmPass.addEventListener('input', validate);

        document.getElementById('resetForm').addEventListener('submit', async (e) => {{
          e.preventDefault();
          alertBox.style.display = 'none';

          const token = tokenInput.value.trim();
          if (!token) {{
            alertBox.className = 'alert alert-error';
            alertBox.textContent = 'Reset token is missing. Please open the reset link from your email.';
            alertBox.style.display = 'block';
            return;
          }}

          if (!validate()) {{
            alertBox.className = 'alert alert-error';
            alertBox.textContent = 'Please make sure passwords match and meet the 6-character requirement.';
            alertBox.style.display = 'block';
            return;
          }}

          submitBtn.disabled = true;
          submitBtn.textContent = 'Updating Password...';

          try {{
            const response = await fetch('/api/auth/reset-password', {{
              method: 'POST',
              headers: {{ 'Content-Type': 'application/json' }},
              body: JSON.stringify({{ token: token, new_password: newPass.value }})
            }});

            const data = await response.json();

            if (response.ok) {{
              formSection.style.display = 'none';
              successSection.style.display = 'block';
            }} else {{
              alertBox.className = 'alert alert-error';
              alertBox.textContent = data.detail || 'Failed to reset password. The link may be expired.';
              alertBox.style.display = 'block';
              submitBtn.disabled = false;
              submitBtn.textContent = 'Reset Password';
            }}
          }} catch (err) {{
            alertBox.className = 'alert alert-error';
            alertBox.textContent = 'Network error. Please check your connection and try again.';
            alertBox.style.display = 'block';
            submitBtn.disabled = false;
            submitBtn.textContent = 'Reset Password';
          }}
        }});
      </script>
    </body>
    </html>
    """

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
            SELECT id, name, phone, email, role, language, state, district,
                   dob, gender, address, city, pin_code, avatar_url, auth_provider, is_verified, created_at
            FROM users
            WHERE id = ?
        """, (uid,))
        row = cursor.fetchone()

        if not row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User profile not found in database."
            )

        safe_phone = sanitize_phone_value(row["phone"])
        if row["phone"] and not safe_phone:
            cursor.execute("UPDATE users SET phone = NULL WHERE id = ?", (uid,))
            conn.commit()

        return UserResponse(
            id=row["id"],
            name=row["name"],
            phone=safe_phone,
            email=row["email"],
            role=row["role"] or "parent",
            language=row["language"] or "ગુજરાતી (Gujarati)",
            state=row["state"],
            district=row["district"],
            dob=row["dob"],
            gender=row["gender"],
            address=row["address"],
            city=row["city"],
            pin_code=row["pin_code"],
            avatar_url=row["avatar_url"],
            auth_provider=row["auth_provider"] or "local",
            is_verified=bool(row["is_verified"]),
            created_at=row["created_at"]
        )

@router.put("/profile", response_model=UserResponse)
@router.patch("/profile", response_model=UserResponse)
def update_profile(
    req: UpdateProfileRequest,
    authorization: Optional[str] = Header(None),
):
    """
    Updates the authenticated user's profile details.
    Only allows authenticated users (via Bearer token) to edit their own profile.
    Validates:
      - 10-digit phone number if provided (and enforces uniqueness against other accounts).
      - Rejects system identifiers (e.g. g_..., a_...) or arbitrary placeholder strings.
      - 6-digit PIN code if provided.
    """
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required. Please provide a valid Bearer token.",
        )

    token = authorization.split(" ")[1]
    payload = verify_token(token)
    if not payload or not payload.get("uid"):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired session token. Please log in again.",
        )

    user_id = payload["uid"]

    # Validate phone if provided
    norm_phone = None
    update_phone = False
    if req.phone is not None:
        update_phone = True
        raw_phone = req.phone.strip()
        if raw_phone:
            # Explicitly reject generated identifiers or placeholder formats
            if raw_phone.startswith(("g_", "a_", "sub_", "id_")):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Invalid mobile number. Google/system identifiers cannot be saved as phone numbers.",
                )
            if not is_valid_phone(raw_phone):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Please provide a valid 10-digit Indian mobile number (e.g., 9876543210).",
                )
            norm_phone = clean_phone(raw_phone)

    # Validate PIN code if provided
    norm_pin = None
    if req.pin_code is not None:
        clean_pin = req.pin_code.strip()
        if clean_pin:
            if len(clean_pin) != 6 or not clean_pin.isdigit():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Please provide a valid 6-digit postal PIN code.",
                )
            norm_pin = clean_pin

    with get_db() as conn:
        cursor = conn.cursor()

        # Verify user exists
        cursor.execute("SELECT id, phone FROM users WHERE id = ?", (user_id,))
        current_user = cursor.fetchone()
        if not current_user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User profile not found.",
            )

        # If phone is being changed/set, ensure it's not taken by another user
        if norm_phone:
            cursor.execute("SELECT id FROM users WHERE phone = ? AND id != ?", (norm_phone, user_id))
            if cursor.fetchone():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Mobile number {norm_phone} is already linked to another account.",
                )

        # Build dynamic update query
        updates = []
        params = []

        if req.name is not None and req.name.strip():
            updates.append("name = ?")
            params.append(req.name.strip())

        if update_phone:
            updates.append("phone = ?")
            params.append(norm_phone)

        if req.dob is not None:
            updates.append("dob = ?")
            params.append(req.dob.strip() if req.dob.strip() else None)

        if req.gender is not None:
            updates.append("gender = ?")
            params.append(req.gender.strip() if req.gender.strip() else None)

        if req.address is not None:
            updates.append("address = ?")
            params.append(req.address.strip() if req.address.strip() else None)

        if req.city is not None:
            updates.append("city = ?")
            params.append(req.city.strip() if req.city.strip() else None)

        if req.state is not None:
            updates.append("state = ?")
            params.append(req.state.strip() if req.state.strip() else None)

        if req.district is not None:
            updates.append("district = ?")
            params.append(req.district.strip() if req.district.strip() else None)

        if req.pin_code is not None:
            updates.append("pin_code = ?")
            params.append(norm_pin)

        if req.avatar_url is not None:
            updates.append("avatar_url = ?")
            params.append(req.avatar_url.strip() if req.avatar_url.strip() else None)

        if req.language is not None:
            updates.append("language = ?")
            params.append(req.language.strip() if req.language.strip() else None)

        if updates:
            params.append(user_id)
            cursor.execute(f"UPDATE users SET {', '.join(updates)} WHERE id = ?", tuple(params))
            conn.commit()

        # Fetch updated record
        cursor.execute("""
            SELECT id, name, phone, email, role, language, state, district,
                   dob, gender, address, city, pin_code, avatar_url, auth_provider, is_verified, created_at
            FROM users WHERE id = ?
        """, (user_id,))
        row = cursor.fetchone()

        return UserResponse(
            id=row["id"],
            name=row["name"],
            phone=row["phone"],
            email=row["email"],
            role=row["role"] or "parent",
            language=row["language"] or "ગુજરાતી (Gujarati)",
            state=row["state"],
            district=row["district"],
            dob=row["dob"],
            gender=row["gender"],
            address=row["address"],
            city=row["city"],
            pin_code=row["pin_code"],
            avatar_url=row["avatar_url"],
            auth_provider=row["auth_provider"] or "local",
            is_verified=bool(row["is_verified"]),
            created_at=row["created_at"],
        )

@router.get("/users", response_model=List[UserResponse])
def list_users():
    """
    Lists registered users from SQLite database (admin / verification endpoint).
    """
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT id, name, phone, email, role, language, state, district,
                   dob, gender, address, city, pin_code, avatar_url, auth_provider, is_verified, created_at
            FROM users
            ORDER BY id DESC
        """)
        rows = cursor.fetchall()
        return [
            UserResponse(
                id=r["id"],
                name=r["name"],
                phone=sanitize_phone_value(r["phone"]),
                email=r["email"],
                role=r["role"] or "parent",
                language=r["language"] or "ગુજરાતી (Gujarati)",
                state=r["state"],
                district=r["district"],
                dob=r["dob"],
                gender=r["gender"],
                address=r["address"],
                city=r["city"],
                pin_code=r["pin_code"],
                avatar_url=r["avatar_url"],
                auth_provider=r["auth_provider"] or "local",
                is_verified=bool(r["is_verified"]),
                created_at=r["created_at"]
            )
            for r in rows
        ]

@router.post("/google", response_model=AuthResponse)
def google_auth(req: GoogleAuthRequest):
    """
    Authenticates or registers a caregiver via verified Google ID Token.
    1. Cryptographically verifies Google ID Token signature and validity.
    2. Maps to existing oauth_accounts record or safely links to verified email account.
    3. If new user, creates active account with is_verified=1, phone=NULL (never placeholder).
    4. Issues standard application session token.
    """
    try:
        google_user = verify_google_id_token(req.id_token)
    except ValueError as ve:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Google authentication failed: {str(ve)}"
        )

    sub = google_user["sub"]
    email = google_user.get("email")
    name = google_user.get("name") or "Google User"
    picture = google_user.get("picture")

    with get_db() as conn:
        cursor = conn.cursor()

        # Step 1: Check if this Google account is already mapped in oauth_accounts
        cursor.execute("""
            SELECT user_id FROM oauth_accounts
            WHERE provider = 'google' AND provider_user_id = ?
        """, (sub,))
        oauth_row = cursor.fetchone()

        user_id = None
        if oauth_row:
            user_id = oauth_row["user_id"]
            # Clean legacy placeholder phone if present
            cursor.execute("""
                UPDATE users 
                SET phone = NULL 
                WHERE id = ? AND (phone LIKE 'g_%' OR phone LIKE 'a_%' OR phone LIKE 'sub_%')
            """, (user_id,))
            if picture:
                cursor.execute("UPDATE users SET avatar_url = COALESCE(avatar_url, ?) WHERE id = ?", (picture, user_id))
            conn.commit()
        elif email:
            # Step 2: Check if an existing account shares this verified email
            cursor.execute("SELECT id, is_verified FROM users WHERE email = ?", (email,))
            existing_user = cursor.fetchone()
            if existing_user:
                user_id = existing_user["id"]
                now_str = datetime.now(timezone.utc).isoformat()
                cursor.execute("""
                    INSERT OR IGNORE INTO oauth_accounts (user_id, provider, provider_user_id, email, created_at)
                    VALUES (?, 'google', ?, ?, ?)
                """, (user_id, sub, email, now_str))
                # Ensure is_verified is set to 1 and clean legacy placeholder phone
                cursor.execute("""
                    UPDATE users 
                    SET is_verified = 1,
                        phone = CASE WHEN phone LIKE 'g_%' OR phone LIKE 'a_%' OR phone LIKE 'sub_%' THEN NULL ELSE phone END,
                        avatar_url = COALESCE(avatar_url, ?) 
                    WHERE id = ?
                """, (picture, user_id))
                conn.commit()

        # Step 3: If user does not exist, create a new verified user account with NULL phone
        if not user_id:
            now = datetime.now(timezone.utc)
            created_at = now.isoformat()

            cursor.execute("""
                INSERT INTO users (name, phone, email, password_hash, salt, role, language, state, district,
                                  dob, gender, address, city, pin_code, avatar_url, is_verified, auth_provider, created_at)
                VALUES (?, NULL, ?, 'OAUTH_GOOGLE', 'OAUTH_SALT', ?, ?, ?, ?, NULL, NULL, NULL, NULL, NULL, ?, 1, 'google', ?)
            """, (
                name,
                email,
                req.role or "parent",
                req.language or "ગુજરાતી (Gujarati)",
                req.state,
                req.district,
                picture,
                created_at
            ))
            user_id = cursor.lastrowid

            cursor.execute("""
                INSERT INTO oauth_accounts (user_id, provider, provider_user_id, email, created_at)
                VALUES (?, 'google', ?, ?, ?)
            """, (user_id, sub, email, created_at))
            conn.commit()

        # Step 4: Fetch user record and return standard session token
        cursor.execute("""
            SELECT id, name, phone, email, role, language, state, district,
                   dob, gender, address, city, pin_code, avatar_url, auth_provider, is_verified, created_at
            FROM users WHERE id = ?
        """, (user_id,))
        user_row = cursor.fetchone()
        if not user_row:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Could not load authenticated user profile."
            )

        safe_phone = sanitize_phone_value(user_row["phone"])
        if user_row["phone"] and not safe_phone:
            cursor.execute("UPDATE users SET phone = NULL WHERE id = ?", (user_id,))
            conn.commit()

        token = generate_token(user_row["id"], safe_phone)
        return AuthResponse(
            success=True,
            message="Google Sign-In successful.",
            token=token,
            user=UserResponse(
                id=user_row["id"],
                name=user_row["name"],
                phone=safe_phone,
                email=user_row["email"],
                role=user_row["role"] or "parent",
                language=user_row["language"] or "ગુજરાતી (Gujarati)",
                state=user_row["state"],
                district=user_row["district"],
                dob=user_row["dob"],
                gender=user_row["gender"],
                address=user_row["address"],
                city=user_row["city"],
                pin_code=user_row["pin_code"],
                avatar_url=user_row["avatar_url"],
                auth_provider=user_row["auth_provider"] or "google",
                is_verified=True,
                created_at=user_row["created_at"]
            ),
            requires_verification=False,
            email=user_row["email"]
        )

@router.post("/apple", response_model=AuthResponse)
def apple_auth(req: AppleAuthRequest):
    """
    Authenticates or registers a caregiver via verified Apple Identity Token.
    1. Cryptographically verifies Apple JWT signature with Apple's JWKS.
    2. Handles Apple private relay email addresses and missing names on subsequent logins.
    3. Maps or safely links to user account in oauth_accounts.
    4. Issues standard application session token.
    """
    try:
        apple_user = verify_apple_identity_token(req.identity_token)
    except ValueError as ve:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Apple authentication failed: {str(ve)}"
        )

    sub = apple_user["sub"]
    # Email from token claims takes priority; fallback to request payload (sent on first authorization)
    email = apple_user.get("email") or (req.email.strip().lower() if req.email else None)

    # Compute full name if provided on first authorization
    first_name = (req.first_name or "").strip()
    last_name = (req.last_name or "").strip()
    full_name = f"{first_name} {last_name}".strip()
    if not full_name:
        full_name = "Apple User"

    with get_db() as conn:
        cursor = conn.cursor()

        # Step 1: Check oauth_accounts for existing Apple mapping
        cursor.execute("""
            SELECT user_id FROM oauth_accounts
            WHERE provider = 'apple' AND provider_user_id = ?
        """, (sub,))
        oauth_row = cursor.fetchone()

        user_id = None
        if oauth_row:
            user_id = oauth_row["user_id"]
        elif email:
            # Step 2: Check if an existing account shares this email
            cursor.execute("SELECT id FROM users WHERE email = ?", (email,))
            existing_user = cursor.fetchone()
            if existing_user:
                user_id = existing_user["id"]
                now_str = datetime.now(timezone.utc).isoformat()
                cursor.execute("""
                    INSERT OR IGNORE INTO oauth_accounts (user_id, provider, provider_user_id, email, created_at)
                    VALUES (?, 'apple', ?, ?, ?)
                """, (user_id, sub, email, now_str))
                cursor.execute("UPDATE users SET is_verified = 1 WHERE id = ?", (user_id,))
                conn.commit()

        # Step 3: Create new user if not found with NULL phone
        if not user_id:
            now = datetime.now(timezone.utc)
            created_at = now.isoformat()

            cursor.execute("""
                INSERT INTO users (name, phone, email, password_hash, salt, role, language, state, district,
                                  dob, gender, address, city, pin_code, avatar_url, is_verified, auth_provider, created_at)
                VALUES (?, NULL, ?, 'OAUTH_APPLE', 'OAUTH_SALT', ?, ?, ?, ?, NULL, NULL, NULL, NULL, NULL, NULL, 1, 'apple', ?)
            """, (
                full_name,
                email,
                req.role or "parent",
                req.language or "ગુજરાતી (Gujarati)",
                req.state,
                req.district,
                created_at
            ))
            user_id = cursor.lastrowid

            cursor.execute("""
                INSERT INTO oauth_accounts (user_id, provider, provider_user_id, email, created_at)
                VALUES (?, 'apple', ?, ?, ?)
            """, (user_id, sub, email, created_at))
            conn.commit()

        # Step 4: Fetch user record and return standard session token
        cursor.execute("""
            SELECT id, name, phone, email, role, language, state, district,
                   dob, gender, address, city, pin_code, avatar_url, auth_provider, is_verified, created_at
            FROM users WHERE id = ?
        """, (user_id,))
        user_row = cursor.fetchone()
        if not user_row:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Could not load authenticated user profile."
            )

        safe_phone = sanitize_phone_value(user_row["phone"])
        if user_row["phone"] and not safe_phone:
            cursor.execute("UPDATE users SET phone = NULL WHERE id = ?", (user_id,))
            conn.commit()

        token = generate_token(user_row["id"], safe_phone)
        return AuthResponse(
            success=True,
            message="Apple Sign-In successful.",
            token=token,
            user=UserResponse(
                id=user_row["id"],
                name=user_row["name"],
                phone=safe_phone,
                email=user_row["email"],
                role=user_row["role"] or "parent",
                language=user_row["language"] or "ગુજરાતી (Gujarati)",
                state=user_row["state"],
                district=user_row["district"],
                dob=user_row["dob"],
                gender=user_row["gender"],
                address=user_row["address"],
                city=user_row["city"],
                pin_code=user_row["pin_code"],
                avatar_url=user_row["avatar_url"],
                auth_provider=user_row["auth_provider"] or "apple",
                is_verified=True,
                created_at=user_row["created_at"]
            ),
            requires_verification=False,
            email=user_row["email"]
        )
