# ApplyX — Project Memory

**Purpose:** Durable project context for humans and coding agents.
**Rule:** Keep only stable facts, decisions, constraints and important discoveries. Do not use this as a daily task log.

---

## 1. Project Identity

- Product name: **ApplyX**
- Product category: Agentic AI opportunity/career assistant
- Primary client: Flutter mobile app
- Backend: FastAPI
- Managed services: Supabase Auth, PostgreSQL, Storage and optional Realtime
- AI layer: Agentic workflow with multiple specialist agents + tools
- Design source of truth: Figma

---

## 2. Core Product Idea

ApplyX turns a user's natural-language opportunity goal into a structured agent workflow that researches, analyzes, prepares application artifacts, verifies results, and asks for approval before consequential actions.

The app is intentionally not a generic chat assistant.

---

## 3. Initial User Persona

Primary MVP persona:

- university student / recent graduate;
- technology-oriented;
- seeking internships, research opportunities or hackathons;
- has skills, projects and online profiles;
- wants less manual searching and application preparation.

The initial product should work well for a CSE student profile, but the core data model must not hard-code CSE-specific behavior.

---

## 4. Product Principles

1. Agentic workflow over simple chat.
2. Evidence over unsupported claims.
3. User control over external consequences.
4. Explainability over opaque scores.
5. Modular architecture over giant prompts.
6. Small MVP over feature overload.
7. Mobile-first UX.

---

## 5. Architecture Decisions

### AD-001 — Flutter client

Use Flutter for Android and iOS to maximize shared UI/business-client code.

### AD-002 — FastAPI backend

Privileged logic, agent orchestration and external API access belong server-side.

### AD-003 — Supabase

Use Supabase for authentication, relational data, storage and row-level authorization support.

### AD-004 — Explicit agent workflow

Do not implement the product as one giant prompt. Persist goals, runs, tasks, tool calls and approvals.

### AD-005 — Human approval

External side effects require explicit user approval and server-side enforcement.

### AD-006 — Figma before Flutter

Design the system and core screens in Figma first. Flutter follows documented visual tokens/components.

---

## 6. Stable MVP Scope

### Must have

- auth;
- onboarding/profile;
- goal creation;
- agent planning;
- opportunity research;
- eligibility analysis;
- profile fit analysis;
- document generation;
- verification;
- approval flow;
- application tracker;
- account deletion.

### Nice to have later

- Gmail integration;
- calendar integration;
- GitHub analysis;
- broader source integrations;
- external application assistance;
- advanced analytics.

---

## 7. Agent Roles

```text
Planner
Research
Eligibility
Profile Fit
Document
Verification
Action
```

Each role must have a limited responsibility and explicit tool access.

---

## 8. Risk / Permission Model

Read-only research is low risk.

Writing inside the user's own workspace is medium risk.

External communication/submission is high risk and requires approval.

Destructive operations are critical and require explicit confirmation or should be excluded from MVP.

---

## 9. Design Decisions

- Dark-first professional UI.
- Minimal premium visual direction.
- Avoid generic chatbot aesthetics.
- Agent timeline is a signature UI.
- Opportunity results use source/evidence sections.
- Approval screen is a dedicated trust-critical screen.

---

## 10. Figma Workflow Memory

Recommended order:

```text
Figma foundations
 ↓
Components
 ↓
Onboarding/Auth
 ↓
Core journey
 ↓
Agent UI
 ↓
Applications
 ↓
Prototype
 ↓
Flutter handoff
```

Figma Make should be used to accelerate first-pass exploration, not to replace structured design-system work.

---

## 11. Technical Conventions

- Use feature-first Flutter structure.
- Use typed models.
- Prefer reusable components.
- Centralize design tokens.
- Use API versioning such as `/v1/...`.
- Use UTC/database-consistent timestamps.
- Use schema validation for agent/tool I/O.
- Keep secrets server-side.

---

## 12. Things We Must Not Forget

- Store release must use production backend.
- Account deletion must actually remove relevant user data.
- Opportunity information can become stale; preserve source/fetched time.
- AI output can be wrong; expose uncertainty.
- External actions need approvals.
- Agent runs need cancellation/timeouts/retry handling.
- Do not fabricate user's qualifications in generated application material.

---

## 13. Known Open Decisions

These should be resolved before the related implementation task:

1. Exact opportunity data sources.
2. Primary LLM provider(s).
3. Agent orchestration library.
4. Push notification provider.
5. Analytics/crash provider.
6. Final visual palette after Figma review.
7. Monetization strategy.

Do not invent final choices when implementing these areas unless the task explicitly authorizes a default choice.

---

## 14. Change Log

### 2026-09-25

- Initial project context created.
- PRD, architecture, rules, design and task framework established.
- Agentic workflow defined as the core differentiator.

### 2026-09-29

- Phase 7 (Agent Core) completed.
- AD-007: Task and tool-call persistence wired into orchestrator via `agent_task_service` and `tool_call_service`. Persistence calls are fire-and-forget with error logging; failures do not block agent execution.
- AD-008: Cancellation is cooperative. The orchestrator polls `get_agent_run` between task attempts. If the database status is `cancelled`, the run stops immediately. No background cancellation thread.
- AD-009: Global timeout uses `run_timeout_minutes` from `AgentGuardrails`. Checked at the start of each iteration in the dependency loop, not per-task.
- AD-010: Retry is bounded by `max_retries_per_task`. Policy errors (`ToolPermissionDenied`), authorization errors, and `ApprovalRequired` do not retry — they break immediately.
- AD-011: Approval boundary is enforced by `check_action_policy` in `policies.py`. `ApprovalRequired` causes the orchestrator to transition to `WAITING_FOR_APPROVAL` without retrying. Resume requires a separate API call. `CRITICAL` actions are blocked entirely for MVP.
- AD-012: DocumentAgent uses the provider-agnostic LLM abstraction with Pydantic `DocumentGenerationResult` for structured output. Fact safety is enforced via system prompt constraints. Generated documents are always marked `is_draft=True`.
- AD-013: State transitions are validated in `state.py`. Terminal states (`COMPLETED`, `FAILED`, `CANCELLED`) have no outgoing transitions. Invalid transitions raise `InvalidStateTransition`.
- LLM provider decision resolved: Gemini via `google-genai` SDK as primary, with `MockLLMProvider` for offline testing. Search provider: Tavily.
