import os
import sqlite3
from typing import Generator
from contextlib import contextmanager

# Determine path for the SQLite database
# Placed in the backend root directory so it persists and is easily discoverable
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DB_PATH = os.getenv("DB_PATH", os.path.join(BASE_DIR, "poshan_saathi.db"))

def get_db_connection() -> sqlite3.Connection:
    """Returns a SQLite connection with row_factory set to sqlite3.Row for dict-like access."""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    # Enable foreign keys
    conn.execute("PRAGMA foreign_keys = ON;")
    return conn

@contextmanager
def get_db():
    """Context manager for SQLite database transactions."""
    conn = get_db_connection()
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()

def init_db():
    """Initializes SQLite database tables if they do not exist."""
    with get_db() as conn:
        cursor = conn.cursor()
        
        # Create users table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                phone TEXT UNIQUE NOT NULL,
                email TEXT,
                password_hash TEXT NOT NULL,
                salt TEXT NOT NULL,
                role TEXT DEFAULT 'parent',
                language TEXT DEFAULT 'Gujarati',
                state TEXT DEFAULT 'Gujarat',
                district TEXT DEFAULT 'Ahmedabad',
                created_at TEXT NOT NULL
            );
        """)
        
        # Create an index on phone for fast lookups
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
        """)

        # Create an index on email
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
        """)

        # Create child_profiles table linked to user
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS child_profiles (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                name TEXT NOT NULL,
                dob TEXT,
                age_months INTEGER DEFAULT 0,
                gender TEXT DEFAULT 'Boy',
                birth_weight_kg REAL,
                current_weight_kg REAL,
                current_length_cm REAL,
                feeding_stage TEXT,
                created_at TEXT NOT NULL,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            );
        """)
        
        conn.commit()
        print(f"[DB] SQLite database initialized at: {DB_PATH}")

