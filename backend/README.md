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
   **OpenAI Key**: To enable the Phase 4 real LLM functionality, add `OPENAI_API_KEY=your-key` to `.env`.
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
- Supports both `OpenAILLMProvider` (when `OPENAI_API_KEY` is set) and a fallback `MockLLMProvider` for offline testing.

### Testing Phase 3 and Phase 4
Comprehensive test suites cover state machines, validation, risk policies, and API.
Run tests using:
```powershell
.\.venv\Scripts\python.exe -m pytest
```

## Phase 4 Architecture: Real LLM Integration

The backend has been upgraded to Phase 4, transitioning from deterministic mocks to a real LLM-powered reasoning engine.

### Real LLM Capabilities
- **Structured Planner**: Uses OpenAI's structured outputs (`response_format`) to generate robust, schema-compliant `AgentPlan`s dynamically.
- **Web Research**: The Research Agent is powered by an LLM loop using `Tool Calling` (`tools` parameter) to formulate queries and extract real-world opportunities dynamically.
- **Eligibility & Profile Fit**: Specialist agents process the authenticated profile against normalized opportunity requirements to provide evidence-backed, reasoned analysis instead of deterministic matching.
- **Fallback safety**: Missing keys cleanly fall back to Phase 3 Mock agents without crashing.
### Background Execution
- Agent orchestration runs asynchronously without blocking HTTP requests.

## Phase 6 Architecture: Provider-Agnostic LLM Layer

The backend implements a generic, provider-neutral LLM abstraction layer to ensure the application is not locked to a single AI vendor.

### Supported Providers
- **mock**: Deterministic local testing, no API key required.
- **openai**: Official OpenAI SDK integration (GPT-4o, etc).
- **gemini**: Google Gemini integration using OpenAI compatibility.
- **openai_compatible**: Generic adapter for any HTTP endpoint matching the OpenAI schema (e.g. Local models, OpenRouter, Groq).

### Configuration
Change providers via `.env` variables (no code changes required):
```env
LLM_PROVIDER=openai
LLM_MODEL=gpt-4o-mini
LLM_API_KEY=your_key_here
LLM_BASE_URL= # Required only for openai_compatible
```

### Capabilities
The generic interface safely reports capabilities:
- `structured_output`
- `tool_calling`
- `json_mode`

### Fallback Semantics
If primary authentication fails, the system safely falls back using:
- `LLM_FALLBACK_PROVIDER=mock`

### Testing & Security
Tests automatically execute within a secure, isolated `mock` environment, preventing accidental usage of real developer credentials inside test suites. 
Tests never expose API keys or secrets in logs, messages, or diagnostics.

### Safe Diagnostics & Smoke Test
You can safely run diagnostics on your provider configuration without making external network calls (Dry-Run mode):

```powershell
python scripts/llm_smoke_test.py
```

This will print the configured provider, model, local initialization state, and capability mappings without hitting the API.

To run a **REAL** network test against your explicitly configured provider, use the `--real` flag. This will send exactly ONE minimal prompt ("Reply with exactly: ApplyX smoke test successful") and print usage metadata and any normalized errors (like quotas or auth failures).

```powershell
python scripts/llm_smoke_test.py --real
```
