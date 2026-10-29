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

class GenericMessageResponse(BaseModel):
    success: bool
    message: str

class UserResponse(BaseModel):
    id: int
    name: str
    phone: str
    email: Optional[str] = None
    role: str = "parent"
    language: str = "ગુજરાતી (Gujarati)"
    state: str = "Gujarat (ગુજરાત)"
    district: str = "Ahmedabad (અમદાવાદ)"
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
