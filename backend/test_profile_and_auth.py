import os
import sys
import unittest
from datetime import datetime, timezone
from fastapi import HTTPException

# Add backend directory to sys.path
backend_dir = os.path.abspath(os.path.join(os.path.dirname(__file__)))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

from app.database import get_db, init_db
from app.security import generate_token, hash_password, generate_salt
from app.schemas import UpdateProfileRequest, UserLoginRequest
from app.routers.auth import update_profile, get_current_user, login

class TestAuthAndProfile(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        init_db()

    def test_01_schema_nullable_phone(self):
        """Verifies phone is nullable in users table and profile columns exist."""
        with get_db() as conn:
            cursor = conn.cursor()
            cursor.execute("PRAGMA table_info(users)")
            cols = {row["name"]: row for row in cursor.fetchall()}

            self.assertIn("phone", cols)
            self.assertEqual(cols["phone"]["notnull"], 0, "Phone column must be nullable (notnull=0)")

            for col in ["dob", "gender", "address", "city", "pin_code", "avatar_url", "auth_provider"]:
                self.assertIn(col, cols, f"Column '{col}' must exist in users table")
            print("[OK] Test 01: SQLite schema nullable phone & profile columns verified.")

    def test_02_no_placeholder_phones_exist(self):
        """Verifies no legacy g_ or a_ placeholder phones remain in the database."""
        with get_db() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT COUNT(*) as count FROM users WHERE phone LIKE 'g_%' OR phone LIKE 'a_%'")
            count = cursor.fetchone()["count"]
            self.assertEqual(count, 0, "No placeholder phone numbers (g_% or a_%) should exist in users table")
            print("[OK] Test 02: No placeholder phones (g_% or a_%) in database.")

    def test_03_profile_update_authenticated(self):
        """Creates user without phone, authenticates with Bearer token, and tests update_profile."""
        with get_db() as conn:
            cursor = conn.cursor()
            salt = generate_salt()
            pwd_hash = hash_password("ValidPassword@123", salt)
            now = datetime.now(timezone.utc).isoformat()
            test_email = f"rohan_{int(datetime.now().timestamp())}@test.com"

            # Create Google user without phone
            cursor.execute("""
                INSERT INTO users (name, phone, email, password_hash, salt, role, is_verified, auth_provider, created_at)
                VALUES ('Rohan Dave', NULL, ?, ?, ?, 'parent', 1, 'google', ?)
            """, (test_email, pwd_hash, salt, now))
            user_id = cursor.lastrowid
            conn.commit()

        # Generate auth token with phone=None
        token = generate_token(user_id, None)
        auth_header = f"Bearer {token}"

        # 1. get_current_user should return user with phone=None and auth_provider='google'
        me_data = get_current_user(authorization=auth_header)
        self.assertEqual(me_data.name, "Rohan Dave")
        self.assertIsNone(me_data.phone)
        self.assertEqual(me_data.auth_provider, "google")

        # 2. update_profile with invalid 7-digit phone should raise HTTPException 400
        with self.assertRaises(HTTPException) as ctx:
            update_profile(
                req=UpdateProfileRequest(phone="1234567"),
                authorization=auth_header,
            )
        self.assertEqual(ctx.exception.status_code, 400)
        self.assertIn("10-digit", ctx.exception.detail)

        # 3. update_profile with invalid 4-digit PIN code should raise HTTPException 400
        with self.assertRaises(HTTPException) as ctx:
            update_profile(
                req=UpdateProfileRequest(pin_code="3800"),
                authorization=auth_header,
            )
        self.assertEqual(ctx.exception.status_code, 400)
        self.assertIn("6-digit", ctx.exception.detail)

        # 4. update_profile with complete valid profile data
        valid_phone = f"9825{str(int(datetime.now().timestamp()))[-6:]}"
        update_req = UpdateProfileRequest(
            name="Rohan J. Dave",
            phone=valid_phone,
            dob="1992-05-14",
            gender="Male",
            address="B-402, Shivalik Residency, Drive-In Road",
            city="Ahmedabad",
            state="Gujarat",
            district="Ahmedabad",
            pin_code="380054",
            avatar_url="https://lh3.googleusercontent.com/a/test-avatar-rohan"
        )
        updated_res = update_profile(req=update_req, authorization=auth_header)
        self.assertEqual(updated_res.name, "Rohan J. Dave")
        self.assertEqual(updated_res.phone, valid_phone)
        self.assertEqual(updated_res.dob, "1992-05-14")
        self.assertEqual(updated_res.gender, "Male")
        self.assertEqual(updated_res.address, "B-402, Shivalik Residency, Drive-In Road")
        self.assertEqual(updated_res.city, "Ahmedabad")
        self.assertEqual(updated_res.state, "Gujarat")
        self.assertEqual(updated_res.pin_code, "380054")
        self.assertEqual(updated_res.avatar_url, "https://lh3.googleusercontent.com/a/test-avatar-rohan")

        # 5. Persisted state verification via get_current_user
        recheck_data = get_current_user(authorization=auth_header)
        self.assertEqual(recheck_data.phone, valid_phone)
        self.assertEqual(recheck_data.city, "Ahmedabad")
        self.assertEqual(recheck_data.pin_code, "380054")
        print("[OK] Test 03: Profile update (PUT /api/auth/profile) & persistence verified.")

    def test_04_user_isolation_security(self):
        """Verifies User A cannot modify User B's profile and phone collisions are prevented."""
        with get_db() as conn:
            cursor = conn.cursor()
            salt = generate_salt()
            pwd_hash = hash_password("ValidPassword@123", salt)
            now = datetime.now(timezone.utc).isoformat()
            ts = int(datetime.now().timestamp())

            phone_a = f"91{str(ts)[-8:]}"
            phone_b = f"92{str(ts)[-8:]}"

            # User A
            cursor.execute("""
                INSERT INTO users (name, phone, email, password_hash, salt, role, is_verified, created_at)
                VALUES ('User Alpha', ?, ?, ?, ?, 'parent', 1, ?)
            """, (phone_a, f"alpha_{ts}@test.com", pwd_hash, salt, now))
            user_a_id = cursor.lastrowid

            # User B
            cursor.execute("""
                INSERT INTO users (name, phone, email, password_hash, salt, role, is_verified, created_at)
                VALUES ('User Beta', ?, ?, ?, ?, 'parent', 1, ?)
            """, (phone_b, f"beta_{ts}@test.com", pwd_hash, salt, now))
            user_b_id = cursor.lastrowid
            conn.commit()

        token_a = generate_token(user_a_id, phone_a)
        auth_header_a = f"Bearer {token_a}"

        # User A updates profile with phone that already belongs to User B -> Must reject!
        with self.assertRaises(HTTPException) as ctx:
            update_profile(
                req=UpdateProfileRequest(phone=phone_b),
                authorization=auth_header_a,
            )
        self.assertEqual(ctx.exception.status_code, 400)
        self.assertIn("already linked", ctx.exception.detail)

        # Unauthenticated request without token must reject with 401
        with self.assertRaises(HTTPException) as ctx:
            update_profile(
                req=UpdateProfileRequest(name="Hacked"),
                authorization=None,
            )
        self.assertEqual(ctx.exception.status_code, 401)
        print("[OK] Test 04: User isolation & token security verified.")

    def test_05_no_hardcoded_priya_in_login(self):
        """Verifies wrong credentials return 401 and never leak hardcoded Priya details."""
        with self.assertRaises(HTTPException) as ctx:
            login(UserLoginRequest(identifier="nonexistent@example.com", password="WrongPassword@123"))
        self.assertEqual(ctx.exception.status_code, 401)
        self.assertNotIn("Priya", ctx.exception.detail)
        print("[OK] Test 05: Login rejects invalid user cleanly without hardcoded Priya fallback.")

    def test_06_google_sign_in_avatar_and_null_phone(self):
        """Verifies Google Sign-In stores verified picture, keeps phone NULL, and avoids duplicate accounts."""
        from unittest.mock import patch
        from app.schemas import GoogleAuthRequest
        from app.routers.auth import google_auth

        ts = int(datetime.now().timestamp())
        mock_google_user = {
            "sub": f"google_sub_{ts}",
            "email": f"google_user_{ts}@gmail.com",
            "name": "Ananya Sharma",
            "picture": "https://lh3.googleusercontent.com/a/ananya-avatar-pic"
        }

        with patch("app.routers.auth.verify_google_id_token", return_value=mock_google_user):
            # First Google Login -> Creates user
            res1 = google_auth(GoogleAuthRequest(id_token=f"valid_token_{ts}"))
            self.assertTrue(res1.success)
            self.assertIsNotNone(res1.token)
            self.assertIsNotNone(res1.user)
            user1 = res1.user
            self.assertEqual(user1.name, "Ananya Sharma")
            self.assertEqual(user1.email, f"google_user_{ts}@gmail.com")
            self.assertIsNone(user1.phone, "Google user phone must be NULL, never a fake placeholder")
            self.assertEqual(user1.avatar_url, "https://lh3.googleusercontent.com/a/ananya-avatar-pic")
            self.assertEqual(user1.auth_provider, "google")
            self.assertTrue(user1.is_verified)

            # Second Google Login -> Must return existing user without duplicating
            res2 = google_auth(GoogleAuthRequest(id_token=f"valid_token_{ts}"))
            self.assertTrue(res2.success)
            self.assertEqual(res2.user.id, user1.id, "Second Google login must map to the same user_id")
            self.assertIsNone(res2.user.phone)

            # Check database directly
            with get_db() as conn:
                cursor = conn.cursor()
                cursor.execute("SELECT COUNT(*) as count FROM users WHERE email = ?", (f"google_user_{ts}@gmail.com",))
                count = cursor.fetchone()["count"]
                self.assertEqual(count, 1, "Only 1 user row must exist for this Google email")
        print("[OK] Test 06: Google Sign-In stores avatar, sets phone=NULL, and links without duplicates.")

    def test_07_legacy_g_identifier_cleanup_and_validation(self):
        """Verifies users with legacy g_100435695197 are safely cleaned and prevented from re-saving identifiers."""
        ts = int(datetime.now().timestamp())
        legacy_identifier = f"g_100435{str(ts)[-6:]}"

        with get_db() as conn:
            cursor = conn.cursor()
            salt = generate_salt()
            pwd_hash = hash_password("ValidPassword@123", salt)
            now = datetime.now(timezone.utc).isoformat()
            
            cursor.execute("""
                INSERT INTO users (name, phone, email, password_hash, salt, role, is_verified, auth_provider, created_at)
                VALUES ('Legacy User', ?, ?, ?, ?, 'parent', 1, 'google', ?)
            """, (legacy_identifier, f"legacy_{ts}@gmail.com", pwd_hash, salt, now))
            legacy_uid = cursor.lastrowid
            conn.commit()

        token = generate_token(legacy_uid, legacy_identifier)
        auth_header = f"Bearer {token}"

        # 1. get_current_user must sanitize g_... to None and clean the database row
        me = get_current_user(authorization=auth_header)
        self.assertIsNone(me.phone, "Legacy g_ identifier must not be returned in UserResponse")

        with get_db() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT phone FROM users WHERE id = ?", (legacy_uid,))
            db_phone = cursor.fetchone()["phone"]
            self.assertIsNone(db_phone, "Database row must be cleansed to NULL")

        # 2. update_profile must reject saving any g_... or system identifier as phone number
        with self.assertRaises(HTTPException) as ctx:
            update_profile(
                req=UpdateProfileRequest(phone="g_100435695197"),
                authorization=auth_header,
            )
        self.assertEqual(ctx.exception.status_code, 400)
        self.assertIn("identifiers", ctx.exception.detail)

        # 3. update_profile must accept a genuine 10-digit mobile number
        valid_phone = f"9821{str(ts)[-6:]}"
        updated = update_profile(
            req=UpdateProfileRequest(phone=valid_phone),
            authorization=auth_header,
        )
        self.assertEqual(updated.phone, valid_phone)

        # Verify persisted in database
        with get_db() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT phone FROM users WHERE id = ?", (legacy_uid,))
            saved_phone = cursor.fetchone()["phone"]
            self.assertEqual(saved_phone, valid_phone)

        print("[OK] Test 07: Legacy g_ identifiers are cleansed to NULL and rejected on update.")

if __name__ == "__main__":
    unittest.main()
