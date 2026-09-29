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

### No Silent Fallbacks
If primary authentication or configuration fails, the system safely raises a configuration error and enters a `CONFIG_INVALID` diagnostic state. It will **not** silently fall back to `mock`, preventing unexpected production behavior where an invalid key quietly switches to deterministic mock responses.

### Testing & Security
Tests automatically execute within a secure, isolated `mock` environment, preventing accidental usage of real developer credentials inside test suites. 
Tests never expose API keys or secrets in logs, messages, or diagnostics.

### Safe Diagnostics & Smoke Test
You can safely run diagnostics on your provider configuration without making external network calls (Dry-Run mode):

```powershell
python scripts/llm_smoke_test.py
```

This will print the configured provider, model, local initialization state, and capability mappings without hitting the API.

Diagnostic states include:
- `NOT_CONFIGURED`: Missing credentials for the selected provider.
- `CONFIG_INVALID`: Malformed configuration or unsupported provider.
- `READY_LOCAL`: Provider constructed successfully, awaiting remote call.
- `REMOTE_VERIFIED`: Remote endpoint responded successfully (requires `--real`).
- `REMOTE_FAILED`: Remote endpoint returned an error (requires `--real`).

To run a **REAL** network test against your explicitly configured provider, use the `--real` flag. This will send exactly ONE minimal prompt ("Reply with exactly: ApplyX smoke test successful") and print usage metadata and any normalized errors (like quotas or auth failures).

```powershell
python scripts/llm_smoke_test.py --real
```

## Provider-Agnostic Search Architecture

The backend implements a generic `SearchProvider` abstraction to decouple research from specific search engines (Tavily, Google, etc.). This ensures that ApplyX can securely retrieve opportunities without vendor lock-in.

### Note: Search Provider ≠ LLM Provider
Search providers and LLM providers are strictly separate abstractions. Switching the LLM provider does not affect the search provider, and vice versa.

### Supported Search Providers
- **mock**: Deterministic offline mock data, ideal for tests.
- **tavily**: Official API integration for Tavily search. Minimal footprint utilizing `httpx`.

### Configuration
```env
SEARCH_PROVIDER=tavily
SEARCH_API_KEY=your_tavily_key
SEARCH_BASE_URL=https://api.tavily.com # Optional override
```

### Search Diagnostics & Smoke Test
You can verify your search credentials securely without calling APIs (dry-run):
```powershell
python scripts/search_smoke_test.py
```

To run a single real search query:
```powershell
python scripts/search_smoke_test.py --real
```

### Research Safety & Evidence Preservation
- **Deduplication**: Results are cleanly extracted, retaining the canonical source domain.
- **Evidence Preservation**: Every opportunity preserves the `source_url`, `source_name`, and `retrieved_at` timestamps to ensure verification is possible. No missing information is fabricated.
- **Execution Guardrails**: The search adapter securely passes back content strictly as data strings. Web content is considered untrusted and never interpreted as code.

## Phase 6 Provider-Agnostic Agent Execution

The agent runtime is now fully decoupled from any specific LLM or search provider.
All agent classes (Planner, Research, Eligibility, Profile Fit) use the generic LLM abstractions rather than concrete provider implementations.

- **LLM Abstraction**: Agents rely strictly on `LLMRequest` and `LLMResponse` models and the `LLMProvider` interface.
- **Search Abstraction**: The `web_search` tool interacts exclusively through the `SearchProvider` interface.
- **Mock Mode**: By default, the system operates in a fully deterministic mock mode (`LLM_PROVIDER=mock`, `SEARCH_PROVIDER=mock`) without making any external API calls. This enables stable end-to-end workflow execution in tests.
- **Real-Provider Configuration Boundary**: Switching to a real provider is a matter of changing environment variables (e.g., `LLM_PROVIDER=openai`). No business logic or agent code requires modification.
- **End-to-End Execution Flow**:
  Goal -> Planner -> Research -> Eligibility -> Profile Fit -> Verification -> Approval Boundary. This sequence executes deterministically using generic abstractions.
- **Approval Boundary**: The orchestrator strictly respects the configured risk levels and halts on `HIGH` or `CRITICAL` actions lacking approval.
- **Test Commands**:
  ```powershell
  python -m pytest
  ```

### Phase 6 Agent Quality & Robustness
- **Quality Gate**: A rigorous final verification step executed before transitioning a run to `COMPLETED`. Validates schema integrity, evidence coverage, source attribution, duplicate removal, and consistency between specialist outputs.
- **Robust Error Taxonomy**: Distinguishes agent failures cleanly (e.g., `provider_timeout`, `validation_error`, `malformed_model_output`, `approval_required`) for accurate diagnostics.
- **Explainable Results**: Eligibility and Profile-Fit outputs strictly enforce transparent reasoning. Outcomes are categorized clearly (`clearly_eligible`, `clearly_not_eligible`, `uncertain`, `insufficient_evidence`) with detailed explanations for matches and gaps, rather than relying on arbitrary numerical scores.
- **Bounded Retries**: Transient task failures are retried safely at the Orchestrator level according to configured guardrails before propagating a run failure.
- **Detailed Observability**: Extended `AgentEventType` models accurately capture granular sub-steps (e.g., `planning_started`, `normalization_completed`, `quality_gate_passed`) to build a transparent, step-by-step audit timeline.

## Live Provider Adapter Layer
The backend utilizes robust provider adapters (OpenAI, Gemini, OpenAI-compatible, Tavily) to execute against real APIs securely.
- **Generic Normalization**: Provider-specific responses are parsed and mapped to common structures, ensuring business agents remain provider-agnostic.
- **Error Mapping**: Network, rate-limit, timeout, and authentication failures are safely mapped to unified generic errors.
- **Resilience**: Configurable hard timeouts and bounded retry mechanisms handle transient provider unavailability without causing infinite loops or blocking indefinitely.
- **Safe Testing**: Normal adapter tests completely mock HTTP boundaries, guaranteeing no real API requests or quota are consumed during development.
