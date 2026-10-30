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
    conn = sqlite3.connect(DB_PATH, timeout=20.0)
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
                phone TEXT UNIQUE,
                email TEXT,
                password_hash TEXT,
                salt TEXT,
                role TEXT DEFAULT 'parent',
                language TEXT DEFAULT 'Gujarati',
                state TEXT DEFAULT 'Gujarat',
                district TEXT DEFAULT 'Ahmedabad',
                dob TEXT,
                gender TEXT,
                address TEXT,
                city TEXT,
                pin_code TEXT,
                avatar_url TEXT,
                is_verified INTEGER DEFAULT 0,
                auth_provider TEXT DEFAULT 'local',
                is_profile_complete INTEGER DEFAULT 0,
                onboarding_step INTEGER DEFAULT 0,
                created_at TEXT NOT NULL
            );
        """)

        # Migration: Ensure phone is nullable (for OAuth users who haven't added phone yet)
        cursor.execute("PRAGMA table_info(users);")
        table_info = cursor.fetchall()
        phone_info = next((row for row in table_info if row["name"] == "phone"), None)
        if phone_info and phone_info["notnull"] == 1:
            cursor.execute("PRAGMA foreign_keys = OFF;")
            cursor.execute("""
                CREATE TABLE users_migration (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL,
                    phone TEXT UNIQUE,
                    email TEXT,
                    password_hash TEXT,
                    salt TEXT,
                    role TEXT DEFAULT 'parent',
                    language TEXT DEFAULT 'Gujarati',
                    state TEXT DEFAULT 'Gujarat',
                    district TEXT DEFAULT 'Ahmedabad',
                    dob TEXT,
                    gender TEXT,
                    address TEXT,
                    city TEXT,
                    pin_code TEXT,
                    avatar_url TEXT,
                    is_verified INTEGER DEFAULT 0,
                    auth_provider TEXT DEFAULT 'local',
                    created_at TEXT NOT NULL
                );
            """)
            cursor.execute("""
                INSERT INTO users_migration (
                    id, name, phone, email, password_hash, salt, role, language, state, district,
                    is_verified, auth_provider, created_at
                )
                SELECT
                    id, name, phone, email, password_hash, salt, role, language, state, district,
                    is_verified, auth_provider, created_at
                FROM users;
            """)
            cursor.execute("DROP TABLE users;")
            cursor.execute("ALTER TABLE users_migration RENAME TO users;")
            cursor.execute("PRAGMA foreign_keys = ON;")

        # Automated Data Cleansing: Cleanse any legacy placeholder phones (e.g. g_..., a_..., sub_...)
        # Google authentication identifiers (sub, id) or arbitrary strings must NEVER be stored as mobile numbers.
        cursor.execute("""
            UPDATE users 
            SET phone = NULL 
            WHERE phone LIKE 'g_%' 
               OR phone LIKE 'a_%' 
               OR phone LIKE 'sub_%'
               OR (phone IS NOT NULL AND (length(phone) != 10 OR phone NOT GLOB '[0-9]*'));
        """)

        # Migration: Add any missing profile columns to existing database
        cursor.execute("PRAGMA table_info(users);")
        col_names = [row["name"] for row in cursor.fetchall()]
        for col, col_type in [
            ("is_verified", "INTEGER DEFAULT 0"),
            ("auth_provider", "TEXT DEFAULT 'local'"),
            ("dob", "TEXT"),
            ("gender", "TEXT"),
            ("address", "TEXT"),
            ("city", "TEXT"),
            ("pin_code", "TEXT"),
            ("avatar_url", "TEXT"),
            ("is_profile_complete", "INTEGER DEFAULT 0"),
            ("onboarding_step", "INTEGER DEFAULT 0"),
        ]:
            if col not in col_names:
                cursor.execute(f"ALTER TABLE users ADD COLUMN {col} {col_type};")

        # Automatically mark existing local users as profile complete so traditional auth is uninterrupted
        cursor.execute("""
            UPDATE users
            SET is_profile_complete = 1, onboarding_step = 2
            WHERE auth_provider = 'local' AND (is_profile_complete IS NULL OR is_profile_complete = 0);
        """)
        
        # Create an index on phone for fast lookups
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
        """)

        # Create an index on email
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
        """)

        # Create oauth_accounts table for social login (Google)
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS oauth_accounts (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                provider TEXT NOT NULL,
                provider_user_id TEXT NOT NULL,
                email TEXT,
                created_at TEXT NOT NULL,
                UNIQUE(provider, provider_user_id),
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            );
        """)
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_oauth_accounts_provider_sub ON oauth_accounts(provider, provider_user_id);
        """)
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_oauth_accounts_user_id ON oauth_accounts(user_id);
        """)

        # Create email_otps table for storing secure hashed OTPs
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS email_otps (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER,
                email TEXT NOT NULL,
                otp_hash TEXT NOT NULL,
                salt TEXT NOT NULL,
                expires_at TEXT NOT NULL,
                attempts_count INTEGER DEFAULT 0,
                max_attempts INTEGER DEFAULT 5,
                created_at TEXT NOT NULL,
                last_sent_at TEXT NOT NULL,
                is_used INTEGER DEFAULT 0,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            );
        """)
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_email_otps_email ON email_otps(email);
        """)

        # Create password_resets table for storing secure single-use password reset token hashes
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS password_resets (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                email TEXT NOT NULL,
                token_hash TEXT NOT NULL,
                salt TEXT NOT NULL,
                expires_at TEXT NOT NULL,
                created_at TEXT NOT NULL,
                is_used INTEGER DEFAULT 0,
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            );
        """)
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_password_resets_token_hash ON password_resets(token_hash);
        """)
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_password_resets_email ON password_resets(email);
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

        # Create children table for parent onboarding and child tracking
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS children (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                parent_id INTEGER NOT NULL,
                name TEXT NOT NULL,
                dob TEXT NOT NULL,
                weight REAL,
                gender TEXT NOT NULL,
                created_at TEXT NOT NULL,
                updated_at TEXT,
                FOREIGN KEY (parent_id) REFERENCES users(id) ON DELETE CASCADE
            );
        """)
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_children_parent_id ON children(parent_id);
        """)
        
        conn.commit()
        print(f"[DB] SQLite database initialized at: {DB_PATH}")

