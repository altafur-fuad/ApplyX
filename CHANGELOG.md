# ApplyX Changelog

## [Unreleased]

### Added

- Initial product specification set.
- Agentic architecture and tool-risk model.
- Supabase/PostgreSQL baseline schema with RLS.
- API contract.
- Agent execution contract.
- Canonical repository structure.
- Deployment guide.
- Environment variable template.

### Added — Phase 7: Agent Core

- Agent task persistence: every planned task is created in the database with status tracking through `pending → running → completed/failed`.
- Tool call audit logging: every tool invocation is persisted with input, output, status, and linkage to `agent_run_id`/`task_id`.
- Cancellation: runs check for user-initiated cancellation from the database between task attempts and stop execution.
- Global timeout: configurable `run_timeout_minutes` enforced in the execution loop; exceeded runs transition to `FAILED`.
- Bounded task retry: transient failures retry up to `max_retries_per_task`; policy/authorization errors and `ApprovalRequired` do not retry.
- Human approval boundary: `ApprovalRequired` exception pauses the run to `WAITING_FOR_APPROVAL`; resume requires server-side revalidation.
- `CRITICAL` risk actions blocked entirely for MVP; `HIGH` risk actions require explicit approval.
- LLM-backed Document Agent: generates structured drafts using Pydantic `DocumentGenerationResult` schema via the provider-agnostic LLM abstraction.
- Document fact safety: system prompt prohibits fabrication; missing information surfaces `uncertainty_warnings` instead.
- Document persistence: `save_generated_document` saves versioned drafts bound to `user_id` and `application_id`.
- `DocumentGenerationResult` mock in `MockLLMProvider` for offline testing.
- Comprehensive offline test coverage: approval policy enforcement, cancellation detection, global timeout, retry behavior, task/tool-call persistence, document generation, and malformed LLM output rejection.

### Notes

This project is currently a development specification and should not be treated as production-ready until the security, privacy, testing and deployment checklists in `task.md` are complete.

## Release Format

Use entries grouped by:

- Added
- Changed
- Fixed
- Security
- Breaking

Example:

```text
## [1.1.0] - YYYY-MM-DD
### Added
- New agent approval preview.
### Fixed
- Duplicate agent action after retry.
```
