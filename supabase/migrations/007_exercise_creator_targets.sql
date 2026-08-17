-- Run after 006_muscle_catalog.sql.
-- Keep the muscle catalogue admin-managed, while allowing the person who added
-- an exercise to maintain that exercise's primary and secondary targets.
drop policy if exists "admins manage exercise targets" on public.exercise_muscles;

create policy "exercise creators or admins manage exercise targets" on public.exercise_muscles
  for all to authenticated
  using (
    public.is_admin() or exists (
      select 1 from public.exercises e
      where e.id = exercise_id and e.created_by = auth.uid()
    )
  )
  with check (
    public.is_admin() or exists (
      select 1 from public.exercises e
      where e.id = exercise_id and e.created_by = auth.uid()
    )
  );
