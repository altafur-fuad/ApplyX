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
-- Profile Creation Trigger
-- =========================

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (user_id, full_name, headline)
  values (new.id, new.raw_user_meta_data->>'full_name', 'Open to new opportunities');
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- =========================
-- RLS Helpers
-- =========================

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
