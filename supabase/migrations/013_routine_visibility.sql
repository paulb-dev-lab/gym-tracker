-- Add opt-in routine sharing. Existing and newly created routines are private by default.
alter table public.routines
  add column if not exists is_public boolean not null default false;

-- Archiving always revokes public visibility, including for updates outside the app.
create or replace function public.make_archived_routine_private()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.archived_at is not null then
    new.is_public = false;
  end if;
  return new;
end;
$$;

drop trigger if exists routines_archive_private on public.routines;
create trigger routines_archive_private
  before insert or update of archived_at, is_public on public.routines
  for each row execute procedure public.make_archived_routine_private();

drop policy if exists "routines shared read" on public.routines;
drop policy if exists "routines active shared read" on public.routines;
drop policy if exists "routines public or owner read" on public.routines;
create policy "routines public or owner read" on public.routines
  for select to authenticated
  using (owner_id = auth.uid() or (is_public and archived_at is null));

drop policy if exists "routine items shared read" on public.routine_items;
drop policy if exists "routine items readable with routine" on public.routine_items;
create policy "routine items readable with routine" on public.routine_items
  for select to authenticated
  using (exists (
    select 1 from public.routines r
    where r.id = routine_id
      and (r.owner_id = auth.uid() or (r.is_public and r.archived_at is null))
  ));
