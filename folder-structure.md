# ApplyX — Canonical Folder Structure

**Version:** 1.0.0

This structure is the reference layout. Small deviations are allowed only when they improve maintainability and are documented.

```text
applyx/
│
├── README.md
├── PRD.md
├── architecture.md
├── design.md
├── rules.md
├── memory.md
├── task.md
├── AGENT_SPEC.md
├── API_SPEC.md
├── DEPLOYMENT.md
├── database.sql
├── folder-structure.md
├── CHANGELOG.md
├── .env.example
├── .gitignore
│
├── app/                         # Flutter application
│   ├── android/
│   ├── ios/
│   ├── web/                    # optional future target
│   ├── lib/
│   │   ├── app/
│   │   │   ├── app.dart
│   │   │   ├── router.dart
│   │   │   └── bootstrap.dart
│   │   │
│   │   ├── core/
│   │   │   ├── constants/
│   │   │   ├── errors/
│   │   │   ├── network/
│   │   │   ├── theme/
│   │   │   ├── widgets/
│   │   │   └── utils/
│   │   │
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   │   ├── data/
│   │   │   │   ├── domain/
│   │   │   │   └── presentation/
│   │   │   ├── onboarding/
│   │   │   ├── home/
│   │   │   ├── profile/
│   │   │   ├── goals/
│   │   │   ├── agent_runs/
│   │   │   ├── opportunities/
│   │   │   ├── applications/
│   │   │   ├── documents/
│   │   │   └── settings/
│   │   │
│   │   └── services/
│   │       ├── auth_service.dart
│   │       ├── api_service.dart
│   │       ├── supabase_service.dart
│   │       └── notification_service.dart
│   │
│   ├── test/
│   └── integration_test/
│
├── backend/
│   ├── app/
│   │   ├── main.py
│   │   ├── api/
│   │   │   ├── auth.py
│   │   │   ├── profiles.py
│   │   │   ├── goals.py
│   │   │   ├── agents.py
│   │   │   ├── opportunities.py
│   │   │   ├── applications.py
│   │   │   ├── documents.py
│   │   │   ├── approvals.py
│   │   │   └── notifications.py
│   │   │
│   │   ├── agents/
│   │   │   ├── state.py
│   │   │   ├── planner.py
│   │   │   ├── research.py
│   │   │   ├── eligibility.py
│   │   │   ├── profile_fit.py
│   │   │   ├── document.py
│   │   │   ├── verification.py
│   │   │   └── action.py
│   │   │
│   │   ├── tools/
│   │   │   ├── registry.py
│   │   │   ├── search.py
│   │   │   ├── source_parser.py
│   │   │   ├── matching.py
│   │   │   └── action_tools.py
│   │   │
│   │   ├── services/
│   │   │   ├── llm_service.py
│   │   │   ├── opportunity_service.py
│   │   │   ├── document_service.py
│   │   │   ├── approval_service.py
│   │   │   └── notification_service.py
│   │   │
│   │   ├── models/
│   │   └── core/
│   │       ├── config.py
│   │       ├── security.py
│   │       ├── policies.py
│   │       ├── logging.py
│   │       └── errors.py
│   │
│   ├── tests/
│   │   ├── api/
│   │   ├── agents/
│   │   └── tools/
│   ├── requirements.txt
│   └── pyproject.toml
│
├── supabase/
│   ├── migrations/
│   └── seed/
│
├── scripts/
│   ├── verify_env.*
│   ├── seed_demo_data.*
│   └── release_checks.*
│
├── docs/
│   ├── screenshots/
│   ├── architecture/
│   └── decisions/
│
└── .github/
    └── workflows/
        ├── flutter_ci.yml
        └── backend_ci.yml
```

## Structure Rules

- `app/lib/features` owns user-facing feature code.
- `app/lib/services` contains cross-feature infrastructure services; feature-specific data access should remain in the relevant feature module.
- `backend/app/agents` contains reasoning/orchestration code; tools belong in `backend/app/tools`.
- `backend/app/core/policies.py` is the final policy gate for risky actions.
- `supabase/migrations` becomes the canonical production schema history even if `database.sql` is retained as the baseline snapshot.
- Never store production secrets in the repository.
