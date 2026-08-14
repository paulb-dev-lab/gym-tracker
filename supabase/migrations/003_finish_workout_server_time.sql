-- Run this after the prior migrations for an existing Lift Log database.
-- It uses Supabase's server clock to prevent device-clock differences from
-- violating the finished_at >= started_at database rule.
create or replace function public.finish_workout(workout_id uuid) returns public.workout_sessions language plpgsql security invoker set search_path = public as $$
declare result public.workout_sessions;
begin
  update public.workout_sessions
  set finished_at = now()
  where id = workout_id and owner_id = auth.uid()
  returning * into result;
  if result.id is null then raise exception 'Workout not found or not owned by this account'; end if;
  return result;
end;
$$;
grant execute on function public.finish_workout(uuid) to authenticated;
