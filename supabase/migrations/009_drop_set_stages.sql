-- Run after the previous migrations. A parent set remains the initial/heaviest
-- stage of a dropset; these rows store each subsequent reduction.
create table public.drop_set_stages (
  id uuid primary key default gen_random_uuid(),
  set_id uuid not null references public.sets(id) on delete cascade,
  position smallint not null check (position > 0),
  reps smallint not null check (reps >= 0 and reps <= 1000),
  weight_kg numeric(7,2) not null check (weight_kg >= 0 and weight_kg <= 2000),
  unique (set_id, position)
);

create index drop_set_stages_set_idx on public.drop_set_stages(set_id, position);

alter table public.drop_set_stages enable row level security;
create policy "drop stages owner only" on public.drop_set_stages
  for all to authenticated
  using (exists (
    select 1 from public.sets st
    join public.session_exercises se on se.id = st.session_exercise_id
    join public.workout_sessions ws on ws.id = se.session_id
    where st.id = set_id and ws.owner_id = auth.uid()
  ))
  with check (exists (
    select 1 from public.sets st
    join public.session_exercises se on se.id = st.session_exercise_id
    join public.workout_sessions ws on ws.id = se.session_id
    where st.id = set_id and ws.owner_id = auth.uid()
  ));
