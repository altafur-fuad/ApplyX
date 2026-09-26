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

## Endpoints

- **Health Endpoint**: `GET /api/v1/health` - Simple JSON response indicating the backend is running.
