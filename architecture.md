# ApplyX — System Architecture

**Version:** 1.0.0
**Architecture Style:** Mobile client + backend API + agent orchestration + managed data services

---

## 1. Architecture Goal

Build a modular, testable and production-oriented agentic application where Flutter owns presentation and local interaction, Supabase owns authentication/data/storage, FastAPI owns privileged backend logic, and the agent orchestration layer coordinates tools and specialist agents.

---

## 2. High-Level Architecture

```text
┌───────────────────────────────┐
│         Flutter App           │
│ Android / iOS                 │
│ UI + State + Routing          │
└───────────────┬───────────────┘
                │ HTTPS
                ▼
┌───────────────────────────────┐
│           FastAPI             │
│ Auth context / API / policy   │
└───────────────┬───────────────┘
                │
        ┌───────┴────────┐
        ▼                ▼
┌──────────────┐  ┌───────────────────┐
│  Supabase    │  │ Agent Orchestrator│
│ Auth / DB /  │  │ Planner + Graph   │
│ Storage      │  └─────────┬─────────┘
└──────────────┘            │
                            ▼
                    ┌────────────────┐
                    │ Tool Registry  │
                    └───────┬────────┘
                            │
             ┌──────────────┼──────────────┐
             ▼              ▼              ▼
        Search/Data      LLM Provider   Other APIs
             │              │              │
             └──────────────┼──────────────┘
                            ▼
                    Verification Layer
                            │
                            ▼
                    Human Approval Gate
                            │
                            ▼
                       Action Tool
```

---

## 3. Architectural Principles

- Thin Flutter client.
- Backend owns privileged operations.
- Agent tools are explicitly registered.
- Every important agent step is observable.
- Database access is least-privilege.
- External side effects require explicit authorization.
- LLM output is treated as untrusted data.
- Agent state is persisted, not held only in memory.
- Design for failure and retry from day one.

---

## 4. Flutter Architecture

Recommended feature-first structure:

```text
lib/
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── bootstrap.dart
│
├── core/
│   ├── constants/
│   ├── errors/
│   ├── network/
│   ├── theme/
│   ├── widgets/
│   └── utils/
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── onboarding/
│   ├── home/
│   ├── profile/
│   ├── goals/
│   ├── agent_runs/
│   ├── opportunities/
│   ├── applications/
│   ├── documents/
│   └── settings/
│
└── services/
    ├── auth_service.dart
    ├── api_service.dart
    ├── supabase_service.dart
    └── notification_service.dart
```

State management can use Riverpod/Bloc/Provider. Pick one and use it consistently; do not mix multiple state-management approaches without a documented reason.

---

## 5. Backend Architecture

```text
backend/
├── app/
│   ├── main.py
│   ├── api/
│   │   ├── auth.py
│   │   ├── profiles.py
│   │   ├── goals.py
│   │   ├── agents.py
│   │   ├── opportunities.py
│   │   ├── applications.py
│   │   └── documents.py
│   │
│   ├── agents/
│   │   ├── planner.py
│   │   ├── research.py
│   │   ├── eligibility.py
│   │   ├── profile_fit.py
│   │   ├── document.py
│   │   ├── verification.py
│   │   └── action.py
│   │
│   ├── tools/
│   │   ├── registry.py
│   │   ├── search.py
│   │   ├── source_parser.py
│   │   └── action_tools.py
│   │
│   ├── services/
│   │   ├── llm_service.py
│   │   ├── opportunity_service.py
│   │   ├── document_service.py
│   │   └── notification_service.py
│   │
│   ├── models/
│   └── core/
│       ├── config.py
│       ├── security.py
│       ├── logging.py
│       └── policies.py
│
├── tests/
└── requirements.txt
```

---

## 6. API Contract

Recommended initial endpoints:

```text
POST   /v1/goals
GET    /v1/goals
GET    /v1/goals/{id}

POST   /v1/agent-runs
GET    /v1/agent-runs/{id}
POST   /v1/agent-runs/{id}/cancel
GET    /v1/agent-runs/{id}/events

GET    /v1/opportunities
GET    /v1/opportunities/{id}
POST   /v1/opportunities/{id}/save

POST   /v1/documents/draft
GET    /v1/documents/{id}
PATCH  /v1/documents/{id}

GET    /v1/applications
POST   /v1/applications
PATCH  /v1/applications/{id}

POST   /v1/approvals/{id}/approve
POST   /v1/approvals/{id}/reject
```

All endpoints should validate authenticated ownership and input.

---

## 7. Agent Execution Model

### Agent Run

An `agent_run` represents one user goal execution.

```text
agent_run
 ├── plan
 ├── tasks[]
 ├── tool_calls[]
 ├── observations[]
 ├── artifacts[]
 ├── approvals[]
 └── final_result
```

### Task state machine

```text
PENDING
  ↓
RUNNING
  ├──→ FAILED
  ├──→ WAITING_FOR_INPUT
  └──→ COMPLETED
             ↓
        NEXT TASK
```

### Approval state machine

```text
NOT_REQUIRED

or

REQUIRED
  ↓
PENDING
 ├──→ APPROVED → EXECUTED
 └──→ REJECTED → CANCELLED
```

---

## 8. Tool Registry

Every agent tool must define:

```python
ToolDefinition(
    name="search_opportunities",
    description="Search approved opportunity sources",
    input_schema={...},
    output_schema={...},
    risk_level="low",
    requires_approval=False,
    timeout_seconds=30,
)
```

### Risk levels

- `low`: read-only search, parsing, analysis.
- `medium`: writes inside user's own workspace.
- `high`: external communication or submission.
- `critical`: destructive or irreversible actions.

For MVP, high/critical tools must be blocked unless an approval record exists.

---

## 9. Database Design

### users

Use Supabase Auth's user identity rather than duplicating authentication state unnecessarily.

### profiles

```text
id
user_id
full_name
headline
bio
education_level
department
location
work_preference
skills_json
links_json
created_at
updated_at
```

### goals

```text
id
user_id
title
raw_goal
structured_constraints_json
status
created_at
updated_at
```

### agent_runs

```text
id
goal_id
user_id
status
current_step
plan_json
final_summary
started_at
completed_at
error_message
```

### agent_tasks

```text
id
agent_run_id
parent_task_id
agent_type
name
status
input_json
output_json
error_message
started_at
completed_at
```

### tool_calls

```text
id
agent_run_id
task_id
tool_name
input_json
output_json
status
risk_level
created_at
```

### opportunities

```text
id
source_name
source_url
external_id
title
organization
type
location
remote_status
deadline
description
requirements_json
compensation_text
fetched_at
content_hash
```

### opportunity_matches

```text
id
user_id
opportunity_id
eligibility_status
fit_reasons_json
missing_requirements_json
created_at
```

### applications

```text
id
user_id
opportunity_id
status
notes
submitted_at
next_action_at
created_at
updated_at
```

### documents

```text
id
user_id
application_id
kind
title
content
version
created_at
updated_at
```

### approvals

```text
id
user_id
agent_run_id
action_type
target_json
preview_json
risk_level
status
approved_at
rejected_at
```

### notifications

```text
id
user_id
type
title
body
read_at
created_at
```

---

## 10. Security Model

### Client

- No service-role keys.
- No long-lived privileged API secrets.
- Store session credentials using platform-appropriate secure storage.

### Backend

- Authenticate every request.
- Authorize resource ownership.
- Validate all tool input.
- Enforce server-side approval checks.
- Log security-sensitive events.

### Supabase

Use Row Level Security so users can access only resources they own, subject to intentionally shared data rules.

---

## 11. LLM Safety and Reliability

LLM output must be parsed into strict typed structures whenever possible.

Never directly execute arbitrary natural-language output.

Required sequence:

```text
LLM proposal
 ↓
Schema validation
 ↓
Policy validation
 ↓
Tool permission check
 ↓
Execution
```

### Hallucination control

- retain source URLs;
- retain retrieval timestamps;
- label uncertain information;
- use verification for important claims;
- allow "insufficient evidence".

---

## 12. Observability

Log:

- agent run ID;
- task ID;
- user ID in privacy-safe form;
- tool name;
- latency;
- success/failure;
- retry count;
- approval events;
- model/provider metadata where permitted.

Do not log raw secrets or unnecessary sensitive document content.

---

## 13. Notifications

Recommended flow:

```text
Backend event
 ↓
Notification service
 ↓
Push notification
 ↓
Deep link to relevant screen
```

Examples:

- Agent completed → `/agent-run/{id}`
- Approval needed → `/approvals/{id}`
- Deadline approaching → `/applications/{id}`

---

## 14. Offline / Network Behavior

The app should keep cached read-only data when practical.

Agent execution requires network access. Show clear offline states rather than pretending a run started.

Queued actions should never silently execute later unless the user explicitly enabled that behavior and the action is safe.

---

## 15. Deployment Architecture

### Development

```text
Local Flutter
Local FastAPI
Supabase project (dev)
Test AI keys
```

### Staging

```text
Flutter QA build
Staging API
Staging Supabase
Restricted test accounts
```

### Production

```text
Play Store / App Store
     ↓
Production Flutter app
     ↓
Production FastAPI
     ↓
Production Supabase
     ↓
Production external APIs / LLM
```

Never point a store release to development infrastructure.

---

## 16. Environment Strategy

Use:

```text
.env.example
.env.development
.env.staging
.env.production
```

Only non-secret configuration may safely be bundled into the mobile client. All privileged secrets remain server-side.

---

## 17. CI/CD Future Plan

Recommended later:

```text
Git push
 ↓
CI
 ↓
Lint
 ↓
Tests
 ↓
Build
 ↓
Security checks
 ↓
Staging deployment
 ↓
Release approval
 ↓
Production
```

---

## 18. Architecture Decision Rules

When a feature can be implemented entirely in Flutter without secrets, do so.

When a feature requires:

- privileged API keys;
- trusted decision logic;
- database-wide operations;
- agent orchestration;
- external side effects;

it belongs on the backend.

---

## 19. Critical Design Decision

**Do not build the app as one giant agent prompt.**

Use a stateful workflow with explicit tasks, tools, validation, approvals and persistence. This makes the system easier to test, debug, explain and extend.

---
