-- Run after 007_exercise_creator_targets.sql.
-- Targets can now reference either a specific muscle or an entire muscle group.
create table public.exercise_targets (
  id uuid primary key default gen_random_uuid(),
  exercise_id uuid not null references public.exercises(id) on delete cascade,
  muscle_id uuid references public.muscles(id) on delete restrict,
  muscle_group_id uuid references public.muscle_groups(id) on delete restrict,
  role public.muscle_target_role not null,
  check ((muscle_id is not null)::integer + (muscle_group_id is not null)::integer = 1)
);

insert into public.exercise_targets (exercise_id, muscle_id, role)
select exercise_id, muscle_id, role from public.exercise_muscles;

create unique index one_primary_target_per_exercise_v2 on public.exercise_targets (exercise_id) where role = 'primary';
create unique index unique_exercise_muscle_target on public.exercise_targets (exercise_id, muscle_id) where muscle_id is not null;
create unique index unique_exercise_group_target on public.exercise_targets (exercise_id, muscle_group_id) where muscle_group_id is not null;
create index exercise_targets_muscle_idx on public.exercise_targets (muscle_id) where muscle_id is not null;
create index exercise_targets_group_idx on public.exercise_targets (muscle_group_id) where muscle_group_id is not null;

alter table public.exercise_targets enable row level security;
create policy "exercise creators or admins manage targets" on public.exercise_targets
  for all to authenticated
  using (public.is_admin() or exists (select 1 from public.exercises e where e.id = exercise_id and e.created_by = auth.uid()))
  with check (public.is_admin() or exists (select 1 from public.exercises e where e.id = exercise_id and e.created_by = auth.uid()));
create policy "exercise targets readable" on public.exercise_targets for select to authenticated using (true);

drop table public.exercise_muscles;
