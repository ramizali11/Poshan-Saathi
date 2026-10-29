import os
from pathlib import Path
import dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

# Load environment variables from app/.env, backend/.env, or root .env
app_dir = Path(__file__).resolve().parent
backend_dir = app_dir.parent
root_dir = backend_dir.parent

dotenv.load_dotenv(app_dir / ".env")
dotenv.load_dotenv(backend_dir / ".env")
dotenv.load_dotenv(root_dir / ".env")

from .database import init_db
from .routers import auth

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: ensure SQLite database tables exist
    init_db()
    yield

app = FastAPI(
    title="PoshanSaathi - Child Nutrition API",
    description="Backend API for PoshanSaathi Child Nutrition Care platform with SQLite authentication.",
    version="1.0.0",
    lifespan=lifespan
)

# Enable CORS for Flutter app communication (emulator, physical device, local dev)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Auth Router
app.include_router(auth.router, prefix="/api")

@app.get("/")
def root():
    return {
        "message": "Welcome to the PoshanSaathi Child Nutrition API! API is running successfully.",
        "docs_url": "/docs",
        "auth_endpoints": {
            "register": "POST /api/auth/register",
            "login": "POST /api/auth/login",
            "me": "GET /api/auth/me",
            "users": "GET /api/auth/users"
        }
    }

@app.get("/health", tags=["Health"])
@app.head("/health", tags=["Health"])
def health():
    """
    Lightweight health-check endpoint for external uptime monitors and container orchestrators.
    Returns status 'ok' without exposing secrets, credentials, or personal information.
    """
    return {"status": "ok"}
