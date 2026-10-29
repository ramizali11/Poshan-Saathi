from fastapi import APIRouter, HTTPException, Header, Query, status
from datetime import datetime
import re
from typing import Optional, List

from ..database import get_db
from ..security import generate_salt, hash_password, verify_password, generate_token, verify_token
from ..schemas import UserRegisterRequest, UserLoginRequest, UserResponse, AuthResponse

router = APIRouter(prefix="/auth", tags=["Authentication"])

def clean_phone(phone: str) -> str:
    """Removes all non-digit characters and strips +91 country code if present."""
    digits = re.sub(r"\D", "", phone)
    if digits.startswith("91") and len(digits) > 10:
        digits = digits[2:]
    return digits

@router.post("/register", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
def register(req: UserRegisterRequest):
    """
    Registers a new user and persists their profile and hashed password into the SQLite database.
    """
    norm_phone = clean_phone(req.phone)
    if len(norm_phone) < 10:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Please provide a valid 10-digit mobile number."
        )

    norm_email = req.email.strip().lower() if req.email else None

    with get_db() as conn:
        cursor = conn.cursor()

        # Check if phone number already exists
        cursor.execute("SELECT id FROM users WHERE phone = ?", (norm_phone,))
        if cursor.fetchone():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"User with mobile number {norm_phone} is already registered. Please log in."
            )

        # Check if email is provided and already exists
        if norm_email:
            cursor.execute("SELECT id FROM users WHERE email = ?", (norm_email,))
            if cursor.fetchone():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"User with email {norm_email} is already registered."
                )

        # Hash password securely
        salt = generate_salt()
        pwd_hash = hash_password(req.password, salt)
        created_at = datetime.utcnow().isoformat() + "Z"

        # Insert new user into SQLite database
        cursor.execute("""
            INSERT INTO users (name, phone, email, password_hash, salt, role, language, state, district, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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

        # Generate session token
        token = generate_token(user_id, norm_phone)

        user_data = UserResponse(
            id=user_id,
            name=req.name.strip(),
            phone=norm_phone,
            email=norm_email,
            role=req.role or "parent",
            language=req.language or "ગુજરાતી (Gujarati)",
            state=req.state or "Gujarat (ગુજરાત)",
            district=req.district or "Ahmedabad (અમદાવાદ)",
            created_at=created_at
        )

        return AuthResponse(
            success=True,
            message="User account created and saved to SQLite database successfully.",
            token=token,
            user=user_data
        )

@router.post("/login", response_model=AuthResponse)
def login(req: UserLoginRequest):
    """
    Authenticates a user against SQLite records using phone or email.
    """
    raw_id = req.identifier.strip()
    norm_phone = clean_phone(raw_id)
    norm_email = raw_id.lower()

    with get_db() as conn:
        cursor = conn.cursor()

        # Query user by phone or email
        cursor.execute("""
            SELECT id, name, phone, email, password_hash, salt, role, language, state, district, created_at
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
            created_at=row["created_at"]
        )

        return AuthResponse(
            success=True,
            message="Login successful.",
            token=token,
            user=user_data
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
            SELECT id, name, phone, email, role, language, state, district, created_at
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
            SELECT id, name, phone, email, role, language, state, district, created_at
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
                created_at=r["created_at"]
            )
            for r in rows
        ]

