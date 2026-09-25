# ApplyX — Supabase Foundation

This folder contains the production-ready Supabase infrastructure for the ApplyX project.

## 1. Setup Instructions

To apply these migrations to your local or remote Supabase instance:

### Local Development
1. Install the Supabase CLI (`npm install -g supabase` or via Homebrew).
2. Run `supabase start` in the root of the project to start a local database.
3. The migrations in `supabase/migrations/` will run automatically. 
4. If you add new migrations later, run `supabase db push` or `supabase db reset` to apply them.

### Remote / Production
1. Link your project: `supabase link --project-ref <your-project-ref>`
2. Push the schema: `supabase db push`

---

## 2. Migrations Structure

The monolithic `database.sql` has been modularized for proper lifecycle management:

- `20240101000000_initial_schema.sql` — Base tables, columns, indexes, and constraints.
- `20240101000001_functions_triggers.sql` — Helper functions, `updated_at` triggers, and the user profile auto-creation trigger.
- `20240101000002_rls_policies.sql` — Row Level Security (RLS) enforcement on all user data.
- `20240101000003_storage.sql` — Storage bucket creation for `documents` and bucket RLS.

---

## 3. Database Architecture

- **User Profiles**: An auto-generated `profiles` row is created whenever a user signs up, listening to `auth.users` via the `handle_new_user` trigger. 
- **Agent Execution**: Separated into `goals`, `agent_runs`, `agent_tasks`, `agent_events`, and `tool_calls`. Ownership cascades down from the goal and agent run.
- **Opportunities**: A public, read-only cache of jobs/grants fetched by the backend. Normal users can only SELECT these.
- **Storage**: A single, private `documents` bucket handles resumes and cover letters. Storage paths are strictly checked by RLS to match the user's `auth.uid()`.

---

## 4. Row Level Security (RLS)

RLS is strictly enforced on all tables. 
- All user-specific tables (`profiles`, `goals`, `applications`, etc.) restrict `SELECT`, `INSERT`, `UPDATE`, and `DELETE` solely to `auth.uid() = user_id`.
- Tables dependent on parent structures (`agent_tasks`, `agent_events`) use an `is_agent_run_owner` function to resolve ownership securely.
- Storage RLS ensures that a user can only upload or download files residing in their specific subfolder `bucket/uid/`.

---

## 5. Security Checklist & Considerations

- **DO NOT** commit the Supabase `service_role` key anywhere in this repository.
- **DO NOT** store real passwords or tokens in code.
- **DO NOT** disable RLS for convenience.
- Use `.env.example` to provide placeholders. Create a local `.env` with actual keys and never commit it.
- **FastAPI / Python**: The backend will use the `service_role` key for administrative updates to `opportunities` and orchestration events.
- **Flutter**: The mobile client will only use the public `anon` key.

---

## 6. Auth Configuration (Dashboard Steps)

While the database schema handles post-signup profile generation, you must configure the following in the Supabase Dashboard manually:

1. **Email Auth**: Go to `Authentication > Providers` and ensure **Email** is enabled. Disable "Confirm email" for testing, but keep it on for production.
2. **Site URL**: Go to `Authentication > URL Configuration` and configure your Site URL (e.g., `http://localhost:3000` or a deep link scheme for the mobile app).
3. **SMTP**: Go to `Project Settings > Auth > SMTP` to set up real email delivery (e.g., Resend or SendGrid) for production.
