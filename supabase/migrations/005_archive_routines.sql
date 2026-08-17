-- Run after the prior migrations for an existing Lift Log project.
alter table public.routines add column if not exists archived_at timestamptz;

drop policy if exists "routines shared read" on public.routines;
drop policy if exists "routines active shared read" on public.routines;
create policy "routines active shared read" on public.routines
  for select to authenticated
  using (archived_at is null or owner_id = auth.uid());

drop policy if exists "routine items shared read" on public.routine_items;
drop policy if exists "routine items readable with routine" on public.routine_items;
create policy "routine items readable with routine" on public.routine_items
  for select to authenticated
  using (exists (
    select 1 from public.routines r
    where r.id = routine_id and (r.archived_at is null or r.owner_id = auth.uid())
  ));
