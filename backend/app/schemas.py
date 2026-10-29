from pydantic import BaseModel, Field
from typing import Optional

class UserRegisterRequest(BaseModel):
    name: str = Field(..., min_length=1, description="Full Name of the user")
    phone: str = Field(..., min_length=10, description="Mobile number (10 digits)")
    email: Optional[str] = Field(None, description="Optional email address")
    password: str = Field(..., min_length=4, description="User password")
    role: Optional[str] = Field("parent", description="User role: parent, clinician, or admin")
    language: Optional[str] = Field("ગુજરાતી (Gujarati)", description="Preferred language")
    state: Optional[str] = Field("Gujarat (ગુજરાત)", description="State")
    district: Optional[str] = Field("Ahmedabad (અમદાવાદ)", description="District")

class UserLoginRequest(BaseModel):
    identifier: str = Field(..., description="Mobile number or Email address")
    password: str = Field(..., description="Password")

class UserResponse(BaseModel):
    id: int
    name: str
    phone: str
    email: Optional[str] = None
    role: str = "parent"
    language: str = "ગુજરાતી (Gujarati)"
    state: str = "Gujarat (ગુજરાત)"
    district: str = "Ahmedabad (અમદાવાદ)"
    created_at: str

class AuthResponse(BaseModel):
    success: bool
    message: str
    token: Optional[str] = None
    user: Optional[UserResponse] = None

