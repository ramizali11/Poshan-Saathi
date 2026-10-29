import os
import time
import logging
from typing import Dict, Any, Optional
import httpx
import jwt
from jwt.algorithms import RSAAlgorithm

logger = logging.getLogger("poshan_saathi.oauth")

# In-memory cache for Apple public JWKS keys: (timestamp, keys_list)
_apple_keys_cache: Dict[str, Any] = {"timestamp": 0, "keys": []}
APPLE_JWKS_URL = "https://appleid.apple.com/auth/keys"
APPLE_ISSUER = "https://appleid.apple.com"

# Optional environment variables for strict audience verification
GOOGLE_CLIENT_ID = os.getenv("GOOGLE_CLIENT_ID", "").strip()
APPLE_CLIENT_ID = os.getenv("APPLE_CLIENT_ID", "").strip()  # Bundle ID / Service ID


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


def get_apple_public_keys() -> list:
    """Retrieves Apple's public RSA JWKS keys, cached in memory for 1 hour."""
    now = time.time()
    if _apple_keys_cache["keys"] and (now - _apple_keys_cache["timestamp"] < 3600):
        return _apple_keys_cache["keys"]

    try:
        with httpx.Client(timeout=10.0) as client:
            resp = client.get(APPLE_JWKS_URL)
            if resp.status_code == 200:
                keys = resp.json().get("keys", [])
                _apple_keys_cache["keys"] = keys
                _apple_keys_cache["timestamp"] = now
                return keys
            else:
                logger.error(f"Failed to fetch Apple JWKS: HTTP {resp.status_code}")
                return _apple_keys_cache["keys"]
    except Exception as e:
        logger.error(f"Failed to fetch Apple JWKS: {e}")
        return _apple_keys_cache["keys"]


def verify_apple_identity_token(identity_token_str: str) -> Dict[str, Any]:
    """
    Cryptographically verifies an Apple Identity Token (JWT) using Apple's public RSA keys.
    Validates signature (RS256), issuer (https://appleid.apple.com), expiry, and audience.
    
    Returns:
        dict containing 'sub', 'email', 'email_verified'
    Raises:
        ValueError if token is invalid, expired, or forged.
    """
    if not identity_token_str or len(identity_token_str.strip()) < 10:
        raise ValueError("Apple identity token is required and cannot be empty.")

    clean_token = identity_token_str.strip()

    try:
        # Step 1: Decode header to get kid
        header = jwt.get_unverified_header(clean_token)
        kid = header.get("kid")
        if not kid:
            raise ValueError("Apple token header is missing key identifier (kid).")

        # Step 2: Match kid against Apple's public JWKS keys
        apple_keys = get_apple_public_keys()
        matching_key = None
        for k in apple_keys:
            if k.get("kid") == kid:
                matching_key = k
                break

        if not matching_key:
            # Force refresh cache once in case Apple rotated keys
            _apple_keys_cache["timestamp"] = 0
            refreshed_keys = get_apple_public_keys()
            for k in refreshed_keys:
                if k.get("kid") == kid:
                    matching_key = k
                    break

        if not matching_key:
            raise ValueError(f"No matching Apple public key found for kid: {kid}")

        # Step 3: Convert JWK to RSA public key
        public_key = RSAAlgorithm.from_jwk(matching_key)

        # Step 4: Verify and decode JWT
        audience = APPLE_CLIENT_ID if APPLE_CLIENT_ID else None
        decode_options = {
            "verify_signature": True,
            "verify_exp": True,
            "verify_iss": True,
            "verify_aud": bool(audience),
        }

        claims = jwt.decode(
            clean_token,
            key=public_key,
            algorithms=["RS256"],
            issuer=APPLE_ISSUER,
            audience=audience,
            options=decode_options,
        )

        sub = claims.get("sub")
        if not sub:
            raise ValueError("Apple token claims are missing 'sub'.")

        email = claims.get("email")
        email_verified = claims.get("email_verified")
        if isinstance(email_verified, str):
            email_verified = (email_verified.lower() == "true")

        return {
            "sub": str(sub),
            "email": str(email).lower() if email else None,
            "email_verified": bool(email_verified) if email_verified is not None else True,
            "is_private_email": bool(claims.get("is_private_email", False)),
        }
    except Exception as e:
        logger.error(f"❌ [APPLE AUTH ERROR]: {e}")
        raise ValueError(f"Invalid or expired Apple identity token: {e}")

