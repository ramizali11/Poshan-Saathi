import os
import hashlib
import secrets
import hmac
import time
import base64
import json

# Secret key for signing lightweight session tokens
SECRET_KEY = os.getenv("SECRET_KEY", "poshan_saathi_care_secret_key_2026_seva_first")

def generate_salt(length: int = 16) -> str:
    """Generates a secure random hexadecimal salt."""
    return secrets.token_hex(length)

def generate_otp_code() -> str:
    """
    Generates a cryptographically secure 6-digit numeric OTP.
    Uses CSPRNG (secrets.randbelow) providing uniform distribution between 000000 and 999999.
    """
    return f"{secrets.randbelow(1000000):06d}"

def hash_otp(otp: str, salt: str) -> str:
    """
    Hashes an OTP with a salt and the secret key using SHA-256 HMAC.
    Fast and cryptographically safe for 5-minute transient verification codes.
    """
    key = f"{SECRET_KEY}:{salt}".encode("utf-8")
    return hmac.new(key, otp.encode("utf-8"), hashlib.sha256).hexdigest()

def verify_otp(otp: str, salt: str, stored_hash: str) -> bool:
    """Verifies a submitted OTP against its stored hash using constant-time comparison."""
    computed_hash = hash_otp(otp, salt)
    return hmac.compare_digest(computed_hash, stored_hash)

def hash_password(password: str, salt: str) -> str:
    """
    Hashes a password with a salt using PBKDF2-HMAC-SHA256 (100,000 iterations).
    Cryptographically secure and standardized by NIST.
    """
    password_bytes = password.encode("utf-8")
    salt_bytes = salt.encode("utf-8")
    hashed_bytes = hashlib.pbkdf2_hmac(
        "sha256",
        password_bytes,
        salt_bytes,
        iterations=100000
    )
    return hashed_bytes.hex()

def verify_password(password: str, salt: str, stored_hash: str) -> bool:
    """Verifies a plain-text password against a stored hash using constant-time comparison."""
    computed_hash = hash_password(password, salt)
    return hmac.compare_digest(computed_hash, stored_hash)

def generate_token(user_id: int, phone: str) -> str:
    """Generates a signed, self-contained token containing user ID and timestamp."""
    payload = {
        "uid": user_id,
        "phone": phone,
        "iat": int(time.time()),
        "exp": int(time.time()) + (30 * 86400) # 30 days validity
    }
    raw_json = json.dumps(payload, separators=(',', ':')).encode("utf-8")
    b64_payload = base64.urlsafe_b64encode(raw_json).decode("utf-8").rstrip("=")
    
    # Signature
    signature = hmac.new(
        SECRET_KEY.encode("utf-8"),
        b64_payload.encode("utf-8"),
        hashlib.sha256
    ).hexdigest()
    
    return f"{b64_payload}.{signature}"

def verify_token(token: str) -> dict | None:
    """Verifies a signed token and returns the payload if valid."""
    try:
        parts = token.split(".")
        if len(parts) != 2:
            return None
        b64_payload, signature = parts
        
        # Verify signature
        expected_sig = hmac.new(
            SECRET_KEY.encode("utf-8"),
            b64_payload.encode("utf-8"),
            hashlib.sha256
        ).hexdigest()
        
        if not hmac.compare_digest(signature, expected_sig):
            return None
            
        # Add padding back if necessary
        padding = 4 - (len(b64_payload) % 4)
        if padding != 4:
            b64_payload += "=" * padding
            
        payload_bytes = base64.urlsafe_b64decode(b64_payload.encode("utf-8"))
        payload = json.loads(payload_bytes.decode("utf-8"))
        
        if payload.get("exp", 0) < time.time():
            return None # Expired
            
        return payload
    except Exception:
        return None

