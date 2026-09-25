# ApplyX — Engineering & Agent Rules

**Version:** 1.0.0
**Purpose:** Non-negotiable rules for developers and coding agents working on ApplyX.

---

## 1. General Rules

1. Read `PRD.md`, `architecture.md`, `design.md`, `memory.md`, and the current `task.md` before modifying the project.
2. Do not invent product requirements that conflict with the PRD.
3. Prefer small, reversible changes.
4. Do not rewrite stable code unless the task requires it.
5. Keep commits focused.
6. Do not mix unrelated refactors into feature work.
7. Explain breaking changes in the task or commit message.

---

## 2. Flutter Rules

- Use feature-first structure.
- Keep widgets small and composable.
- Avoid business logic inside deeply nested UI widgets.
- Use a single state-management pattern consistently.
- Centralize theme tokens.
- Avoid hard-coded colors and spacing when a design token exists.
- Support loading, empty, success and error states.
- Handle mounted/context lifecycle correctly around async operations.
- Do not block the UI thread with heavy work.

---

## 3. UI/UX Rules

- Follow `design.md` as the source of truth for UI decisions.
- Do not invent random gradients, shadows or colors without documenting the reason.
- Keep primary CTA visually dominant.
- Maintain consistent corner radius and spacing tokens.
- Use clear hierarchy.
- Avoid overusing cards.
- Never hide critical action status behind decorative animation.
- Design for mobile first.
- All important screens need empty/error/loading states.
- All user-facing text should be reviewed for clarity.

---

## 4. Figma Rules

- Figma is the visual source of truth before Flutter implementation.
- Use components for repeated UI.
- Use variables/tokens for colors, spacing, typography and radii where supported.
- Name layers semantically.
- Keep screens inside logical page/frame groups.
- Do not export screenshots and manually rebuild unknown dimensions unless necessary.
- Every implemented screen should map to a Figma frame.
- When a design changes, update the implementation intentionally; do not silently diverge.

---

## 5. Backend Rules

- Never place service-role secrets in Flutter.
- Validate all client input server-side.
- Authorize every resource access.
- Use typed request/response schemas.
- Return predictable error structures.
- Use timeouts for external calls.
- Use retries only for idempotent/safe operations.
- Avoid hidden background side effects.

---

## 6. Database Rules

- Every user-owned table must have an explicit ownership model.
- Enable and test Row Level Security where applicable.
- Use foreign keys where appropriate.
- Add indexes for frequent filters/lookups.
- Never store a password directly in application tables.
- Keep timestamps in a consistent timezone strategy.
- Use migrations; do not manually mutate production schema without a tracked migration.

---

## 7. Agentic AI Rules

### 7.1 No giant prompt architecture

Never implement the full product as one giant prompt.

Use:

```text
Planner → Tasks → Tools → Verification → Approval → Action
```

### 7.2 LLM output is untrusted

Never execute raw LLM text as code, SQL, shell commands or arbitrary tool instructions.

Require:

```text
structured output
→ schema validation
→ policy validation
→ tool permission check
→ execution
```

### 7.3 Evidence

Important opportunity facts must preserve source information where available.

### 7.4 Uncertainty

Use:

- confirmed;
- likely;
- uncertain;
- insufficient evidence.

Do not represent estimates as guarantees.

### 7.5 Human approval

Actions with external side effects require a stored approval record.

### 7.6 Idempotency

Repeated execution must not accidentally duplicate an external action.

### 7.7 Agent limits

Every run should have:

- maximum task count;
- maximum execution time;
- maximum retry count;
- sensible model/tool usage limits.

### 7.8 Audit trail

Record which agent/tool performed important operations.

---

## 8. Security Rules

- Never commit secrets.
- Never commit `.env` files containing real secrets.
- Use `.env.example` with placeholders.
- Sanitize logs.
- Validate uploaded file types and size.
- Use secure storage for sensitive local credentials.
- Avoid exposing internal stack traces to users.

---

## 9. Privacy Rules

- Collect only required data.
- Explain why sensitive user documents are processed.
- Provide account deletion.
- Provide privacy policy.
- Avoid unnecessary analytics containing personal content.
- Do not send user documents to external AI providers unless that processing is intended, disclosed and technically required.

---

## 10. Testing Rules

Every meaningful feature should have appropriate tests.

Minimum for MVP:

- unit tests for business-critical logic;
- widget tests for important UI behavior;
- integration tests for auth/core flows;
- manual testing on real Android/iOS devices before release.

Agent workflows must test:

- success;
- tool failure;
- malformed model output;
- timeout;
- retry;
- approval rejection;
- cancellation;
- duplicate execution.

---

## 11. Git Rules

Branch pattern:

```text
main
 develop
 feature/<short-name>
 fix/<short-name>
 chore/<short-name>
```

Commit style examples:

```text
feat: add goal creation flow
fix: handle agent timeout state
refactor: split opportunity card
chore: update android build config
```

Never push secrets.

---

## 12. Definition-of-Done Rules

A feature is not done until:

- implementation works;
- error/loading/empty states exist where relevant;
- tests are updated;
- design matches Figma or deviation is documented;
- security/privacy impact is considered;
- task is marked complete in `task.md`;
- no obvious analyzer/linter errors remain.

---

## 13. Coding Agent Rules

When an AI coding agent is used:

1. Read all project context files first.
2. Inspect existing implementation before creating new files.
3. Reuse existing services/components.
4. Ask only when a missing decision blocks safe implementation; otherwise follow the documented defaults.
5. Do not silently change architecture.
6. Do not remove working features without an explicit task.
7. After implementation, run relevant tests/analyzer/build checks.
8. Update `task.md` with completed work and blockers.
9. Update `memory.md` only for stable project facts or durable decisions.

---

## 14. Release Rules

Before production:

```text
flutter analyze
flutter test
release build
manual smoke test
privacy review
permissions review
store metadata review
review account/access instructions
```

Production release must never use development API/database credentials.

---

## 15. Priority Rule

When two goals conflict, prefer:

```text
Security
 > Data integrity
 > Correctness
 > User control
 > Reliability
 > Performance
 > Visual polish
 > Convenience
```

---
