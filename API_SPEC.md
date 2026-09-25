# ApplyX API Specification

**Version:** 1.0.0
**Base path:** `/v1`
**Transport:** HTTPS / JSON
**Authentication:** Supabase user JWT forwarded as `Authorization: Bearer <token>`

## 1. API Principles

- Every authenticated endpoint must verify the Supabase user identity.
- Every user-owned resource must enforce ownership server-side.
- Client-provided `user_id` must never be trusted for authorization.
- All request/response payloads should use typed Pydantic models.
- Errors use a stable response envelope.
- Long-running agent execution must be represented by an `agent_run` resource instead of holding an HTTP request open indefinitely.
- Consequential actions require an approval record and a server-side approval check.

## 2. Error Envelope

```json
{
  "error": {
    "code": "AGENT_RUN_NOT_FOUND",
    "message": "The requested agent run does not exist.",
    "request_id": "req_123"
  }
}
```

Suggested codes:

```text
AUTH_REQUIRED
FORBIDDEN
VALIDATION_ERROR
NOT_FOUND
CONFLICT
RATE_LIMITED
UPSTREAM_TIMEOUT
AGENT_RUN_FAILED
APPROVAL_REQUIRED
APPROVAL_INVALID
INTERNAL_ERROR
```

## 3. Health

### GET `/health`

No authentication required.

Response:

```json
{
  "status": "ok",
  "version": "1.0.0"
}
```

## 4. Profile

### GET `/profiles/me`

Returns the current user's profile.

### PUT `/profiles/me`

Request:

```json
{
  "full_name": "Example User",
  "headline": "CSE Student | Flutter | Python | ML",
  "bio": "...",
  "education_level": "undergraduate",
  "department": "Computer Science and Engineering",
  "location": "Bangladesh",
  "work_preference": "remote",
  "skills": ["Flutter", "Dart", "Python", "Machine Learning"],
  "links": {
    "github": "https://github.com/example",
    "linkedin": "https://linkedin.com/in/example"
  }
}
```

## 5. Goals

### POST `/goals`

Request:

```json
{
  "title": "Find Flutter internships",
  "raw_goal": "Find paid remote Flutter internships suitable for a final-year CSE student.",
  "structured_constraints": {
    "opportunity_types": ["internship"],
    "skills": ["Flutter"],
    "paid": true,
    "remote": true
  }
}
```

Response includes `id`, `status`, timestamps and normalized constraints.

### GET `/goals`

Returns the current user's goals.

### GET `/goals/{goal_id}`

Returns a single owned goal.

### PATCH `/goals/{goal_id}`

Updates editable goal fields.

## 6. Agent Runs

### POST `/agent-runs`

Creates and starts an agent run asynchronously.

Request:

```json
{
  "goal_id": "uuid",
  "mode": "research_and_match"
}
```

Response:

```json
{
  "id": "uuid",
  "goal_id": "uuid",
  "status": "queued",
  "created_at": "2026-09-25T04:00:00Z"
}
```

### GET `/agent-runs/{run_id}`

Returns current state:

```json
{
  "id": "uuid",
  "status": "running",
  "current_step": "profile_fit",
  "progress": 62,
  "final_summary": null,
  "error": null
}
```

### GET `/agent-runs/{run_id}/events`

Returns ordered, user-safe agent events for the UI.

Example:

```json
{
  "events": [
    {
      "type": "task_started",
      "task": "Research opportunities",
      "timestamp": "2026-09-25T04:01:02Z"
    },
    {
      "type": "source_found",
      "source": "Example source",
      "timestamp": "2026-09-25T04:01:09Z"
    }
  ]
}
```

### POST `/agent-runs/{run_id}/cancel`

Requests cancellation of a running run.

## 7. Opportunities

### GET `/opportunities`

Query parameters may include:

```text
q
opportunity_type
location
remote
status
limit
cursor
```

### GET `/opportunities/{opportunity_id}`

Returns normalized opportunity details, source metadata and freshness metadata.

### POST `/opportunities/{opportunity_id}/save`

Saves the opportunity for the current user.

## 8. Matches

### GET `/opportunities/{opportunity_id}/match`

Returns the current user's match analysis when it exists.

Response:

```json
{
  "eligibility_status": "likely_eligible",
  "fit_reasons": [
    "Flutter is listed as a relevant skill.",
    "Remote work is allowed."
  ],
  "missing_requirements": [],
  "evidence": [
    {
      "claim": "Remote work is allowed",
      "source_url": "https://example.com/opportunity"
    }
  ]
}
```

## 9. Applications

### GET `/applications`

Returns the current user's applications.

### POST `/applications`

Request:

```json
{
  "opportunity_id": "uuid",
  "status": "draft"
}
```

### PATCH `/applications/{application_id}`

Updates the user's own application status/notes/next action.

## 10. Documents

### POST `/documents/draft`

Starts or completes a document-generation task.

Request:

```json
{
  "application_id": "uuid",
  "kind": "cover_letter",
  "instruction": "Create a concise tailored cover letter using only profile evidence."
}
```

Response may contain a draft document or an asynchronous job reference.

### GET `/documents/{document_id}`

Returns an owned document.

### PATCH `/documents/{document_id}`

Allows user edits and version creation.

## 11. Approvals

### GET `/approvals`

Returns pending approvals for the current user.

### POST `/approvals/{approval_id}/approve`

Server verifies:

1. approval belongs to current user;
2. approval is still pending;
3. target/action has not already executed;
4. required policy checks pass.

Only then may the action be executed.

### POST `/approvals/{approval_id}/reject`

Marks the approval rejected and prevents execution.

## 12. Notifications

### GET `/notifications`

Returns user notifications.

### POST `/notifications/{id}/read`

Marks a notification read.

## 13. Pagination

Prefer cursor pagination for opportunity feeds and event streams.

Request:

```text
?limit=20&cursor=<opaque_cursor>
```

Response:

```json
{
  "items": [],
  "next_cursor": "opaque_cursor_or_null"
}
```

## 14. Idempotency

For endpoints that can trigger work or external side effects, support an `Idempotency-Key` header.

Example:

```text
Idempotency-Key: 2c4d8f3a-...
```

The backend should return the original result when the same key is replayed for the same authenticated user.

## 15. Rate Limits

At minimum apply limits to:

- agent run creation;
- document generation;
- external search/tool calls;
- authentication-sensitive endpoints.

The exact quotas are an open implementation decision and should be configured server-side, not hard-coded into UI.
