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
from app.schemas import (
    UpdateProfileRequest,
    UserLoginRequest,
    OnboardingStep1Request,
    ChildCreateRequest,
    ChildrenBatchCreateRequest,
)
from app.routers.auth import (
    update_profile,
    get_current_user,
    login,
    onboarding_step_1,
    onboarding_step_2,
    skip_onboarding_step_2,
    get_children,
    add_single_child,
)

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

    def test_08_google_first_time_login_onboarding_status(self):
        """Verifies a brand new Google user starts with is_profile_complete=False and onboarding_step=0."""
        from unittest.mock import patch
        from app.schemas import GoogleAuthRequest
        from app.routers.auth import google_auth

        ts = int(datetime.now().timestamp())
        mock_user = {
            "sub": f"new_google_{ts}",
            "email": f"firsttime_{ts}@gmail.com",
            "name": "Meera Patel",
            "picture": "https://lh3.googleusercontent.com/a/meera"
        }

        with patch("app.routers.auth.verify_google_id_token", return_value=mock_user):
            res = google_auth(GoogleAuthRequest(id_token=f"token_meera_{ts}"))
            self.assertTrue(res.success)
            self.assertFalse(res.user.is_profile_complete, "First time user profile must be incomplete")
            self.assertEqual(res.user.onboarding_step, 0, "First time user onboarding_step must be 0")
            self.assertEqual(res.user.name, "Meera Patel")
            self.assertEqual(res.user.email, f"firsttime_{ts}@gmail.com")
            self.assertIsNone(res.user.phone, "Mobile number must be None for new Google user")

        print("[OK] Test 08: First-time Google user starts with is_profile_complete=False, onboarding_step=0.")

    def test_09_step1_user_information_validation(self):
        """Verifies Step 1 validation: name required, phone optional & validated, saves to DB, sets step=1."""
        ts = int(datetime.now().timestamp())
        with get_db() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                INSERT INTO users (name, phone, email, password_hash, salt, role, is_verified, auth_provider,
                                  is_profile_complete, onboarding_step, created_at)
                VALUES ('Temp User', NULL, ?, 'OAUTH_GOOGLE', 'OAUTH_SALT', 'parent', 1, 'google', 0, 0, ?)
            """, (f"step1_{ts}@gmail.com", datetime.now(timezone.utc).isoformat()))
            uid = cursor.lastrowid
            conn.commit()

        token = generate_token(uid, None)
        auth = f"Bearer {token}"

        # 1. Blank name rejected
        with self.assertRaises(HTTPException) as ctx:
            onboarding_step_1(req=OnboardingStep1Request(name="   "), authorization=auth)
        self.assertEqual(ctx.exception.status_code, 400)
        self.assertIn("Full Name is required", ctx.exception.detail)

        # 2. Fake Google identifier phone rejected
        with self.assertRaises(HTTPException) as ctx:
            onboarding_step_1(req=OnboardingStep1Request(name="Valid Name", phone="g_100234567"), authorization=auth)
        self.assertEqual(ctx.exception.status_code, 400)

        # 3. Invalid phone rejected
        with self.assertRaises(HTTPException) as ctx:
            onboarding_step_1(req=OnboardingStep1Request(name="Valid Name", phone="12345"), authorization=auth)
        self.assertEqual(ctx.exception.status_code, 400)

        # 4. Valid Step 1 with optional fields skipped (phone=None, address=None)
        res_skipped = onboarding_step_1(
            req=OnboardingStep1Request(name="Kavita Shah", phone=None, dob="1995-08-20", gender="Female"),
            authorization=auth
        )
        self.assertEqual(res_skipped.name, "Kavita Shah")
        self.assertIsNone(res_skipped.phone)
        self.assertEqual(res_skipped.dob, "1995-08-20")
        self.assertEqual(res_skipped.gender, "Female")
        self.assertEqual(res_skipped.onboarding_step, 1, "onboarding_step must advance to 1")
        self.assertFalse(res_skipped.is_profile_complete, "Profile is not complete until Step 2 is done/skipped")

        # 5. Adding valid phone in Step 1
        valid_phone = f"9879{str(ts)[-6:]}"
        res_with_phone = onboarding_step_1(
            req=OnboardingStep1Request(name="Kavita M. Shah", phone=valid_phone, city="Surat"),
            authorization=auth
        )
        self.assertEqual(res_with_phone.name, "Kavita M. Shah")
        self.assertEqual(res_with_phone.phone, valid_phone)
        self.assertEqual(res_with_phone.city, "Surat")

        print("[OK] Test 09: Step 1 Caregiver profile validation and progression verified.")

    def test_10_step2_children_information_saving(self):
        """Verifies Step 2 adds 1 or multiple children, supports optional weight, links to parent, completes profile."""
        ts = int(datetime.now().timestamp())
        with get_db() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                INSERT INTO users (name, phone, email, password_hash, salt, role, is_verified, auth_provider,
                                  is_profile_complete, onboarding_step, created_at)
                VALUES ('Sanjay Varma', NULL, ?, 'OAUTH_GOOGLE', 'OAUTH_SALT', 'parent', 1, 'google', 0, 1, ?)
            """, (f"step2_{ts}@gmail.com", datetime.now(timezone.utc).isoformat()))
            parent_id = cursor.lastrowid
            conn.commit()

        token = generate_token(parent_id, None)
        auth = f"Bearer {token}"

        # 1. Invalid child data: blank/whitespace name rejected
        with self.assertRaises(HTTPException) as ctx:
            onboarding_step_2(
                req=ChildrenBatchCreateRequest(children=[
                    ChildCreateRequest(name="   ", dob="2023-01-15", gender="Boy")
                ]),
                authorization=auth
            )
        self.assertEqual(ctx.exception.status_code, 400)
        self.assertIn("name is required", ctx.exception.detail)

        # 2. Add multiple children (Child 1 with weight, Child 2 with weight omitted/None)
        batch = ChildrenBatchCreateRequest(children=[
            ChildCreateRequest(name="Aarav Varma", dob="2023-02-10", weight=11.5, gender="Boy"),
            ChildCreateRequest(name="Ananya Varma", dob="2024-05-20", weight=None, gender="Girl"),
        ])
        res = onboarding_step_2(req=batch, authorization=auth)
        self.assertTrue(res["success"])
        self.assertEqual(len(res["children"]), 2)

        # Verify child records in database
        children = get_children(authorization=auth)
        self.assertEqual(len(children), 2)
        self.assertEqual(children[0].name, "Aarav Varma")
        self.assertEqual(children[0].parent_id, parent_id)
        self.assertEqual(children[0].weight, 11.5)
        self.assertEqual(children[0].gender, "Boy")

        self.assertEqual(children[1].name, "Ananya Varma")
        self.assertEqual(children[1].parent_id, parent_id)
        self.assertIsNone(children[1].weight, "Weight can be None/omitted")
        self.assertEqual(children[1].gender, "Girl")

        # Verify parent user is now marked as complete
        me = get_current_user(authorization=auth)
        self.assertTrue(me.is_profile_complete, "User must now have is_profile_complete=True")
        self.assertEqual(me.onboarding_step, 2, "User onboarding_step must now be 2")

        print("[OK] Test 10: Step 2 Multiple children saving, foreign key linking, and profile completion verified.")

    def test_11_step2_skip_functionality(self):
        """Verifies Step 2 'Add Later' / Skip completes profile so parent is never prompted again."""
        ts = int(datetime.now().timestamp())
        with get_db() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                INSERT INTO users (name, phone, email, password_hash, salt, role, is_verified, auth_provider,
                                  is_profile_complete, onboarding_step, created_at)
                VALUES ('Pooja Joshi', NULL, ?, 'OAUTH_GOOGLE', 'OAUTH_SALT', 'parent', 1, 'google', 0, 1, ?)
            """, (f"skip_{ts}@gmail.com", datetime.now(timezone.utc).isoformat()))
            uid = cursor.lastrowid
            conn.commit()

        token = generate_token(uid, None)
        auth = f"Bearer {token}"

        # Skip Step 2
        skip_res = skip_onboarding_step_2(authorization=auth)
        self.assertTrue(skip_res["success"])

        # Check user status
        me = get_current_user(authorization=auth)
        self.assertTrue(me.is_profile_complete)
        self.assertEqual(me.onboarding_step, 2)

        # Check children list is empty
        children = get_children(authorization=auth)
        self.assertEqual(len(children), 0)

        print("[OK] Test 11: Step 2 Skip ('Add Later') marks profile complete.")

    def test_12_midway_dropoff_and_resume(self):
        """Verifies that if user dropped off after Step 1, next login returns onboarding_step=1 to resume."""
        from unittest.mock import patch
        from app.schemas import GoogleAuthRequest
        from app.routers.auth import google_auth

        ts = int(datetime.now().timestamp())
        mock_user = {
            "sub": f"resume_sub_{ts}",
            "email": f"resume_{ts}@gmail.com",
            "name": "Devang Trivedi",
            "picture": None
        }

        with patch("app.routers.auth.verify_google_id_token", return_value=mock_user):
            # 1. First login -> Step 0
            login1 = google_auth(GoogleAuthRequest(id_token=f"tok_{ts}"))
            self.assertEqual(login1.user.onboarding_step, 0)
            self.assertFalse(login1.user.is_profile_complete)

            # 2. User completes Step 1
            auth = f"Bearer {login1.token}"
            step1_res = onboarding_step_1(
                req=OnboardingStep1Request(name="Devang Trivedi", gender="Male"),
                authorization=auth
            )
            self.assertEqual(step1_res.onboarding_step, 1)

            # 3. User closes app and logs in again -> Resumes at Step 1!
            login2 = google_auth(GoogleAuthRequest(id_token=f"tok_{ts}"))
            self.assertEqual(login2.user.onboarding_step, 1, "Must resume at step 1")
            self.assertFalse(login2.user.is_profile_complete, "Profile still incomplete")

        print("[OK] Test 12: Midway dropoff and resume at correct step verified.")

    def test_13_existing_completed_user_relogin(self):
        """Verifies that existing users with completed profiles go straight to dashboard (is_profile_complete=True)."""
        from unittest.mock import patch
        from app.schemas import GoogleAuthRequest
        from app.routers.auth import google_auth

        ts = int(datetime.now().timestamp())
        mock_user = {
            "sub": f"completed_sub_{ts}",
            "email": f"completed_{ts}@gmail.com",
            "name": "Ila Shah",
            "picture": None
        }

        with patch("app.routers.auth.verify_google_id_token", return_value=mock_user):
            # 1. First login
            log1 = google_auth(GoogleAuthRequest(id_token=f"tok_{ts}"))
            auth = f"Bearer {log1.token}"

            # 2. Complete Step 1
            onboarding_step_1(req=OnboardingStep1Request(name="Ila Shah"), authorization=auth)

            # 3. Complete Step 2
            onboarding_step_2(
                req=ChildrenBatchCreateRequest(children=[
                    ChildCreateRequest(name="Vivan Shah", dob="2023-06-01", gender="Boy")
                ]),
                authorization=auth
            )

            # 4. Subsequent login
            log_subsequent = google_auth(GoogleAuthRequest(id_token=f"tok_{ts}"))
            self.assertTrue(log_subsequent.user.is_profile_complete)
            self.assertEqual(log_subsequent.user.onboarding_step, 2)

        print("[OK] Test 13: Completed user subsequent login returns is_profile_complete=True.")

    def test_14_parent_isolation_of_children(self):
        """Verifies Parent A CANNOT access or see Parent B's children records."""
        ts = int(datetime.now().timestamp())
        now = datetime.now(timezone.utc).isoformat()

        with get_db() as conn:
            cursor = conn.cursor()
            # Parent A
            cursor.execute("""
                INSERT INTO users (name, phone, email, password_hash, salt, role, is_verified, auth_provider,
                                  is_profile_complete, onboarding_step, created_at)
                VALUES ('Parent Alpha', NULL, ?, 'OAUTH', 'SALT', 'parent', 1, 'google', 1, 2, ?)
            """, (f"p_alpha_{ts}@gmail.com", now))
            parent_a_id = cursor.lastrowid

            # Parent B
            cursor.execute("""
                INSERT INTO users (name, phone, email, password_hash, salt, role, is_verified, auth_provider,
                                  is_profile_complete, onboarding_step, created_at)
                VALUES ('Parent Beta', NULL, ?, 'OAUTH', 'SALT', 'parent', 1, 'google', 1, 2, ?)
            """, (f"p_beta_{ts}@gmail.com", now))
            parent_b_id = cursor.lastrowid

            # Add Child for Parent A
            cursor.execute("""
                INSERT INTO children (parent_id, name, dob, weight, gender, created_at)
                VALUES (?, 'Alpha Child', '2023-01-01', 10.0, 'Boy', ?)
            """, (parent_a_id, now))

            # Add Child for Parent B
            cursor.execute("""
                INSERT INTO children (parent_id, name, dob, weight, gender, created_at)
                VALUES (?, 'Beta Child', '2023-02-02', 12.0, 'Girl', ?)
            """, (parent_b_id, now))
            conn.commit()

        token_a = generate_token(parent_a_id, None)
        token_b = generate_token(parent_b_id, None)

        # Query children with Parent A's token
        children_a = get_children(authorization=f"Bearer {token_a}")
        self.assertEqual(len(children_a), 1)
        self.assertEqual(children_a[0].name, "Alpha Child")
        self.assertNotIn("Beta Child", [c.name for c in children_a])

        # Query children with Parent B's token
        children_b = get_children(authorization=f"Bearer {token_b}")
        self.assertEqual(len(children_b), 1)
        self.assertEqual(children_b[0].name, "Beta Child")
        self.assertNotIn("Alpha Child", [c.name for c in children_b])

        print("[OK] Test 14: Strict parent-child data isolation verified.")

    def test_15_health_endpoint_and_keepalive_lifespan(self):
        """Tests /health endpoint response and validates lifespan background task configuration."""
        import inspect
        from app.main import health, app, keep_alive_task

        # 1. Health check returns status ok
        res = health()
        self.assertEqual(res, {"status": "ok"})

        # 2. Verify keep_alive_task is an asynchronous coroutine function
        self.assertTrue(inspect.iscoroutinefunction(keep_alive_task), "keep_alive_task must be an async coroutine function")

        # 3. Verify app has lifespan context configured
        self.assertIsNotNone(app.router.lifespan_context, "FastAPI app must have lifespan context configured")

        # 4. Verify keep_alive_task generates a valid coroutine
        coro = keep_alive_task()
        self.assertTrue(inspect.iscoroutine(coro))
        coro.close()

        print("[OK] Test 15: /health endpoint and keepalive background task lifespan verified.")

    def test_16_apple_auth_completely_removed(self):
        """Verifies Apple route does not exist in FastAPI route table and schemas."""
        from app.main import app
        import app.schemas as schemas
        import app.oauth_service as oauth_service

        # 1. No /apple route in app routes
        route_paths = [getattr(route, "path", "") for route in app.routes if hasattr(route, "path")]
        self.assertNotIn("/api/auth/apple", route_paths)
        self.assertNotIn("/auth/apple", route_paths)

        # 2. No AppleAuthRequest schema
        self.assertFalse(hasattr(schemas, "AppleAuthRequest"), "AppleAuthRequest must not exist in schemas")

        # 3. No Apple functions in oauth_service
        self.assertFalse(hasattr(oauth_service, "verify_apple_identity_token"), "verify_apple_identity_token must not exist")
        self.assertFalse(hasattr(oauth_service, "get_apple_public_keys"), "get_apple_public_keys must not exist")
        self.assertFalse(hasattr(oauth_service, "APPLE_CLIENT_ID"), "APPLE_CLIENT_ID must not exist")

        print("[OK] Test 16: Apple Sign-In routes, functions, and schemas completely removed.")

    def test_17_child_update_and_weight_persistence(self):
        """Verifies updating child weight and details, and prevents cross-parent updates."""
        from app.routers.auth import update_child, add_single_child
        from app.schemas import ChildUpdateRequest, ChildCreateRequest

        ts = int(datetime.now().timestamp())
        now = datetime.now(timezone.utc).isoformat()

        with get_db() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                INSERT INTO users (name, phone, email, password_hash, salt, role, is_verified, auth_provider, is_profile_complete, onboarding_step, created_at)
                VALUES ('Parent Test 17', NULL, ?, 'OAUTH', 'SALT', 'parent', 1, 'google', 1, 2, ?)
            """, (f"p17_{ts}@gmail.com", now))
            parent_id = cursor.lastrowid
            
            cursor.execute("""
                INSERT INTO users (name, phone, email, password_hash, salt, role, is_verified, auth_provider, is_profile_complete, onboarding_step, created_at)
                VALUES ('Other Parent 17', NULL, ?, 'OAUTH', 'SALT', 'parent', 1, 'google', 1, 2, ?)
            """, (f"p17_other_{ts}@gmail.com", now))
            other_parent_id = cursor.lastrowid
            conn.commit()

        token_parent = generate_token(parent_id, None)
        token_other = generate_token(other_parent_id, None)

        # 1. Add child with missing weight
        created = add_single_child(
            req=ChildCreateRequest(name="Rehan", dob="2024-03-15", gender="Boy", weight=None),
            authorization=f"Bearer {token_parent}"
        )
        self.assertEqual(created.name, "Rehan")
        self.assertIsNone(created.weight)

        # 2. Update weight via PATCH /children/{child_id}
        updated = update_child(
            child_id=created.id,
            req=ChildUpdateRequest(weight=12.4),
            authorization=f"Bearer {token_parent}"
        )
        self.assertEqual(updated.weight, 12.4)
        self.assertIsNotNone(updated.updated_at)

        # 3. Other parent attempts to update this child -> must return 404
        with self.assertRaises(HTTPException) as ctx:
            update_child(
                child_id=created.id,
                req=ChildUpdateRequest(weight=15.0),
                authorization=f"Bearer {token_other}"
            )
        self.assertEqual(ctx.exception.status_code, 404)

        print("[OK] Test 17: Child update, weight persistence, and isolation verified.")

if __name__ == "__main__":
    unittest.main()
