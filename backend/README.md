# ApplyX Backend

This is the FastAPI backend for the ApplyX application.

## Prerequisites

- Python 3.10+
- PowerShell (for Windows setups)

## Setup Instructions

1. **Virtual Environment Setup (PowerShell)**:
   Navigate to the backend directory and create a virtual environment:
   ```powershell
   cd E:\ApplyX\backend
   python -m venv .venv
   ```

2. **Activation Command**:
   Activate the virtual environment:
   ```powershell
   .\.venv\Scripts\Activate.ps1
   ```

3. **Package Installation**:
   Install the required dependencies:
   ```powershell
   pip install -r requirements.txt
   ```

4. **Environment Variable Setup**:
   Copy the example environment file and configure it:
   ```powershell
   cp .env.example .env
   ```
   **Security Warning**: The `SUPABASE_SERVICE_ROLE_KEY` is a highly privileged, backend-only secret. It bypasses Row Level Security. It must NEVER be exposed to Flutter or any client-side code.

5. **How to Run FastAPI**:
   Run the development server:
   ```powershell
   uvicorn app.main:app --reload
   ```
   The API will be available at `http://localhost:8000`.

6. **How to Run Tests**:
   Execute the test suite using pytest:
   ```powershell
   pytest
   ```

## Phase 2 Architecture

The backend now serves as a secure, authenticated API layer utilizing Supabase for data access.

### Authentication Flow
1. Flutter client authenticates via Supabase Auth.
2. Client receives a Supabase JWT.
3. Client includes the JWT in the `Authorization` header:
   ```
   Authorization: Bearer <Supabase JWT>
   ```
4. FastAPI `get_current_user` dependency verifies the JWT signature securely via the Supabase Python SDK.
5. Ownership checks and Row Level Security enforcement are performed using the authenticated user identity (not client-provided data).

### API Endpoints

**Health**
- `GET /health`
- `GET /api/v1/health`

**Profiles**
- `GET /api/v1/profiles/me`
- `PUT /api/v1/profiles/me`

**Goals**
- `POST /api/v1/goals`
- `GET /api/v1/goals`
- `GET /api/v1/goals/{goal_id}`
- `PATCH /api/v1/goals/{goal_id}`

**Opportunities**
- `GET /api/v1/opportunities`
- `GET /api/v1/opportunities/{opportunity_id}`
- `POST /api/v1/opportunities/{opportunity_id}/save`

**Applications**
- `GET /api/v1/applications`
- `POST /api/v1/applications`
- `PATCH /api/v1/applications/{application_id}`

### Example Curl Request

```bash
curl -X GET http://localhost:8000/api/v1/profiles/me \
  -H "Authorization: Bearer YOUR_SUPABASE_JWT"
```
