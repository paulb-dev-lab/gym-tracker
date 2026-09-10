-- Run this after the prior migrations for an existing Lift Log database.
-- Reorders a workout's exercises in one transaction while preserving the
-- session exercise rows (and therefore all of their sets and notes).
alter table public.session_exercises alter column position type integer;

create or replace function public.reorder_session_exercises(workout_id uuid, exercise_ids uuid[]) returns void language plpgsql security invoker set search_path = public as $$
declare
  item_count integer;
  max_position integer;
begin
  perform pg_advisory_xact_lock(hashtextextended(workout_id::text, 0));

  if not exists (select 1 from public.workout_sessions where id = workout_id and owner_id = auth.uid()) then
    raise exception 'Workout not found or not owned by this account';
  end if;

  select count(*), coalesce(max(position), 0)
  into item_count, max_position
  from public.session_exercises
  where session_id = workout_id;

  if coalesce(cardinality(exercise_ids), -1) <> item_count
    or (select count(distinct exercise_id) from unnest(exercise_ids) as requested(exercise_id)) <> item_count
    or exists (
      select 1
      from unnest(exercise_ids) as requested(exercise_id)
      left join public.session_exercises se on se.id = requested.exercise_id and se.session_id = workout_id
      where se.id is null
    ) then
    raise exception 'Exercise order must contain every workout exercise exactly once';
  end if;

  -- Move every row above the currently occupied range first, then normalize
  -- to 1..n. Both updates are part of this function's single transaction.
  with staged as (
    select id, max_position + row_number() over (order by position, id) as temporary_position
    from public.session_exercises
    where session_id = workout_id
  )
  update public.session_exercises se
  set position = staged.temporary_position
  from staged
  where se.id = staged.id;

  with desired as (
    select exercise_id, ordinality::integer as position
    from unnest(exercise_ids) with ordinality as requested(exercise_id, ordinality)
  )
  update public.session_exercises se
  set position = desired.position
  from desired
  where se.id = desired.exercise_id and se.session_id = workout_id;
end;
$$;

grant execute on function public.reorder_session_exercises(uuid, uuid[]) to authenticated;
