-- Lift Log initial schema. Run in the Supabase SQL editor or through the Supabase CLI.
create extension if not exists "pgcrypto";

create type public.app_role as enum ('member', 'admin');
create type public.set_kind as enum ('standard', 'failure', 'drop_set', 'back_off', 'amrap');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 40),
  role public.app_role not null default 'member',
  default_set_count smallint not null default 3 check (default_set_count between 1 and 20),
  created_at timestamptz not null default now()
);
create table public.exercises (
  id uuid primary key default gen_random_uuid(), name text not null unique check (char_length(name) between 2 and 100),
  primary_muscle text, equipment text, created_by uuid not null default auth.uid() references public.profiles(id),
  is_retired boolean not null default false, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.exercise_suggestions (
  id uuid primary key default gen_random_uuid(), exercise_id uuid not null references public.exercises(id) on delete cascade,
  author_id uuid not null default auth.uid() references public.profiles(id), suggestion text not null check (char_length(suggestion) between 3 and 1000),
  status text not null default 'pending' check (status in ('pending','accepted','dismissed')), admin_note text, created_at timestamptz not null default now()
);
create table public.routines (
  id uuid primary key default gen_random_uuid(), owner_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 100), description text,
  copied_from_routine_id uuid references public.routines(id) on delete set null,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.routine_items (
  id uuid primary key default gen_random_uuid(), routine_id uuid not null references public.routines(id) on delete cascade,
  exercise_id uuid not null references public.exercises(id), position smallint not null check (position > 0), default_setup_label text,
  unique(routine_id, position)
);
create table public.workout_sessions (
  id uuid primary key default gen_random_uuid(), owner_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  title text, notes text, started_at timestamptz not null default now(), finished_at timestamptz,
  check (finished_at is null or finished_at >= started_at)
);
create table public.session_exercises (
  id uuid primary key default gen_random_uuid(), session_id uuid not null references public.workout_sessions(id) on delete cascade,
  exercise_id uuid not null references public.exercises(id), position smallint not null check (position > 0), setup_label text, notes text,
  unique(session_id, position)
);
create table public.sets (
  id uuid primary key default gen_random_uuid(), session_exercise_id uuid not null references public.session_exercises(id) on delete cascade,
  set_number smallint not null check (set_number > 0), set_type public.set_kind not null default 'standard',
  reps smallint not null check (reps >= 0 and reps <= 1000), weight_kg numeric(7,2) not null check (weight_kg >= 0 and weight_kg <= 2000), note text,
  unique(session_exercise_id, set_number)
);
create table public.catalog_audit_log (
  id bigint generated always as identity primary key, actor_id uuid references public.profiles(id), exercise_id uuid references public.exercises(id), action text not null, details jsonb, created_at timestamptz not null default now()
);
create index exercises_name_idx on public.exercises(name); create index sessions_owner_started_idx on public.workout_sessions(owner_id, started_at desc);

create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path = public as $$
begin insert into public.profiles (id, display_name) values (new.id, coalesce(nullif(trim(new.raw_user_meta_data->>'display_name'), ''), split_part(new.email, '@', 1))); return new; end; $$;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();
create or replace function public.is_admin() returns boolean language sql stable security definer set search_path = public as $$ select coalesce((select role = 'admin' from public.profiles where id = auth.uid()), false); $$;
create or replace function public.touch_updated_at() returns trigger language plpgsql as $$ begin new.updated_at = now(); return new; end; $$;
create trigger exercises_touch before update on public.exercises for each row execute procedure public.touch_updated_at();
create trigger routines_touch before update on public.routines for each row execute procedure public.touch_updated_at();
create or replace function public.audit_exercise_change() returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'DELETE' then
    insert into public.catalog_audit_log(actor_id, exercise_id, action, details) values (auth.uid(), old.id, tg_op, jsonb_build_object('name', old.name));
    return old;
  end if;
  insert into public.catalog_audit_log(actor_id, exercise_id, action, details) values (auth.uid(), new.id, tg_op, jsonb_build_object('name', new.name));
  return new;
end;
$$;
create trigger exercises_audit after insert or update or delete on public.exercises for each row execute procedure public.audit_exercise_change();

alter table public.profiles enable row level security; alter table public.exercises enable row level security; alter table public.exercise_suggestions enable row level security; alter table public.routines enable row level security; alter table public.routine_items enable row level security; alter table public.workout_sessions enable row level security; alter table public.session_exercises enable row level security; alter table public.sets enable row level security; alter table public.catalog_audit_log enable row level security;
create policy "profiles visible to members" on public.profiles for select to authenticated using (true);
create policy "profile update own display name" on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid() and role = (select role from public.profiles where id = auth.uid()));
create policy "catalog readable" on public.exercises for select to authenticated using (true);
create policy "members add exercises" on public.exercises for insert to authenticated with check (created_by = auth.uid());
create policy "admin updates exercises" on public.exercises for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "admin deletes exercises" on public.exercises for delete to authenticated using (public.is_admin());
create policy "suggestions insert own" on public.exercise_suggestions for insert to authenticated with check (author_id = auth.uid());
create policy "suggestions view own or admin" on public.exercise_suggestions for select to authenticated using (author_id = auth.uid() or public.is_admin());
create policy "admin updates suggestions" on public.exercise_suggestions for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "routines shared read" on public.routines for select to authenticated using (true);
create policy "routines owner insert" on public.routines for insert to authenticated with check (owner_id = auth.uid());
create policy "routines owner update" on public.routines for update to authenticated using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "routines owner delete" on public.routines for delete to authenticated using (owner_id = auth.uid());
create policy "routine items shared read" on public.routine_items for select to authenticated using (true);
create policy "routine items owner write" on public.routine_items for all to authenticated using (exists (select 1 from public.routines r where r.id = routine_id and r.owner_id = auth.uid())) with check (exists (select 1 from public.routines r where r.id = routine_id and r.owner_id = auth.uid()));
create policy "sessions owner only" on public.workout_sessions for all to authenticated using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "session exercises owner only" on public.session_exercises for all to authenticated using (exists (select 1 from public.workout_sessions s where s.id = session_id and s.owner_id = auth.uid())) with check (exists (select 1 from public.workout_sessions s where s.id = session_id and s.owner_id = auth.uid()));
create policy "sets owner only" on public.sets for all to authenticated using (exists (select 1 from public.session_exercises se join public.workout_sessions s on s.id = se.session_id where se.id = session_exercise_id and s.owner_id = auth.uid())) with check (exists (select 1 from public.session_exercises se join public.workout_sessions s on s.id = se.session_id where se.id = session_exercise_id and s.owner_id = auth.uid()));
create policy "admins audit read" on public.catalog_audit_log for select to authenticated using (public.is_admin());

-- After you create your first account, run once with your auth user UUID:
-- update public.profiles set role = 'admin' where id = 'YOUR-USER-UUID';
