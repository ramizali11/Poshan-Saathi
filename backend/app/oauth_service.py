import os
import logging
from typing import Dict, Any, Optional
import httpx

logger = logging.getLogger("poshan_saathi.oauth")

# Optional environment variable for strict audience verification
GOOGLE_CLIENT_ID = os.getenv("GOOGLE_CLIENT_ID", "").strip()


def verify_google_id_token(id_token_str: str) -> Dict[str, Any]:
    """
    Cryptographically verifies a Google ID token from the mobile or web client.
    First attempts verification using the official google-auth library.
    Falls back to Google's public tokeninfo verification endpoint.
    
    Returns:
        dict containing 'sub', 'email', 'name', 'picture', 'email_verified'
    Raises:
        ValueError if token is invalid, expired, or forged.
    """
    if not id_token_str or len(id_token_str.strip()) < 10:
        raise ValueError("Google ID token is required and cannot be empty.")

    clean_token = id_token_str.strip()
    audience = GOOGLE_CLIENT_ID if GOOGLE_CLIENT_ID else None

    # Method 1: Official Google Auth SDK verification
    try:
        from google.oauth2 import id_token as google_id_token
        from google.auth.transport import requests as google_requests

        req = google_requests.Request()
        id_info = google_id_token.verify_oauth2_token(
            clean_token,
            req,
            audience=audience
        )

        iss = id_info.get("iss", "")
        if iss not in ("accounts.google.com", "https://accounts.google.com"):
            raise ValueError(f"Invalid Google token issuer: {iss}")

        sub = id_info.get("sub")
        email = id_info.get("email")
        if not sub:
            raise ValueError("Google token is missing 'sub' identifier.")

        return {
            "sub": str(sub),
            "email": str(email).lower() if email else None,
            "email_verified": bool(id_info.get("email_verified", True)),
            "name": id_info.get("name") or "Google User",
            "picture": id_info.get("picture"),
        }
    except Exception as sdk_err:
        logger.warning(f"Google SDK verify note: {sdk_err}. Checking Google tokeninfo endpoint...")

    # Method 2: Google's direct tokeninfo endpoint
    try:
        with httpx.Client(timeout=10.0) as client:
            resp = client.get("https://oauth2.googleapis.com/tokeninfo", params={"id_token": clean_token})
            if resp.status_code != 200:
                raise ValueError(f"Google token verification failed with status {resp.status_code}: {resp.text}")

            payload = resp.json()

            # Verify issuer
            iss = payload.get("iss", "")
            if iss not in ("accounts.google.com", "https://accounts.google.com"):
                raise ValueError(f"Invalid Google token issuer: {iss}")

            # Verify audience if configured
            if audience and payload.get("aud") != audience:
                raise ValueError(f"Google token audience mismatch: expected {audience}, got {payload.get('aud')}")

            sub = payload.get("sub")
            if not sub:
                raise ValueError("Google token is missing 'sub' identifier.")

            email = payload.get("email")
            email_verified = payload.get("email_verified")
            if isinstance(email_verified, str):
                email_verified = (email_verified.lower() == "true")

            return {
                "sub": str(sub),
                "email": str(email).lower() if email else None,
                "email_verified": bool(email_verified),
                "name": payload.get("name") or "Google User",
                "picture": payload.get("picture"),
            }
    except Exception as endpoint_err:
        logger.error(f"❌ [GOOGLE AUTH ERROR]: {endpoint_err}")
        raise ValueError(f"Invalid or expired Google credential: {endpoint_err}")


