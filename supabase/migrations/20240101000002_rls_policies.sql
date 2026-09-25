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
alter table public.opportunities enable row level security;

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
