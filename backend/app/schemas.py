from pydantic import BaseModel, Field
from typing import Optional

class UserRegisterRequest(BaseModel):
    name: str = Field(..., min_length=1, description="Full Name of the user")
    phone: str = Field(..., min_length=10, description="Mobile number (10 digits)")
    email: str = Field(..., min_length=5, description="Email address for 6-digit OTP verification")
    password: str = Field(..., min_length=4, description="User password")
    role: Optional[str] = Field("parent", description="User role: parent, clinician, or admin")
    language: Optional[str] = Field("ગુજરાતી (Gujarati)", description="Preferred language")
    state: Optional[str] = Field("Gujarat (ગુજરાત)", description="State")
    district: Optional[str] = Field("Ahmedabad (અમદાવાદ)", description="District")

class UserLoginRequest(BaseModel):
    identifier: str = Field(..., description="Mobile number or Email address")
    password: str = Field(..., description="Password")

class VerifyOtpRequest(BaseModel):
    email: str = Field(..., description="Registered email address to verify")
    otp: str = Field(..., min_length=6, max_length=6, description="6-digit verification code")

class ResendOtpRequest(BaseModel):
    email: str = Field(..., description="Registered email address requesting a new OTP")

class ForgotPasswordRequest(BaseModel):
    email: str = Field(..., min_length=3, description="Registered email address")

class ResetPasswordRequest(BaseModel):
    token: str = Field(..., min_length=10, description="Single-use password reset token")
    new_password: str = Field(..., min_length=6, description="New password (minimum 6 characters)")

class GoogleAuthRequest(BaseModel):
    id_token: str = Field(..., min_length=10, description="Google ID Token (JWT) obtained from Google Sign-In SDK")
    role: Optional[str] = Field("parent", description="User role: parent or clinician")
    language: Optional[str] = Field(None, description="Preferred language")
    state: Optional[str] = Field(None, description="State")
    district: Optional[str] = Field(None, description="District")

class AppleAuthRequest(BaseModel):
    identity_token: str = Field(..., min_length=10, description="Apple Identity Token (JWT) from Apple Sign-In")
    authorization_code: Optional[str] = Field(None, description="Apple authorization code")
    first_name: Optional[str] = Field(None, description="Given name (sent only on first login)")
    last_name: Optional[str] = Field(None, description="Family name (sent only on first login)")
    email: Optional[str] = Field(None, description="Email address (sent only on first login or private relay)")
    role: Optional[str] = Field("parent", description="User role: parent or clinician")
    language: Optional[str] = Field(None, description="Preferred language")
    state: Optional[str] = Field(None, description="State")
    district: Optional[str] = Field(None, description="District")

class UpdateProfileRequest(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=100, description="Full Name")
    phone: Optional[str] = Field(None, description="10-digit mobile number")
    dob: Optional[str] = Field(None, description="Date of birth (YYYY-MM-DD)")
    gender: Optional[str] = Field(None, description="Gender (Female, Male, Other)")
    address: Optional[str] = Field(None, max_length=250, description="Residential Address")
    city: Optional[str] = Field(None, max_length=100, description="City / Town")
    state: Optional[str] = Field(None, max_length=100, description="State")
    district: Optional[str] = Field(None, max_length=100, description="District")
    pin_code: Optional[str] = Field(None, description="Postal PIN Code (6 digits)")
    avatar_url: Optional[str] = Field(None, description="Profile picture URL")
    language: Optional[str] = Field(None, description="Preferred language")

class GenericMessageResponse(BaseModel):
    success: bool
    message: str

class UserResponse(BaseModel):
    id: int
    name: str
    phone: Optional[str] = None
    email: Optional[str] = None
    role: str = "parent"
    language: Optional[str] = None
    state: Optional[str] = None
    district: Optional[str] = None
    dob: Optional[str] = None
    gender: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    pin_code: Optional[str] = None
    avatar_url: Optional[str] = None
    auth_provider: Optional[str] = "local"
    is_verified: bool = False
    created_at: str

class AuthResponse(BaseModel):
    success: bool
    message: str
    token: Optional[str] = None
    user: Optional[UserResponse] = None
    requires_verification: Optional[bool] = False
    email: Optional[str] = None
    cooldown_seconds: Optional[int] = None
