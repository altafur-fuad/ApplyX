-- ApplyX Supabase/PostgreSQL baseline schema
-- Version: 1.0.0
-- Intended for a fresh development Supabase project.
-- Review with the production migration strategy before deployment.

create extension if not exists pgcrypto;

-- =========================
-- Utility functions
-- =========================

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

-- =========================
-- Profiles
-- =========================

create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  full_name text,
  headline text,
  bio text,
  education_level text,
  department text,
  location text,
  work_preference text,
  skills_json jsonb not null default '[]'::jsonb,
  links_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

-- =========================
-- Goals
-- =========================

create table if not exists public.goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  raw_goal text not null,
  structured_constraints_json jsonb not null default '{}'::jsonb,
  status text not null default 'active' check (status in ('active', 'paused', 'completed', 'archived')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

-- =========================
-- Agent runs / tasks / events / tool calls
-- =========================

create table if not exists public.agent_runs (
  id uuid primary key default gen_random_uuid(),
  goal_id uuid not null references public.goals(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'queued' check (status in ('queued', 'planning', 'running', 'waiting_for_input', 'waiting_for_approval', 'completed', 'failed', 'cancelled')),
  current_step text,
  plan_json jsonb not null default '{}'::jsonb,
  final_summary text,
  error_message text,
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.agent_tasks (
  id uuid primary key default gen_random_uuid(),
  agent_run_id uuid not null references public.agent_runs(id) on delete cascade,
  parent_task_id uuid references public.agent_tasks(id) on delete set null,
  agent_type text not null,
  name text not null,
  status text not null default 'pending' check (status in ('pending', 'running', 'waiting_for_input', 'waiting_for_approval', 'completed', 'failed', 'cancelled')),
  input_json jsonb not null default '{}'::jsonb,
  output_json jsonb,
  error_message text,
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.agent_events (
  id uuid primary key default gen_random_uuid(),
  agent_run_id uuid not null references public.agent_runs(id) on delete cascade,
  task_id uuid references public.agent_tasks(id) on delete set null,
  event_type text not null,
  message text,
  payload_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.tool_calls (
  id uuid primary key default gen_random_uuid(),
  agent_run_id uuid not null references public.agent_runs(id) on delete cascade,
  task_id uuid references public.agent_tasks(id) on delete set null,
  tool_name text not null,
  input_json jsonb not null default '{}'::jsonb,
  output_json jsonb,
  status text not null default 'started' check (status in ('started', 'completed', 'failed', 'timed_out')),
  risk_level text not null check (risk_level in ('low', 'medium', 'high', 'critical')),
  created_at timestamptz not null default timezone('utc', now())
);

-- =========================
-- Opportunities
-- =========================

create table if not exists public.opportunities (
  id uuid primary key default gen_random_uuid(),
  source_name text not null,
  source_url text not null,
  external_id text,
  title text not null,
  organization text not null,
  type text not null,
  location text,
  remote_status text,
  deadline timestamptz,
  description text,
  requirements_json jsonb not null default '[]'::jsonb,
  compensation_text text,
  fetched_at timestamptz not null default timezone('utc', now()),
  content_hash text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (source_name, external_id)
);

create unique index if not exists opportunities_content_hash_unique
on public.opportunities(content_hash)
where content_hash is not null;

-- =========================
-- Matches / saved opportunities
-- =========================

create table if not exists public.opportunity_matches (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  opportunity_id uuid not null references public.opportunities(id) on delete cascade,
  eligibility_status text not null check (eligibility_status in ('likely_eligible', 'partially_eligible', 'likely_not_eligible', 'insufficient_evidence')),
  fit_reasons_json jsonb not null default '[]'::jsonb,
  missing_requirements_json jsonb not null default '[]'::jsonb,
  evidence_json jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (user_id, opportunity_id)
);

create table if not exists public.saved_opportunities (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  opportunity_id uuid not null references public.opportunities(id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  unique (user_id, opportunity_id)
);

-- =========================
-- Applications / documents / approvals
-- =========================

create table if not exists public.applications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  opportunity_id uuid not null references public.opportunities(id) on delete restrict,
  status text not null default 'draft' check (status in ('draft', 'ready', 'submitted', 'interview', 'rejected', 'withdrawn', 'accepted', 'archived')),
  notes text,
  submitted_at timestamptz,
  next_action_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.documents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  application_id uuid references public.applications(id) on delete cascade,
  kind text not null check (kind in ('resume', 'cover_letter', 'short_answer', 'portfolio_summary', 'other')),
  title text not null,
  content text not null,
  version integer not null default 1,
  is_draft boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.approvals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  agent_run_id uuid not null references public.agent_runs(id) on delete cascade,
  action_type text not null,
  target_json jsonb not null default '{}'::jsonb,
  preview_json jsonb not null default '{}'::jsonb,
  risk_level text not null check (risk_level in ('medium', 'high', 'critical')),
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected', 'expired', 'executed', 'failed')),
  approved_at timestamptz,
  rejected_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

-- =========================
-- Notifications / device tokens
-- =========================

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  type text not null,
  title text not null,
  body text not null,
  data_json jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  platform text not null check (platform in ('android', 'ios')),
  token text not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (user_id, token)
);

-- =========================
-- Updated-at triggers
-- =========================

do $$
begin
  if not exists (select 1 from pg_trigger where tgname = 'profiles_set_updated_at') then
    create trigger profiles_set_updated_at before update on public.profiles
    for each row execute function public.set_updated_at();
  end if;
  if not exists (select 1 from pg_trigger where tgname = 'goals_set_updated_at') then
    create trigger goals_set_updated_at before update on public.goals
    for each row execute function public.set_updated_at();
  end if;
  if not exists (select 1 from pg_trigger where tgname = 'agent_runs_set_updated_at') then
    create trigger agent_runs_set_updated_at before update on public.agent_runs
    for each row execute function public.set_updated_at();
  end if;
  if not exists (select 1 from pg_trigger where tgname = 'agent_tasks_set_updated_at') then
    create trigger agent_tasks_set_updated_at before update on public.agent_tasks
    for each row execute function public.set_updated_at();
  end if;
  if not exists (select 1 from pg_trigger where tgname = 'opportunities_set_updated_at') then
    create trigger opportunities_set_updated_at before update on public.opportunities
    for each row execute function public.set_updated_at();
  end if;
  if not exists (select 1 from pg_trigger where tgname = 'opportunity_matches_set_updated_at') then
    create trigger opportunity_matches_set_updated_at before update on public.opportunity_matches
    for each row execute function public.set_updated_at();
  end if;
  if not exists (select 1 from pg_trigger where tgname = 'applications_set_updated_at') then
    create trigger applications_set_updated_at before update on public.applications
    for each row execute function public.set_updated_at();
  end if;
  if not exists (select 1 from pg_trigger where tgname = 'documents_set_updated_at') then
    create trigger documents_set_updated_at before update on public.documents
    for each row execute function public.set_updated_at();
  end if;
  if not exists (select 1 from pg_trigger where tgname = 'approvals_set_updated_at') then
    create trigger approvals_set_updated_at before update on public.approvals
    for each row execute function public.set_updated_at();
  end if;
  if not exists (select 1 from pg_trigger where tgname = 'device_tokens_set_updated_at') then
    create trigger device_tokens_set_updated_at before update on public.device_tokens
    for each row execute function public.set_updated_at();
  end if;
end $$;

-- =========================
-- Indexes
-- =========================

create index if not exists goals_user_id_idx on public.goals(user_id);
create index if not exists agent_runs_user_id_idx on public.agent_runs(user_id);
create index if not exists agent_runs_goal_id_idx on public.agent_runs(goal_id);
create index if not exists agent_tasks_run_id_idx on public.agent_tasks(agent_run_id);
create index if not exists agent_events_run_id_created_at_idx on public.agent_events(agent_run_id, created_at);
create index if not exists tool_calls_run_id_idx on public.tool_calls(agent_run_id);
create index if not exists opportunities_deadline_idx on public.opportunities(deadline);
create index if not exists opportunities_type_idx on public.opportunities(type);
create index if not exists opportunity_matches_user_idx on public.opportunity_matches(user_id);
create index if not exists applications_user_status_idx on public.applications(user_id, status);
create index if not exists applications_next_action_idx on public.applications(next_action_at);
create index if not exists documents_user_id_idx on public.documents(user_id);
create index if not exists approvals_user_status_idx on public.approvals(user_id, status);
create index if not exists notifications_user_created_at_idx on public.notifications(user_id, created_at desc);

-- =========================
-- Row Level Security
-- =========================

alter table public.profiles enable row level security;
alter table public.goals enable row level security;
alter table public.agent_runs enable row level security;
alter table public.agent_tasks enable row level security;
alter table public.agent_events enable row level security;
alter table public.tool_calls enable row level security;
alter table public.opportunity_matches enable row level security;
alter table public.saved_opportunities enable row level security;
alter table public.applications enable row level security;
alter table public.documents enable row level security;
alter table public.approvals enable row level security;
alter table public.notifications enable row level security;
alter table public.device_tokens enable row level security;

-- Opportunities are intentionally not user-owned.
-- Do not enable client writes; privileged backend/service role should ingest/update them.

-- Profiles
 drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own on public.profiles for select using (auth.uid() = user_id);
 drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own on public.profiles for insert with check (auth.uid() = user_id);
 drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
 drop policy if exists profiles_delete_own on public.profiles;
create policy profiles_delete_own on public.profiles for delete using (auth.uid() = user_id);

-- Goals
 drop policy if exists goals_all_own on public.goals;
create policy goals_all_own on public.goals for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Agent runs
 drop policy if exists agent_runs_select_own on public.agent_runs;
create policy agent_runs_select_own on public.agent_runs for select using (auth.uid() = user_id);
 drop policy if exists agent_runs_insert_own on public.agent_runs;
create policy agent_runs_insert_own on public.agent_runs for insert with check (auth.uid() = user_id);
 drop policy if exists agent_runs_update_own on public.agent_runs;
create policy agent_runs_update_own on public.agent_runs for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
 drop policy if exists agent_runs_delete_own on public.agent_runs;
create policy agent_runs_delete_own on public.agent_runs for delete using (auth.uid() = user_id);

-- Agent tasks / events / tool calls inherit ownership through agent_runs.
create or replace function public.is_agent_run_owner(run_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.agent_runs ar
    where ar.id = run_id and ar.user_id = auth.uid()
  );
$$;

 drop policy if exists agent_tasks_select_own_run on public.agent_tasks;
create policy agent_tasks_select_own_run on public.agent_tasks for select using (public.is_agent_run_owner(agent_run_id));

 drop policy if exists agent_events_select_own_run on public.agent_events;
create policy agent_events_select_own_run on public.agent_events for select using (public.is_agent_run_owner(agent_run_id));

 drop policy if exists tool_calls_select_own_run on public.tool_calls;
create policy tool_calls_select_own_run on public.tool_calls for select using (public.is_agent_run_owner(agent_run_id));

-- Opportunity matches / saved opportunities
 drop policy if exists opportunity_matches_all_own on public.opportunity_matches;
create policy opportunity_matches_all_own on public.opportunity_matches for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

 drop policy if exists saved_opportunities_all_own on public.saved_opportunities;
create policy saved_opportunities_all_own on public.saved_opportunities for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Applications / documents / approvals / notifications / device tokens
 drop policy if exists applications_all_own on public.applications;
create policy applications_all_own on public.applications for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

 drop policy if exists documents_all_own on public.documents;
create policy documents_all_own on public.documents for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

 drop policy if exists approvals_all_own on public.approvals;
create policy approvals_all_own on public.approvals for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

 drop policy if exists notifications_all_own on public.notifications;
create policy notifications_all_own on public.notifications for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

 drop policy if exists device_tokens_all_own on public.device_tokens;
create policy device_tokens_all_own on public.device_tokens for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Opportunities are readable by authenticated users through the client only when needed.
-- Ingestion/update remains privileged backend/service-role work.
drop policy if exists opportunities_read_authenticated on public.opportunities;
create policy opportunities_read_authenticated on public.opportunities
  for select using (auth.role() = 'authenticated');
