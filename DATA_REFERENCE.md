# Poshan-Saathi Data Reference Documentation

> **Developer Reference Guide**  
> **Project:** Poshan-Saathi (પોષણ સાથી • Child Nutrition Care)  
> **Scope:** Complete reference for accessing and updating every User and Child variable across SQLite, FastAPI backend, and Flutter frontend.  
> **Last Verified:** October 2026  

---

## Table of Contents

1. [User Information Reference Table](#1-user-information-reference-table)
2. [Child Information Reference Table](#2-child-information-reference-table)
3. [Exact Working Code Examples](#3-exact-working-code-examples)
   - [3.1 Accessing the Logged-In User in Flutter](#31-accessing-the-logged-in-user-in-flutter)
   - [3.2 Accessing User Data in FastAPI Backend](#32-accessing-user-data-in-fastapi-backend)
   - [3.3 Direct SQLite Database Access for Users](#33-direct-sqlite-database-access-for-users)
   - [3.4 Updating User Information](#34-updating-user-information)
   - [3.5 Safe Handling of Nullable User Fields](#35-safe-handling-of-nullable-user-fields)
   - [3.6 Accessing Child Data in Flutter](#36-accessing-child-data-in-flutter)
   - [3.7 Accessing Child Data in FastAPI Backend](#37-accessing-child-data-in-fastapi-backend)
   - [3.8 Direct SQLite Database Access for Children](#38-direct-sqlite-database-access-for-children)
   - [3.9 Handling Multiple Children for a Single Parent](#39-handling-multiple-children-for-a-single-parent)
   - [3.10 Calculating Child Age from Date of Birth](#310-calculating-child-age-from-date-of-birth)
4. [API Reference & Endpoints](#4-api-reference--endpoints)
5. [Important Architectural & Security Rules](#5-important-architectural--security-rules)
   - [5.1 Database Schema & Tables](#51-database-schema--tables)
   - [5.2 Parent-Child Relational Link (Foreign Keys)](#52-parent-child-relational-link-foreign-keys)
   - [5.3 Identifying the Authenticated User (Bearer Tokens)](#53-identifying-the-authenticated-user-bearer-tokens)
   - [5.4 Multi-Tenant Data Isolation (Preventing Leaks)](#54-multi-tenant-data-isolation-preventing-leaks)
   - [5.5 Mandatory vs. Nullable Fields Matrix](#55-mandatory-vs-nullable-fields-matrix)
6. [Quick Cheat Sheet for Future Developers](#6-quick-cheat-sheet-for-future-developers)

---

## 1. User Information Reference Table

All user records are persisted in the SQLite database and served via Pydantic response models to Flutter.

| Variable | Description | Database Table | Database Column | Flutter Access Code (`UserModel`) | Backend Access Code (`UserResponse` / Row) |
|---|---|---|---|---|---|
| **User ID** | Unique primary key | `users` | `id` (INTEGER PK) | `user.id` | `row["id"]` / `user.id` |
| **Name** | Caregiver's full name | `users` | `name` (TEXT NOT NULL) | `user.name` / `UserSession.instance.displayName` | `row["name"]` / `user.name` |
| **Email** | Caregiver's email address | `users` | `email` (TEXT) | `user.email` (nullable `String?`) | `row["email"]` / `user.email` |
| **Mobile Number** | 10-digit Indian mobile number | `users` | `phone` (TEXT UNIQUE) | `user.phone` / `UserSession.instance.displayPhone` | `row["phone"]` / `user.phone` |
| **Gender** | Caregiver gender (Female/Male/Other) | `users` | `gender` (TEXT) | `user.gender` (nullable `String?`) | `row["gender"]` / `user.gender` |
| **Date of Birth** | Caregiver DOB (`YYYY-MM-DD`) | `users` | `dob` (TEXT) | `user.dob` (nullable `String?`) | `row["dob"]` / `user.dob` |
| **Address** | Residential street address | `users` | `address` (TEXT) | `user.address` (nullable `String?`) | `row["address"]` / `user.address` |
| **City** | City / Town / Village | `users` | `city` (TEXT) | `user.city` (nullable `String?`) | `row["city"]` / `user.city` |
| **State** | State (Default: Gujarat) | `users` | `state` (TEXT) | `user.state` (nullable `String?`) | `row["state"]` / `user.state` |
| **District** | District (Default: Ahmedabad) | `users` | `district` (TEXT) | `user.district` (nullable `String?`) | `row["district"]` / `user.district` |
| **PIN Code** | 6-digit postal code | `users` | `pin_code` (TEXT) | `user.pinCode` (nullable `String?`) | `row["pin_code"]` / `user.pin_code` |
| **Avatar URL** | Profile picture URL | `users` | `avatar_url` (TEXT) | `user.avatarUrl` (nullable `String?`) | `row["avatar_url"]` / `user.avatar_url` |
| **Role** | User role (`parent`, `clinician`, `admin`) | `users` | `role` (TEXT DEFAULT `'parent'`) | `user.role` (`String`) | `row["role"]` / `user.role` |
| **Language** | Preferred interface language | `users` | `language` (TEXT) | `user.language` (nullable `String?`) | `row["language"]` / `user.language` |
| **Auth Provider** | Authentication origin (`local` or `google`) | `users` | `auth_provider` (TEXT DEFAULT `'local'`) | `user.authProvider` (`String?`) | `row["auth_provider"]` / `user.auth_provider` |
| **Email Verified** | Whether email OTP was verified | `users` | `is_verified` (INTEGER 0 or 1) | `user.isVerified` (`bool`) | `bool(row["is_verified"])` / `user.is_verified` |
| **Profile Complete** | Whether onboarding steps are done | `users` | `is_profile_complete` (INTEGER 0 or 1) | `user.isProfileComplete` (`bool`) | `bool(row["is_profile_complete"])` / `user.is_profile_complete` |
| **Onboarding Step** | 0 = Step 1 needed, 1 = Step 2 needed, 2 = Complete | `users` | `onboarding_step` (INTEGER DEFAULT 0) | `user.onboardingStep` (`int`) | `int(row["onboarding_step"])` / `user.onboarding_step` |
| **Created At** | Account creation timestamp (ISO-8601 UTC) | `users` | `created_at` (TEXT NOT NULL) | `user.createdAt` (nullable `String?`) | `row["created_at"]` / `user.created_at` |
| **Session Token** | In-memory JWT bearer token | *N/A (JWT)* | *Transient* | `user.token` / `UserSession.instance.currentToken` | Generated via `generate_token(uid, phone)` |

---

## 2. Child Information Reference Table

Child records are stored in the `children` table and linked to the authenticated parent via `parent_id`.

| Variable | Description | Database Table | Database Column | Flutter Access Code (`ChildModel`) | Backend Access Code (`ChildResponse` / Row) |
|---|---|---|---|---|---|
| **Child ID** | Unique primary key of the child | `children` | `id` (INTEGER PK) | `child.id` (`int`) | `row["id"]` / `child.id` (`int`) |
| **Parent ID** | Foreign key linking to parent (`users.id`) | `children` | `parent_id` (INTEGER NOT NULL FK) | `child.parentId` (`int`) | `row["parent_id"]` / `child.parent_id` (`int`) |
| **Child Name** | Full name of the child | `children` | `name` (TEXT NOT NULL) | `child.name` (`String`) | `row["name"]` / `child.name` (`str`) |
| **Date of Birth** | Child's birth date (`YYYY-MM-DD`) | `children` | `dob` (TEXT NOT NULL) | `child.dob` (`String`) | `row["dob"]` / `child.dob` (`str`) |
| **Age** | Age dynamically computed from DOB | *Computed* | *Computed from `dob`* | `child.ageDisplay` (e.g. `'2 yr 3 mo'`) | Computed dynamically or `child_profiles.age_months` |
| **Weight** | Child's weight in kilograms | `children` | `weight` (REAL) | `child.weight` (nullable `double?`) | `row["weight"]` / `child.weight` (nullable `float?`) |
| **Gender** | Child's gender (`Boy`, `Girl`, `Other`) | `children` | `gender` (TEXT NOT NULL) | `child.gender` (`String`) | `row["gender"]` / `child.gender` (`str`) |
| **Created At** | Timestamp when child was added (ISO UTC) | `children` | `created_at` (TEXT NOT NULL) | `child.createdAt` (nullable `String?`) | `row["created_at"]` / `child.created_at` (`str`) |
| **Updated At** | Timestamp of last modification | `children` | `updated_at` (TEXT) | `child.updatedAt` (nullable `String?`) | `row["updated_at"]` / `child.updated_at` (nullable `str?`) |
| **Birth Weight** | Weight at birth (kg) | `child_profiles` | `birth_weight_kg` (REAL) | *Only in static mock / child_profiles* | `row["birth_weight_kg"]` |
| **Height / Length** | Length in cm | `child_profiles` | `current_length_cm` (REAL) | *Only in static mock / child_profiles* | `row["current_length_cm"]` |
| **Feeding Stage** | E.g. Exclusive Breastfeeding | `child_profiles` | `feeding_stage` (TEXT) | *Only in static mock / child_profiles* | `row["feeding_stage"]` |
| **ABHA ID** | Ayushman Bharat Health Account ID | *Not in SQLite* | *N/A* | `NOT IMPLEMENTED` *(Mock only in mock_data.dart)* | `NOT IMPLEMENTED` |
| **WHO Growth Zone** | Standard growth classification | *Not in SQLite* | *N/A* | `NOT IMPLEMENTED` *(Mock only in mock_data.dart)* | `NOT IMPLEMENTED` |

---

## 3. Exact Working Code Examples

### 3.1 Accessing the Logged-In User in Flutter

All authenticated user state in Flutter is managed by the singleton [`UserSession.instance`](file:///frontend/lib/core/services/user_session.dart) in `frontend/lib/core/services/user_session.dart`.

```dart
import 'package:frontend/core/models/user_model.dart';
import 'package:frontend/core/services/user_session.dart';

void exampleAccessUser() {
  // 1. Get the current user model (nullable)
  final UserModel? user = UserSession.instance.currentUser;

  if (user != null) {
    final int userId = user.id;
    final String name = user.name;
    final String? email = user.email;
    final String? phone = user.phone; // Already sanitized, or null if missing
    final String role = user.role;
    final bool isVerified = user.isVerified;
    final bool isComplete = user.isProfileComplete;

    print('User #$userId: $name ($email), Phone: $phone');
  }

  // 2. Convenience helpers on UserSession
  final String displayName = UserSession.instance.displayName; // Returns name or 'Caregiver'
  final String displayPhone = UserSession.instance.displayPhone; // Returns phone or 'Not added'
  final String? token = UserSession.instance.currentToken; // Bearer token for API calls
}
```

#### Reactive UI Binding in Flutter Widgets
To automatically re-render widgets when user details change:

```dart
ValueListenableBuilder<UserModel?>(
  valueListenable: UserSession.instance.currentUserNotifier,
  builder: (context, user, child) {
    if (user == null) {
      return const Text('Not signed in');
    }
    return Text('Welcome, ${user.name}!');
  },
)
```

---

### 3.2 Accessing User Data in FastAPI Backend

In [`backend/app/routers/auth.py`](file:///backend/app/routers/auth.py), the authenticated user is resolved from the standard HTTP `Authorization: Bearer <token>` header:

```python
from fastapi import APIRouter, Header, HTTPException, status
from app.routers.auth import get_authenticated_user_id
from app.database import get_db
from app.schemas import UserResponse

router = APIRouter()

@router.get("/example-user-route")
def get_user_example(authorization: str = Header(...)):
    # 1. Extract and verify user_id from token payload (raises 401 if invalid/expired)
    user_id: int = get_authenticated_user_id(authorization)

    # 2. Query user row from SQLite
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT id, name, phone, email, role, dob, gender, address, city,
                   state, district, pin_code, avatar_url, auth_provider,
                   is_verified, is_profile_complete, onboarding_step, created_at
            FROM users
            WHERE id = ?
        """, (user_id,))
        row = cursor.fetchone()

        if not row:
            raise HTTPException(status_code=404, detail="User not found")

        # 3. Access variables directly from dict-like row
        name = row["name"]
        email = row["email"]
        phone = row["phone"]  # None if not added

        return {
            "id": row["id"],
            "name": name,
            "email": email,
            "phone": phone or "Not added",
            "is_profile_complete": bool(row["is_profile_complete"])
        }
```

---

### 3.3 Direct SQLite Database Access for Users

If executing scripts or database management directly via [`backend/app/database.py`](file:///backend/app/database.py):

```python
from app.database import get_db

def fetch_user_by_id(user_id: int):
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,))
        row = cursor.fetchone()
        if row:
            print(f"ID: {row['id']}")
            print(f"Name: {row['name']}")
            print(f"Phone: {row['phone']}")
            print(f"Email: {row['email']}")
            print(f"Provider: {row['auth_provider']}")
            print(f"Onboarding Step: {row['onboarding_step']}")
        return row
```

---

### 3.4 Updating User Information

#### In Flutter via `ApiService`:
Call [`ApiService.instance.updateProfile`](file:///frontend/lib/core/services/api_service.dart#L520):

```dart
final result = await ApiService.instance.updateProfile(
  name: 'Ananya Sharma',
  phone: '9876543210',       // Must be valid 10-digit number starting with 6-9
  dob: '1992-05-14',
  gender: 'Female',
  address: '14 Shantivan Society',
  city: 'Ahmedabad',
  state: 'Gujarat',
  district: 'Ahmedabad',
  pinCode: '380015',
);

if (result.success) {
  print('Profile updated! New name: ${result.user?.name}');
} else {
  print('Error: ${result.message}');
}
```

#### In Backend Endpoint (`PUT /api/auth/profile`):
```python
# Defined in backend/app/routers/auth.py (update_profile)
updates = []
params = []

if req.name is not None and req.name.strip():
    updates.append("name = ?")
    params.append(req.name.strip())

if req.phone is not None:
    updates.append("phone = ?")
    params.append(clean_phone(req.phone))  # Validated 10 digits

if updates:
    params.append(user_id)
    cursor.execute(f"UPDATE users SET {', '.join(updates)} WHERE id = ?", tuple(params))
    conn.commit()
```

---

### 3.5 Safe Handling of Nullable User Fields

> [!IMPORTANT]
> Google OAuth users often do not have a phone number, address, or date of birth upon initial registration. Never assume these fields are non-null. Never save system identifiers (like `g_100435...`) as phone numbers.

#### Safe Phone Access Pattern:
```dart
// Flutter
String phoneDisplay = 'Not added';
if (user.phone != null && user.phone!.trim().isNotEmpty) {
  phoneDisplay = '+91 ${user.phone}';
}
// Or use built-in helper:
String safePhone = UserSession.instance.displayPhone;
```

#### Sanitizing Incoming Phone Numbers (Backend):
```python
# Defined in backend/app/routers/auth.py
from app.routers.auth import sanitize_phone_value

safe_phone = sanitize_phone_value(raw_input)
# Returns genuine 10-digit string (e.g. '9876543210') or None if placeholder/invalid
```

---

### 3.6 Accessing Child Data in Flutter

In Flutter, use [`ApiService.instance.fetchChildren()`](file:///frontend/lib/core/services/api_service.dart#L796) to retrieve all children belonging to the authenticated parent from `GET /api/children`:

```dart
import 'package:frontend/core/models/child_model.dart';
import 'package:frontend/core/services/api_service.dart';

Future<void> loadChildrenExample() async {
  // Fetches list of ChildModel from backend SQLite database
  final List<ChildModel> children = await ApiService.instance.fetchChildren();

  for (final child in children) {
    print('Child ID: ${child.id}');
    print('Parent ID: ${child.parentId}');
    print('Name: ${child.name}');
    print('DOB: ${child.dob}');
    print('Age: ${child.ageDisplay}'); // Calculated human-readable string (e.g. '2 yr 3 mo')
    print('Weight: ${child.weight != null ? "${child.weight} kg" : "Not recorded"}');
    print('Gender: ${child.gender}');
  }
}
```

---

### 3.7 Accessing Child Data in FastAPI Backend

The endpoint `GET /api/children` in [`backend/app/routers/auth.py`](file:///backend/app/routers/auth.py#L1671) isolates children by the authenticated parent's ID:

```python
from fastapi import Header
from app.routers.auth import get_authenticated_user_id
from app.database import get_db
from app.schemas import ChildResponse
from typing import List

def get_children(authorization: str = Header(None)) -> List[ChildResponse]:
    parent_id = get_authenticated_user_id(authorization)

    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT id, parent_id, name, dob, weight, gender, created_at, updated_at
            FROM children
            WHERE parent_id = ?
            ORDER BY id ASC
        """, (parent_id,))
        rows = cursor.fetchall()

        return [
            ChildResponse(
                id=r["id"],
                parent_id=r["parent_id"],
                name=r["name"],
                dob=r["dob"],
                weight=r["weight"],
                gender=r["gender"],
                created_at=r["created_at"],
                updated_at=r["updated_at"]
            )
            for r in rows
        ]
```

---

### 3.8 Direct SQLite Database Access for Children

```python
from app.database import get_db

def fetch_children_for_parent(parent_id: int):
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT id, name, dob, weight, gender, created_at 
            FROM children 
            WHERE parent_id = ?
        """, (parent_id,))
        return cursor.fetchall()
```

---

### 3.9 Handling Multiple Children for a Single Parent

When a parent has multiple children registered, use standard collection operations in Dart:

```dart
final List<ChildModel> children = await ApiService.instance.fetchChildren();

if (children.isEmpty) {
  print('No children registered yet.');
  return;
}

// 1. Get the first child
final ChildModel primaryChild = children.first;
print('First child: ${primaryChild.name}');

// 2. Find a specific child by Child ID
final int targetChildId = 42;
final ChildModel? specificChild = children.cast<ChildModel?>().firstWhere(
  (c) => c?.id == targetChildId,
  orElse: () => null,
);

// 3. Find a child by name (case-insensitive)
final ChildModel? aarav = children.cast<ChildModel?>().firstWhere(
  (c) => c?.name.toLowerCase() == 'aarav',
  orElse: () => null,
);

// 4. Find the youngest child (latest date of birth)
final ChildModel youngest = children.reduce(
  (curr, next) => DateTime.parse(curr.dob).isAfter(DateTime.parse(next.dob)) ? curr : next
);
print('Youngest child: ${youngest.name} (${youngest.ageDisplay})');

// 5. Filter children by gender
final List<ChildModel> girls = children.where((c) => c.gender == 'Girl').toList();
```

---

### 3.10 Calculating Child Age from Date of Birth

The application computes child age dynamically rather than storing a static age integer that becomes obsolete over time.

#### Flutter Implementation ([`frontend/lib/core/models/child_model.dart`](file:///frontend/lib/core/models/child_model.dart#L58-L86)):
```dart
String get ageDisplay {
  try {
    final birthDate = DateTime.parse(dob); // dob is 'YYYY-MM-DD'
    final today = DateTime.now();

    int years = today.year - birthDate.year;
    int months = today.month - birthDate.month;
    int days = today.day - birthDate.day;

    if (days < 0) {
      months -= 1;
    }
    if (months < 0) {
      years -= 1;
      months += 12;
    }

    if (years > 0) {
      return months > 0 ? '$years yr $months mo' : '$years yr old';
    } else if (months > 0) {
      return '$months month${months > 1 ? 's' : ''} old';
    } else {
      final totalDays = today.difference(birthDate).inDays;
      return '$totalDays day${totalDays > 1 ? 's' : ''} old';
    }
  } catch (_) {
    return '';
  }
}
```

#### Python / FastAPI Backend Calculation:
```python
from datetime import datetime, date

def calculate_age_details(dob_str: str) -> dict:
    """Calculates years, months, and total age in months from YYYY-MM-DD string."""
    birth_date = datetime.strptime(dob_str, "%Y-%m-%d").date()
    today = date.today()

    years = today.year - birth_date.year
    months = today.month - birth_date.month
    days = today.day - birth_date.day

    if days < 0:
        months -= 1
    if months < 0:
        years -= 1
        months += 12

    total_months = (years * 12) + months
    return {
        "years": years,
        "months": months,
        "total_months": total_months,
        "display": f"{years} yr {months} mo" if years > 0 else f"{months} months old"
    }
```

---

## 4. API Reference & Endpoints

All endpoints support both `/api/...` and root `/...` prefixes.

| Endpoint | HTTP Method | Authentication | Purpose | Response Variables |
|---|---|---|---|---|
| `/api/auth/register` | `POST` | None | Registers new caregiver, stores unverified user in SQLite, dispatches 6-digit OTP email | `success`, `message`, `requires_verification`, `email`, `cooldown_seconds` |
| `/api/auth/login` | `POST` | None | Authenticates email/phone & password against SQLite credentials; blocks unverified users | `success`, `message`, `token`, `user` (`UserResponse`), `requires_verification` |
| `/api/auth/verify-otp` | `POST` | None | Verifies 6-digit OTP code against SQLite cryptographic hash, activates user account | `success`, `message`, `token`, `user` (`UserResponse`) |
| `/api/auth/resend-otp` | `POST` | None | Issues a fresh 5-minute OTP code (enforcing 60-second cooldown) | `success`, `message`, `requires_verification`, `email`, `cooldown_seconds` |
| `/api/auth/google` | `POST` | None (Google ID Token) | Verifies Google ID token, links/creates active user with `phone=NULL`, returns session token | `success`, `message`, `token`, `user` (`UserResponse`) |
| `/api/auth/forgot-password`| `POST` | None | Generates 15-minute password reset token hash and emails reset link via Resend | `success`, `message` (neutral anti-enumeration message) |
| `/api/auth/reset-password` | `POST` | None | Validates single-use reset token hash, updates password hash in SQLite database | `success`, `message` |
| `/api/auth/reset-password` | `GET` | None | Serves the web-based interactive HTML password reset form | HTML Page |
| `/api/auth/me` | `GET` | `Bearer <token>` | Retrieves currently authenticated user profile from SQLite | `UserResponse` (`id`, `name`, `phone`, `email`, `dob`, etc.) |
| `/api/auth/profile` | `PUT` / `PATCH` | `Bearer <token>` | Updates profile details (name, phone, dob, address, pin_code, etc.) for logged-in user | `UserResponse` (updated record) |
| `/api/onboarding/step-1` | `POST` / `PUT` | `Bearer <token>` | Saves Step 1 Caregiver profile information; advances `onboarding_step` to 1 | `UserResponse` (`onboarding_step=1`) |
| `/api/onboarding/step-2` | `POST` | `Bearer <token>` | Saves one or multiple children linked to parent; marks `is_profile_complete=1` | `success`, `message`, `children` (List of `ChildResponse`) |
| `/api/onboarding/skip-step-2` | `POST` | `Bearer <token>` | Skips Step 2 ("Add Later"); marks `is_profile_complete=1`, `onboarding_step=2` | `success`, `message` |
| `/api/children` | `GET` | `Bearer <token>` | Retrieves all children profiles belonging strictly to the authenticated parent | List of `ChildResponse` (`id`, `parent_id`, `name`, `dob`, `weight`, `gender`) |
| `/api/children` | `POST` | `Bearer <token>` | Adds an individual child profile linked to the authenticated parent | `ChildResponse` (`id`, `parent_id`, `name`, `dob`, `weight`, `gender`) |
| `/api/auth/users` | `GET` | None | Admin verification endpoint listing all registered users in SQLite | List of `UserResponse` |
| `/health` | `GET` / `HEAD` | None | System keep-alive health check for Render and external uptime monitors | `{"status": "ok"}` |

---

### Example API Payloads

#### 1. Onboarding Step 1 (Save Caregiver Profile)
* **Request:** `POST /api/onboarding/step-1`
* **Headers:** `Authorization: Bearer <JWT>`, `Content-Type: application/json`
```json
{
  "name": "Pooja Patel",
  "phone": "9825012345",
  "dob": "1994-08-22",
  "gender": "Female",
  "address": "B-202 Shivalik Heights, SG Highway",
  "city": "Ahmedabad",
  "state": "Gujarat",
  "district": "Ahmedabad",
  "pin_code": "380054"
}
```
* **Response (HTTP 200):**
```json
{
  "id": 14,
  "name": "Pooja Patel",
  "phone": "9825012345",
  "email": "pooja.patel@gmail.com",
  "role": "parent",
  "language": "ગુજરાતી (Gujarati)",
  "state": "Gujarat",
  "district": "Ahmedabad",
  "dob": "1994-08-22",
  "gender": "Female",
  "address": "B-202 Shivalik Heights, SG Highway",
  "city": "Ahmedabad",
  "pin_code": "380054",
  "avatar_url": "https://lh3.googleusercontent.com/a/...",
  "auth_provider": "google",
  "is_verified": true,
  "is_profile_complete": false,
  "onboarding_step": 1,
  "created_at": "2026-10-31T07:15:30.123456+00:00"
}
```

#### 2. Onboarding Step 2 (Batch Create Children)
* **Request:** `POST /api/onboarding/step-2`
* **Headers:** `Authorization: Bearer <JWT>`, `Content-Type: application/json`
```json
{
  "children": [
    {
      "name": "Aarav Patel",
      "dob": "2023-04-15",
      "weight": 11.8,
      "gender": "Boy"
    },
    {
      "name": "Diya Patel",
      "dob": "2025-01-10",
      "weight": 6.2,
      "gender": "Girl"
    }
  ]
}
```
* **Response (HTTP 200):**
```json
{
  "success": true,
  "message": "Successfully registered 2 child profile(s). Profile onboarding is complete!",
  "children": [
    {
      "id": 101,
      "parent_id": 14,
      "name": "Aarav Patel",
      "dob": "2023-04-15",
      "weight": 11.8,
      "gender": "Boy",
      "created_at": "2026-10-31T07:18:22.987654+00:00",
      "updated_at": null
    },
    {
      "id": 102,
      "parent_id": 14,
      "name": "Diya Patel",
      "dob": "2025-01-10",
      "weight": 6.2,
      "gender": "Girl",
      "created_at": "2026-10-31T07:18:22.987654+00:00",
      "updated_at": null
    }
  ]
}
```

---

## 5. Important Architectural & Security Rules

### 5.1 Database Schema & Tables
1. **`users`**: Contains primary accounts, authentication hashes, and caregiver demographics.
2. **`children`**: Contains children belonging to parents (`parent_id REFERENCES users(id)`).
3. **`child_profiles`**: Historical / compatibility table mirroring child records with additional nutritional fields (`current_weight_kg`, `age_months`, etc.).
4. **`oauth_accounts`**: Maps Google `sub` (provider ID) to the internal `user_id`.
5. **`email_otps`**: Stores SHA-256 OTP hashes, expiry dates (5 minutes), and attempt counters.
6. **`password_resets`**: Stores single-use reset token hashes with 15-minute expiry.

---

### 5.2 Parent-Child Relational Link (Foreign Keys)
In SQLite:
```sql
FOREIGN KEY (parent_id) REFERENCES users(id) ON DELETE CASCADE
```
* Every child must have a valid `parent_id` matching an existing record in `users`.
* If a user account is deleted, all associated children in `children` and `child_profiles` are automatically deleted via `ON DELETE CASCADE`.

---

### 5.3 Identifying the Authenticated User (Bearer Tokens)
* The client sends the header: `Authorization: Bearer <token>`.
* In [`backend/app/security.py`](file:///backend/app/security.py), the JWT contains the payload:
  ```json
  {
    "uid": 14,
    "phone": "9825012345",
    "exp": 1793440000
  }
  ```
* In [`backend/app/routers/auth.py`](file:///backend/app/routers/auth.py#L1379), `get_authenticated_user_id(authorization)` extracts `payload["uid"]`.
* **Security Rule:** Never accept `parent_id` or `user_id` from client request bodies. Always derive it exclusively from the verified JWT bearer token.

---

### 5.4 Multi-Tenant Data Isolation (Preventing Leaks)
To guarantee Parent A can never view or modify Parent B's children:
```sql
-- CORRECT (Data Isolated):
SELECT * FROM children WHERE parent_id = ? AND id = ?;

-- INCORRECT (Security Vulnerability):
SELECT * FROM children WHERE id = ?;
```
Every child query in the backend includes `WHERE parent_id = ?`, passing the token's authenticated `uid`.

---

### 5.5 Mandatory vs. Nullable Fields Matrix

| Table | Column | Nullable? | Rules & Validations |
|---|---|---|---|
| `users` | `name` | **NO** | Min length 1, max 100. |
| `users` | `phone` | **YES** | Nullable for OAuth. If provided, must be exactly 10 digits starting with 6, 7, 8, or 9. Cannot start with `g_`, `a_`, `sub_`. |
| `users` | `email` | **YES** | Required for local registration; verified by OTP. |
| `users` | `password_hash` | **YES** | Nullable / dummy for Google OAuth users. |
| `users` | `dob` | **YES** | Optional `YYYY-MM-DD`. |
| `users` | `gender` | **YES** | Optional (`Female`, `Male`, `Other`). |
| `users` | `pin_code` | **YES** | If provided, must be exactly 6 numeric digits. |
| `children` | `parent_id` | **NO** | Mandatory foreign key linking to `users.id`. |
| `children` | `name` | **NO** | Child's full name (min 1 character). |
| `children` | `dob` | **NO** | Mandatory `YYYY-MM-DD`. |
| `children` | `gender` | **NO** | Mandatory (`Boy`, `Girl`, or `Other`). |
| `children` | `weight` | **YES** | Optional floating point numeric in kg (e.g. `11.5`). |

---

## 6. Quick Cheat Sheet for Future Developers

```text
========================================================================================
FEATURE                         FLUTTER CLIENT ACCESS                     BACKEND HANDLER
========================================================================================
Logged-in User Name             UserSession.instance.displayName          row["name"] / user.name
Logged-in User Email            UserSession.instance.currentUser?.email   row["email"] / user.email
Logged-in User Mobile           UserSession.instance.displayPhone         sanitize_phone_value(row["phone"])
Logged-in User Token            UserSession.instance.currentToken         Authorization: Bearer <token>
Is Onboarding Finished?         user.isProfileComplete (bool)             bool(row["is_profile_complete"])

Fetch All Children              ApiService.instance.fetchChildren()       GET /api/children
Child Name                      child.name                                row["name"]
Child Date of Birth             child.dob ('YYYY-MM-DD')                  row["dob"]
Child Human Age                 child.ageDisplay ('2 yr 3 mo')            calculate_age_details(dob)
Child Current Weight            child.weight (double? in kg)              row["weight"] (float? in kg)
Child Gender                    child.gender ('Boy'/'Girl'/'Other')       row["gender"]
========================================================================================
```

