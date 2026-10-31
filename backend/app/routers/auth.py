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
from ..oauth_service import verify_google_id_token
from ..schemas import (
    UserRegisterRequest,
    UserLoginRequest,
    VerifyOtpRequest,
    ResendOtpRequest,
    ForgotPasswordRequest,
    ResetPasswordRequest,
    GoogleAuthRequest,
    UpdateProfileRequest,
    GenericMessageResponse,
    UserResponse,
    AuthResponse,
    OnboardingStep1Request,
    ChildCreateRequest,
    ChildUpdateRequest,
    ChildrenBatchCreateRequest,
    ChildResponse,
    HeightMeasurementCreate,
    HeightMeasurementUpdate,
    HeightMeasurementResponse,
)

logger = logging.getLogger("poshan_saathi.auth")
router = APIRouter(prefix="/auth", tags=["Authentication"])
onboarding_router = APIRouter(prefix="/onboarding", tags=["Onboarding"])
children_router = APIRouter(prefix="/children", tags=["Children"])

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

        # Insert new user into SQLite with is_verified = 0, and profile marked complete for standard email registration
        cursor.execute("""
            INSERT INTO users (name, phone, email, password_hash, salt, role, language, state, district, is_verified, is_profile_complete, onboarding_step, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 1, 2, ?)
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
            is_profile_complete=True,
            onboarding_step=2,
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
            SELECT id, name, phone, email, role, language, state, district, is_verified, is_profile_complete, onboarding_step, created_at
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
                    is_profile_complete=bool(user_row["is_profile_complete"]),
                    onboarding_step=int(user_row["onboarding_step"] or 0),
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
            is_profile_complete=bool(user_row["is_profile_complete"]),
            onboarding_step=int(user_row["onboarding_step"] or 0),
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
                   dob, gender, address, city, pin_code, avatar_url, auth_provider, is_verified,
                   is_profile_complete, onboarding_step, created_at
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
            is_profile_complete=bool(row["is_profile_complete"]),
            onboarding_step=int(row["onboarding_step"] or 0),
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
                   dob, gender, address, city, pin_code, avatar_url, auth_provider, is_verified,
                   is_profile_complete, onboarding_step, created_at
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
            is_profile_complete=bool(row["is_profile_complete"]),
            onboarding_step=int(row["onboarding_step"] or 0),
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
                   dob, gender, address, city, pin_code, avatar_url, auth_provider, is_verified,
                   is_profile_complete, onboarding_step, created_at
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
            is_profile_complete=bool(row["is_profile_complete"]),
            onboarding_step=int(row["onboarding_step"] or 0),
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
                   dob, gender, address, city, pin_code, avatar_url, auth_provider, is_verified,
                   is_profile_complete, onboarding_step, created_at
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
                is_profile_complete=bool(r["is_profile_complete"]),
                onboarding_step=int(r["onboarding_step"] or 0),
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
                                  dob, gender, address, city, pin_code, avatar_url, is_verified, auth_provider,
                                  is_profile_complete, onboarding_step, created_at)
                VALUES (?, NULL, ?, 'OAUTH_GOOGLE', 'OAUTH_SALT', ?, ?, ?, ?, NULL, NULL, NULL, NULL, NULL, ?, 1, 'google', 0, 0, ?)
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
                   dob, gender, address, city, pin_code, avatar_url, auth_provider, is_verified,
                   is_profile_complete, onboarding_step, created_at
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
                is_profile_complete=bool(user_row["is_profile_complete"]),
                onboarding_step=int(user_row["onboarding_step"] or 0),
                created_at=user_row["created_at"]
            ),
            requires_verification=False,
            email=user_row["email"]
        )

# ============================================================================
# Two-Step Onboarding & Children Management Endpoints
# ============================================================================

def get_authenticated_user_id(authorization: Optional[str]) -> int:
    """Extracts and verifies user_id from Bearer token payload."""
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
    return payload["uid"]

@router.post("/onboarding/step-1", response_model=UserResponse)
@router.put("/onboarding/step-1", response_model=UserResponse)
@onboarding_router.post("/step-1", response_model=UserResponse)
@onboarding_router.put("/step-1", response_model=UserResponse)
def onboarding_step_1(
    req: OnboardingStep1Request,
    authorization: Optional[str] = Header(None)
):
    """
    Step 1 of Onboarding: Updates Caregiver Profile Information.
    - Full Name: REQUIRED (non-empty).
    - Mobile Number: OPTIONAL (validated if provided, never saves fake IDs or placeholders).
    - Date of Birth, Gender, Address, City, State, District, PIN code: OPTIONAL.
    - Sets onboarding_step = 1.
    """
    user_id = get_authenticated_user_id(authorization)

    clean_name = req.name.strip()
    if not clean_name:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Full Name is required and cannot be blank.",
        )

    # Validate phone if entered
    norm_phone = None
    update_phone = False
    if req.phone is not None:
        update_phone = True
        raw_phone = req.phone.strip()
        if raw_phone:
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

    # Validate PIN code if entered
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
        cursor.execute("SELECT id, phone, email, onboarding_step FROM users WHERE id = ?", (user_id,))
        user_row = cursor.fetchone()
        if not user_row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User profile not found in database.",
            )

        # Check phone conflict if provided
        if norm_phone:
            cursor.execute("SELECT id FROM users WHERE phone = ? AND id != ?", (norm_phone, user_id))
            if cursor.fetchone():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Mobile number {norm_phone} is already linked to another account.",
                )

        # Dynamic query building
        updates = ["name = ?"]
        params = [clean_name]

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

        # Progress onboarding step to at least 1
        updates.append("onboarding_step = CASE WHEN COALESCE(onboarding_step, 0) < 1 THEN 1 ELSE onboarding_step END")

        params.append(user_id)
        cursor.execute(f"UPDATE users SET {', '.join(updates)} WHERE id = ?", tuple(params))
        conn.commit()

        # Fetch updated record
        cursor.execute("""
            SELECT id, name, phone, email, role, language, state, district,
                   dob, gender, address, city, pin_code, avatar_url, auth_provider, is_verified,
                   is_profile_complete, onboarding_step, created_at
            FROM users WHERE id = ?
        """, (user_id,))
        updated_row = cursor.fetchone()

        return UserResponse(
            id=updated_row["id"],
            name=updated_row["name"],
            phone=updated_row["phone"],
            email=updated_row["email"],
            role=updated_row["role"] or "parent",
            language=updated_row["language"] or "ગુજરાતી (Gujarati)",
            state=updated_row["state"],
            district=updated_row["district"],
            dob=updated_row["dob"],
            gender=updated_row["gender"],
            address=updated_row["address"],
            city=updated_row["city"],
            pin_code=updated_row["pin_code"],
            avatar_url=updated_row["avatar_url"],
            auth_provider=updated_row["auth_provider"] or "local",
            is_verified=bool(updated_row["is_verified"]),
            is_profile_complete=bool(updated_row["is_profile_complete"]),
            onboarding_step=int(updated_row["onboarding_step"] or 1),
            created_at=updated_row["created_at"],
        )

@router.post("/onboarding/step-2")
@onboarding_router.post("/step-2")
def onboarding_step_2(
    req: ChildrenBatchCreateRequest,
    authorization: Optional[str] = Header(None)
):
    """
    Step 2 of Onboarding: Saves Child/Children Details.
    - Supports multiple children.
    - Each child requires: name, dob, gender.
    - Weight (kg) is optional numeric.
    - Saves records linked with foreign key to authenticated parent (parent_id = uid).
    - Marks is_profile_complete = 1, onboarding_step = 2.
    """
    parent_id = get_authenticated_user_id(authorization)

    if not req.children:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="At least one child record is required. Or choose 'Skip' to add child details later.",
        )

    # Validate all children
    for idx, child in enumerate(req.children):
        if not child.name.strip():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Child #{idx + 1} name is required.",
            )
        if not child.dob.strip():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Child #{idx + 1} date of birth is required.",
            )
        clean_gender = child.gender.strip()
        if clean_gender not in ("Boy", "Girl", "Other"):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Child #{idx + 1} gender must be 'Boy', 'Girl', or 'Other'.",
            )

    created_children = []
    now_str = datetime.now(timezone.utc).isoformat()

    with get_db() as conn:
        cursor = conn.cursor()

        # Insert each child
        for child in req.children:
            cursor.execute("""
                INSERT INTO children (parent_id, name, dob, weight, gender, created_at)
                VALUES (?, ?, ?, ?, ?, ?)
            """, (
                parent_id,
                child.name.strip(),
                child.dob.strip(),
                child.weight,
                child.gender.strip(),
                now_str
            ))
            child_id = cursor.lastrowid

            # Also mirror into child_profiles for backwards compatibility
            cursor.execute("""
                INSERT INTO child_profiles (user_id, name, dob, current_weight_kg, gender, created_at)
                VALUES (?, ?, ?, ?, ?, ?)
            """, (
                parent_id,
                child.name.strip(),
                child.dob.strip(),
                child.weight,
                child.gender.strip(),
                now_str
            ))

            created_children.append(
                ChildResponse(
                    id=child_id,
                    parent_id=parent_id,
                    name=child.name.strip(),
                    dob=child.dob.strip(),
                    weight=child.weight,
                    gender=child.gender.strip(),
                    created_at=now_str
                )
            )

        # Mark user as profile complete and onboarding step 2 complete
        cursor.execute("""
            UPDATE users
            SET is_profile_complete = 1, onboarding_step = 2
            WHERE id = ?
        """, (parent_id,))
        conn.commit()

    return {
        "success": True,
        "message": f"Successfully registered {len(created_children)} child profile(s). Profile onboarding is complete!",
        "children": [c.model_dump() for c in created_children],
    }

@router.post("/onboarding/skip-step-2")
@onboarding_router.post("/skip-step-2")
def skip_onboarding_step_2(
    authorization: Optional[str] = Header(None)
):
    """
    Allows parent to skip Step 2 ("Add Later").
    Marks is_profile_complete = 1, onboarding_step = 2 so the user is not prompted again on subsequent logins.
    """
    parent_id = get_authenticated_user_id(authorization)

    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            UPDATE users
            SET is_profile_complete = 1, onboarding_step = 2
            WHERE id = ?
        """, (parent_id,))
        conn.commit()

    return {
        "success": True,
        "message": "Child profile addition postponed. Profile onboarding is complete.",
    }

@router.get("/children", response_model=List[ChildResponse])
@children_router.get("", response_model=List[ChildResponse])
@children_router.get("/", response_model=List[ChildResponse])
def get_children(
    authorization: Optional[str] = Header(None)
):
    """
    Retrieves all children belonging to the authenticated parent.
    Strictly isolated: parent_id is derived from verified token, ensuring Parent A cannot access Parent B's children.
    """
    parent_id = get_authenticated_user_id(authorization)

    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT id, parent_id, name, dob, weight, gender, created_at, updated_at
            FROM children
            WHERE parent_id = ?
            ORDER BY id ASC
        """, (parent_id,))
        rows = cursor.fetchall()

        return [
            ChildResponse(
                id=r["id"],
                parent_id=r["parent_id"],
                name=r["name"],
                dob=r["dob"],
                weight=r["weight"],
                gender=r["gender"],
                created_at=r["created_at"],
                updated_at=r["updated_at"]
            )
            for r in rows
        ]

@router.post("/children", response_model=ChildResponse)
@children_router.post("", response_model=ChildResponse)
@children_router.post("/", response_model=ChildResponse)
def add_single_child(
    req: ChildCreateRequest,
    authorization: Optional[str] = Header(None)
):
    """
    Adds a single child profile for the authenticated parent.
    """
    parent_id = get_authenticated_user_id(authorization)

    clean_name = req.name.strip()
    if not clean_name:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Child's name is required.")
    clean_dob = req.dob.strip()
    if not clean_dob:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Child's date of birth is required.")
    clean_gender = req.gender.strip()
    if clean_gender not in ("Boy", "Girl", "Other"):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Child gender must be 'Boy', 'Girl', or 'Other'.")

    now_str = datetime.now(timezone.utc).isoformat()
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO children (parent_id, name, dob, weight, gender, created_at)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (parent_id, clean_name, clean_dob, req.weight, clean_gender, now_str))
        child_id = cursor.lastrowid

        cursor.execute("""
            INSERT INTO child_profiles (user_id, name, dob, current_weight_kg, gender, created_at)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (parent_id, clean_name, clean_dob, req.weight, clean_gender, now_str))
        conn.commit()

        return ChildResponse(
            id=child_id,
            parent_id=parent_id,
            name=clean_name,
            dob=clean_dob,
            weight=req.weight,
            gender=clean_gender,
            created_at=now_str
        )

@router.patch("/children/{child_id}", response_model=ChildResponse)
@router.put("/children/{child_id}", response_model=ChildResponse)
@children_router.patch("/{child_id}", response_model=ChildResponse)
@children_router.put("/{child_id}", response_model=ChildResponse)
def update_child(
    child_id: int,
    req: ChildUpdateRequest,
    authorization: Optional[str] = Header(None)
):
    """
    Updates an existing child's information (such as weight, name, dob, gender).
    Enforces strict multi-tenancy: only the authenticated parent can update their own child.
    """
    parent_id = get_authenticated_user_id(authorization)

    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT id, parent_id, name, dob, weight, gender, created_at FROM children WHERE id = ? AND parent_id = ?", (child_id, parent_id))
        child_row = cursor.fetchone()
        if not child_row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Child profile not found or does not belong to the authenticated caregiver."
            )

        updates = []
        params = []

        if req.name is not None and req.name.strip():
            updates.append("name = ?")
            params.append(req.name.strip())

        if req.dob is not None and req.dob.strip():
            updates.append("dob = ?")
            params.append(req.dob.strip())

        if req.weight is not None:
            if req.weight <= 0 or req.weight > 100:
                raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Please enter a valid weight in kg (between 0.5 and 100).")
            updates.append("weight = ?")
            params.append(float(req.weight))

        if req.gender is not None and req.gender.strip():
            clean_gender = req.gender.strip()
            if clean_gender not in ("Boy", "Girl", "Other"):
                raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Child gender must be 'Boy', 'Girl', or 'Other'.")
            updates.append("gender = ?")
            params.append(clean_gender)

        now_str = datetime.now(timezone.utc).isoformat()
        updates.append("updated_at = ?")
        params.append(now_str)

        if updates:
            params.extend([child_id, parent_id])
            cursor.execute(f"UPDATE children SET {', '.join(updates)} WHERE id = ? AND parent_id = ?", tuple(params))

        # Also mirror into child_profiles if exists
        child_profile_updates = ["created_at = created_at"]
        cp_params = []
        if req.name is not None and req.name.strip():
            child_profile_updates.append("name = ?")
            cp_params.append(req.name.strip())
        if req.dob is not None and req.dob.strip():
            child_profile_updates.append("dob = ?")
            cp_params.append(req.dob.strip())
        if req.weight is not None:
            child_profile_updates.append("current_weight_kg = ?")
            cp_params.append(float(req.weight))
        if req.gender is not None and req.gender.strip():
            child_profile_updates.append("gender = ?")
            cp_params.append(req.gender.strip())
        if len(child_profile_updates) > 1:
            cp_params.extend([parent_id, child_row["name"]])
            cursor.execute(f"UPDATE child_profiles SET {', '.join(child_profile_updates)} WHERE user_id = ? AND name = ?", tuple(cp_params))

        conn.commit()

        # Fetch updated row
        cursor.execute("SELECT id, parent_id, name, dob, weight, gender, created_at, updated_at FROM children WHERE id = ?", (child_id,))
        updated_row = cursor.fetchone()

        return ChildResponse(
            id=updated_row["id"],
            parent_id=updated_row["parent_id"],
            name=updated_row["name"],
            dob=updated_row["dob"],
            weight=updated_row["weight"],
            gender=updated_row["gender"],
            created_at=updated_row["created_at"],
            updated_at=updated_row["updated_at"]
        )


# ============================================================================
# CHILD HEIGHT MEASUREMENT & GROWTH TRACKING ENDPOINTS
# ============================================================================

@router.get("/children/{child_id}/heights", response_model=List[HeightMeasurementResponse])
@children_router.get("/{child_id}/heights", response_model=List[HeightMeasurementResponse])
def get_child_height_measurements(
    child_id: int,
    authorization: Optional[str] = Header(None)
):
    """
    Retrieves all actual height measurements for a specific child.
    - Requires authenticated parent bearer token.
    - Strictly prevents unauthorized access across parents.
    - Calculates growth differences between consecutive chronological measurements.
    - Never fabricates random or synthetic measurements.
    """
    parent_id = get_authenticated_user_id(authorization)

    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT id FROM children WHERE id = ? AND parent_id = ?", (child_id, parent_id))
        child_row = cursor.fetchone()
        if not child_row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Child profile not found or does not belong to the authenticated caregiver."
            )

        cursor.execute("""
            SELECT id, child_id, parent_id, height_cm, measurement_date, notes, created_at, updated_at
            FROM child_height_measurements
            WHERE child_id = ? AND parent_id = ?
            ORDER BY measurement_date ASC, id ASC
        """, (child_id, parent_id))
        rows = cursor.fetchall()

        results: List[HeightMeasurementResponse] = []
        prev_height = None
        for row in rows:
            diff = None
            if prev_height is not None:
                diff = round(row["height_cm"] - prev_height, 2)
            prev_height = row["height_cm"]

            results.append(HeightMeasurementResponse(
                id=row["id"],
                child_id=row["child_id"],
                parent_id=row["parent_id"],
                height_cm=round(row["height_cm"], 2),
                measurement_date=row["measurement_date"],
                notes=row["notes"] or "",
                created_at=row["created_at"],
                updated_at=row["updated_at"],
                diff_from_previous=diff
            ))

        return results


@router.post("/children/{child_id}/heights", response_model=HeightMeasurementResponse, status_code=status.HTTP_201_CREATED)
@children_router.post("/{child_id}/heights", response_model=HeightMeasurementResponse, status_code=status.HTTP_201_CREATED)
def add_child_height_measurement(
    child_id: int,
    req: HeightMeasurementCreate,
    authorization: Optional[str] = Header(None)
):
    """
    Records a new accurate height measurement in centimetres (cm).
    - Validates positive, reasonable numeric value (20.0 cm to 250.0 cm).
    - Defaults measurement_date to today's date if missing.
    - Persists permanently to SQLite database without fabricating synthetic data.
    """
    parent_id = get_authenticated_user_id(authorization)

    if req.height_cm <= 20.0 or req.height_cm >= 250.0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Please enter a valid height measurement between 20.0 cm and 250.0 cm."
        )

    # Validate measurement date format (YYYY-MM-DD)
    meas_date = req.measurement_date.strip() if req.measurement_date else None
    if not meas_date:
        meas_date = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    else:
        try:
            datetime.strptime(meas_date, "%Y-%m-%d")
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Measurement date must follow YYYY-MM-DD format."
            )

    now_str = datetime.now(timezone.utc).isoformat()

    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT id FROM children WHERE id = ? AND parent_id = ?", (child_id, parent_id))
        child_row = cursor.fetchone()
        if not child_row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Child profile not found or does not belong to the authenticated caregiver."
            )

        cursor.execute("""
            INSERT INTO child_height_measurements (
                child_id, parent_id, height_cm, measurement_date, notes, created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (
            child_id,
            parent_id,
            round(req.height_cm, 2),
            meas_date,
            (req.notes or "").strip(),
            now_str,
            now_str
        ))
        new_id = cursor.lastrowid

        # Update child updated_at
        cursor.execute("UPDATE children SET updated_at = ? WHERE id = ?", (now_str, child_id))
        conn.commit()

        # Find preceding measurement to calculate diff
        cursor.execute("""
            SELECT height_cm FROM child_height_measurements
            WHERE child_id = ? AND parent_id = ? AND id != ? AND measurement_date <= ?
            ORDER BY measurement_date DESC, id DESC
            LIMIT 1
        """, (child_id, parent_id, new_id, meas_date))
        prev_row = cursor.fetchone()
        diff = None
        if prev_row:
            diff = round(req.height_cm - prev_row["height_cm"], 2)

        return HeightMeasurementResponse(
            id=new_id,
            child_id=child_id,
            parent_id=parent_id,
            height_cm=round(req.height_cm, 2),
            measurement_date=meas_date,
            notes=(req.notes or "").strip(),
            created_at=now_str,
            updated_at=now_str,
            diff_from_previous=diff
        )


@router.put("/children/{child_id}/heights/{measurement_id}", response_model=HeightMeasurementResponse)
@router.patch("/children/{child_id}/heights/{measurement_id}", response_model=HeightMeasurementResponse)
@children_router.put("/{child_id}/heights/{measurement_id}", response_model=HeightMeasurementResponse)
@children_router.patch("/{child_id}/heights/{measurement_id}", response_model=HeightMeasurementResponse)
def update_child_height_measurement(
    child_id: int,
    measurement_id: int,
    req: HeightMeasurementUpdate,
    authorization: Optional[str] = Header(None)
):
    """
    Updates an existing height measurement record.
    - Strictly authorized to the owning parent.
    """
    parent_id = get_authenticated_user_id(authorization)

    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT id, child_id, parent_id, height_cm, measurement_date, notes, created_at, updated_at
            FROM child_height_measurements
            WHERE id = ? AND child_id = ? AND parent_id = ?
        """, (measurement_id, child_id, parent_id))
        row = cursor.fetchone()
        if not row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Measurement record not found or unauthorized."
            )

        updates = []
        params = []

        if req.height_cm is not None:
            if req.height_cm <= 20.0 or req.height_cm >= 250.0:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Please enter a valid height measurement between 20.0 cm and 250.0 cm."
                )
            updates.append("height_cm = ?")
            params.append(round(req.height_cm, 2))

        if req.measurement_date is not None and req.measurement_date.strip():
            meas_date = req.measurement_date.strip()
            try:
                datetime.strptime(meas_date, "%Y-%m-%d")
            except ValueError:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Measurement date must follow YYYY-MM-DD format."
                )
            updates.append("measurement_date = ?")
            params.append(meas_date)

        if req.notes is not None:
            updates.append("notes = ?")
            params.append(req.notes.strip())

        now_str = datetime.now(timezone.utc).isoformat()
        updates.append("updated_at = ?")
        params.append(now_str)

        if updates:
            params.extend([measurement_id, child_id, parent_id])
            cursor.execute(f"""
                UPDATE child_height_measurements
                SET {', '.join(updates)}
                WHERE id = ? AND child_id = ? AND parent_id = ?
            """, tuple(params))
            conn.commit()

        cursor.execute("""
            SELECT id, child_id, parent_id, height_cm, measurement_date, notes, created_at, updated_at
            FROM child_height_measurements
            WHERE id = ?
        """, (measurement_id,))
        updated_row = cursor.fetchone()

        # Preceding diff
        cursor.execute("""
            SELECT height_cm FROM child_height_measurements
            WHERE child_id = ? AND parent_id = ? AND id != ? AND measurement_date <= ?
            ORDER BY measurement_date DESC, id DESC
            LIMIT 1
        """, (child_id, parent_id, measurement_id, updated_row["measurement_date"]))
        prev_row = cursor.fetchone()
        diff = None
        if prev_row:
            diff = round(updated_row["height_cm"] - prev_row["height_cm"], 2)

        return HeightMeasurementResponse(
            id=updated_row["id"],
            child_id=updated_row["child_id"],
            parent_id=updated_row["parent_id"],
            height_cm=round(updated_row["height_cm"], 2),
            measurement_date=updated_row["measurement_date"],
            notes=updated_row["notes"] or "",
            created_at=updated_row["created_at"],
            updated_at=updated_row["updated_at"],
            diff_from_previous=diff
        )


@router.delete("/children/{child_id}/heights/{measurement_id}", response_model=GenericMessageResponse)
@children_router.delete("/{child_id}/heights/{measurement_id}", response_model=GenericMessageResponse)
def delete_child_height_measurement(
    child_id: int,
    measurement_id: int,
    authorization: Optional[str] = Header(None)
):
    """
    Deletes an existing height measurement record.
    - Strictly authorized to the owning parent.
    """
    parent_id = get_authenticated_user_id(authorization)

    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT id FROM child_height_measurements
            WHERE id = ? AND child_id = ? AND parent_id = ?
        """, (measurement_id, child_id, parent_id))
        row = cursor.fetchone()
        if not row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Measurement record not found or unauthorized."
            )

        cursor.execute("""
            DELETE FROM child_height_measurements
            WHERE id = ? AND child_id = ? AND parent_id = ?
        """, (measurement_id, child_id, parent_id))
        conn.commit()

        return GenericMessageResponse(
            success=True,
            message="Height measurement deleted successfully."
        )
