import os
import asyncio
import logging
from pathlib import Path
import dotenv
import httpx
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

logger = logging.getLogger("poshan_saathi.main")

# Load environment variables from app/.env, backend/.env, or root .env
app_dir = Path(__file__).resolve().parent
backend_dir = app_dir.parent
root_dir = backend_dir.parent

dotenv.load_dotenv(app_dir / ".env")
dotenv.load_dotenv(backend_dir / ".env")
dotenv.load_dotenv(root_dir / ".env")

from .database import init_db
from .routers import auth

async def keep_alive_task():
    """
    Periodic keep-alive heartbeat background task.
    Pings the health check endpoint at a configurable interval (default: 10 minutes = 600s).
    Supports RENDER_EXTERNAL_URL / BASE_URL if deployed, or localhost fallback.
    Shuts down cleanly when cancelled during lifespan termination.
    """
    port = os.getenv("PORT", "8000")
    target_url = os.getenv("RENDER_EXTERNAL_URL") or os.getenv("BASE_URL") or f"http://127.0.0.1:{port}"
    health_endpoint = f"{target_url.rstrip('/')}/health"
    interval_seconds = int(os.getenv("KEEPALIVE_INTERVAL_SECONDS", "600"))

    logger.info(f"🚀 [HEARTBEAT TASK] Started (Interval: {interval_seconds}s, Target: {health_endpoint})")

    try:
        while True:
            await asyncio.sleep(interval_seconds)
            try:
                async with httpx.AsyncClient(timeout=10.0) as client:
                    response = await client.get(health_endpoint)
                    logger.info(f"💓 [HEARTBEAT] Pinged {health_endpoint} -> HTTP {response.status_code}")
            except Exception as e:
                logger.warning(f"⚠️ [HEARTBEAT] Ping attempt failed: {e}")
    except asyncio.CancelledError:
        logger.info("🛑 [HEARTBEAT TASK] Shutdown requested, task cancelled cleanly.")
        raise

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: ensure SQLite database tables exist
    init_db()

    # Start the keep-alive heartbeat task once on application startup
    heartbeat_task = asyncio.create_task(keep_alive_task())

    try:
        yield
    finally:
        # Shutdown: cancel task cleanly and await termination
        heartbeat_task.cancel()
        try:
            await heartbeat_task
        except asyncio.CancelledError:
            pass
        logger.info("✅ [HEARTBEAT TASK] Background task stopped successfully.")

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

# Include Routers under both /api and root prefix to support all path conventions
app.include_router(auth.router, prefix="/api")
app.include_router(auth.router, prefix="")
app.include_router(auth.onboarding_router, prefix="/api")
app.include_router(auth.onboarding_router, prefix="")
app.include_router(auth.children_router, prefix="/api")
app.include_router(auth.children_router, prefix="")

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
