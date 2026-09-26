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

## Phase 3 Architecture: Agentic AI Runtime

The backend now includes a modular, deterministic Agentic AI runtime with strict policy controls and observability.

### Agent Lifecycle & State Machine
- **State Machine**: Agent runs transition through `QUEUED`, `PLANNING`, `RUNNING`, `WAITING_FOR_INPUT`, `WAITING_FOR_APPROVAL`, `COMPLETED`, `FAILED`, and `CANCELLED`.
- **Orchestrator**: A stateful orchestrator (`app.agents.orchestrator`) loads the goal/profile, delegates planning, validates the plan, executes tasks in dependency order, and collects evidence.

### Specialist Agents
- **Planner**: Generates a structured execution plan based on goal constraints.
- **Research**: Searches for opportunities and captures source-backed evidence.
- **Eligibility**: Parses requirements against the user's profile and determines eligibility with confidence scores.
- **Profile Fit**: Evaluates profile facts against requirements without fabricating experience.
- **Document**: Drafts artifacts like cover letters or resumes using verified facts.
- **Verification**: Verifies all task outputs, checks evidence lists, downgrades unsupported claims, and detects dependency cycles.
- **Action**: Prepares actionable payloads and strictly enforces the approval policy.

### Tool Registry & Risk Policy
- **Registry**: Centralized tool execution gateway (`app.tools.registry`).
- **Built-in Safe Tools**: `calculate_match_signals`, `normalize_opportunity`, `summarize_evidence`, `create_draft_artifact`, `persist_agent_event`.
- **Policy Gate**:
  - `LOW`: Executes automatically.
  - `MEDIUM`: Executes automatically (within authenticated workspace boundaries).
  - `HIGH`: Blocked without explicit `approval_granted=True`.
  - `CRITICAL`: Fully blocked for MVP.

### Persistence
- Agent runs, tasks, tool calls, and events are persisted securely enforcing user ownership.
- Data structures align exactly with Supabase DB schema (`agent_runs`, `agent_tasks`, `tool_calls`, `agent_events`).

### LLM Abstraction
- A clean `LLMProvider` interface handles generation (`app.services.llm_service`).
- Currently defaults to `MockLLMProvider` ensuring tests and Phase 3 run deterministically without requiring an API key.

### Testing Phase 3
Phase 3 comes with a comprehensive test suite (40+ tests) covering state machines, validation, risk policies, and API.
Run tests using:
```powershell
.\.venv\Scripts\python.exe -m pytest
```
