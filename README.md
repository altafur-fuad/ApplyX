# ApplyX

ApplyX is a mobile-first agentic AI opportunity-management app for students and early-career users.

The core workflow is:

```text
User Goal
  ↓
Agent Plan
  ↓
Research
  ↓
Eligibility Analysis
  ↓
Profile Fit Analysis
  ↓
Application Preparation
  ↓
Verification
  ↓
Human Approval
  ↓
Action / Tracking
```

ApplyX is not a generic chatbot. The product is built around observable, tool-using agent workflows with explicit human approval for consequential external actions.

## Project Documentation

Read these in this order before implementing features:

1. `PRD.md` — product requirements and MVP scope.
2. `architecture.md` — technical architecture and service boundaries.
3. `design.md` — UI/UX, Figma workflow, design system and Flutter handoff.
4. `rules.md` — engineering, security, agent and coding rules.
5. `memory.md` — durable project context and decisions.
6. `task.md` — master execution checklist.
7. `AGENT_SPEC.md` — agent state machine, tools, schemas, guardrails and execution contract.
8. `API_SPEC.md` — backend API contract.
9. `database.sql` — Supabase/PostgreSQL schema and RLS baseline.
10. `folder-structure.md` — canonical repository structure.
11. `DEPLOYMENT.md` — staging, Android, iOS and production release flow.
12. `.env.example` — required environment variables and where each secret belongs.

## Recommended Stack

- Flutter / Dart — Android + iOS client
- Supabase — Auth, PostgreSQL, Storage, Realtime where useful
- FastAPI / Python — backend API and privileged operations
- Agent orchestration — LangGraph or another stateful graph workflow library selected during implementation
- LLM provider — selected and documented before integration
- Push notifications — provider selected during implementation

## Repository Layout

See `folder-structure.md`.

## Local Setup

### Prerequisites

Install:

- Flutter SDK
- Android Studio / Android SDK
- Git
- Python 3.12+ recommended for backend
- PostgreSQL client tools optional
- A Supabase project

For iOS builds, use a supported macOS + Xcode environment or a macOS CI service.

### 1. Clone

```bash
git clone <YOUR_REPOSITORY_URL>
cd applyx
```

### 2. Create local environment files

Flutter should receive only public client configuration such as the Supabase project URL and publishable/anon client key.

Backend receives privileged secrets.

```bash
cp .env.example .env
```

Never commit a real `.env` file.

### 3. Create Supabase project

Create a development project, then run `database.sql` using the Supabase SQL editor or an equivalent migration workflow.

After running the schema, verify:

- tables exist;
- foreign keys are present;
- RLS is enabled;
- authenticated users can access only their own private rows;
- public opportunity rows remain readable only as intended.

### 4. Backend

```bash
cd backend
python -m venv .venv
# Windows PowerShell
.venv\Scripts\Activate.ps1
# macOS/Linux
# source .venv/bin/activate

pip install -r requirements.txt
uvicorn app.main:app --reload
```

### 5. Flutter

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Environment Separation

Use three environments when possible:

```text
Development → developer machines
Staging     → internal testing / TestFlight / Play testing
Production  → real users
```

Never point a local build accidentally at production credentials.

## First Implementation Slice

Do not build the whole roadmap at once. The first end-to-end vertical slice should be:

```text
Signup/Login
  ↓
Profile
  ↓
Create Goal
  ↓
Start Agent Run
  ↓
Research one approved source
  ↓
Return normalized opportunities
  ↓
Show evidence + fit explanation
  ↓
Save opportunity
```

After that slice is stable, add document generation, verification, approvals, notifications and external actions.

## Definition of Done

A feature is complete when:

- implementation works;
- UI matches the Figma source of truth or the deviation is documented;
- loading, empty and error states are handled;
- tests cover the important behavior;
- security/privacy implications are reviewed;
- relevant documentation is updated;
- no secrets are committed;
- `flutter analyze` and relevant backend tests pass.

## Important Product Rule

AI should not fabricate qualifications, deadlines, eligibility guarantees, organization details, or application facts. Source-backed facts and AI-generated interpretation must remain distinguishable in both the data model and UI.
