-- Run after migrations 001 through 005.
-- A muscle target is intentionally attached to a specific muscle/region, then
-- rolled up to its group. Each exercise has exactly one primary target and may
-- have any number of secondary targets.
create type public.muscle_target_role as enum ('primary', 'secondary');

create table public.muscle_groups (
  id uuid primary key default gen_random_uuid(),
  name text not null unique check (char_length(name) between 2 and 60),
  position smallint not null default 100 check (position >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.muscles (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.muscle_groups(id) on delete restrict,
  name text not null unique check (char_length(name) between 2 and 80),
  position smallint not null default 100 check (position >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.exercise_muscles (
  exercise_id uuid not null references public.exercises(id) on delete cascade,
  muscle_id uuid not null references public.muscles(id) on delete restrict,
  role public.muscle_target_role not null,
  primary key (exercise_id, muscle_id)
);

create unique index one_primary_target_per_exercise on public.exercise_muscles (exercise_id) where role = 'primary';
create index exercise_muscles_muscle_idx on public.exercise_muscles (muscle_id);

create table public.muscle_suggestions (
  id uuid primary key default gen_random_uuid(),
  muscle_id uuid references public.muscles(id) on delete set null,
  author_id uuid not null default auth.uid() references public.profiles(id),
  suggestion text not null check (char_length(suggestion) between 3 and 1000),
  status text not null default 'pending' check (status in ('pending', 'accepted', 'dismissed')),
  created_at timestamptz not null default now()
);

create trigger muscle_groups_touch before update on public.muscle_groups for each row execute procedure public.touch_updated_at();
create trigger muscles_touch before update on public.muscles for each row execute procedure public.touch_updated_at();

alter table public.muscle_groups enable row level security;
alter table public.muscles enable row level security;
alter table public.exercise_muscles enable row level security;
alter table public.muscle_suggestions enable row level security;

create policy "muscle groups readable" on public.muscle_groups for select to authenticated using (true);
create policy "muscles readable" on public.muscles for select to authenticated using (true);
create policy "exercise targets readable" on public.exercise_muscles for select to authenticated using (true);
create policy "admins manage muscle groups" on public.muscle_groups for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "admins manage muscles" on public.muscles for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "admins manage exercise targets" on public.exercise_muscles for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "members submit muscle suggestions" on public.muscle_suggestions for insert to authenticated with check (author_id = auth.uid());
create policy "suggestions readable by author or admin" on public.muscle_suggestions for select to authenticated using (author_id = auth.uid() or public.is_admin());
create policy "admins update muscle suggestions" on public.muscle_suggestions for update to authenticated using (public.is_admin()) with check (public.is_admin());

insert into public.muscle_groups (name, position) values
  ('Chest', 10), ('Back', 20), ('Shoulders', 30), ('Biceps', 40), ('Triceps', 50), ('Forearms', 60),
  ('Quadriceps', 70), ('Hamstrings', 80), ('Glutes', 90), ('Calves', 100), ('Hips', 110), ('Core', 120), ('Traps & neck', 130)
on conflict (name) do nothing;

insert into public.muscles (group_id, name, position)
select g.id, seed.name, seed.position
from (values
  ('Chest', 'Upper chest', 10), ('Chest', 'Mid chest', 20), ('Chest', 'Lower chest', 30),
  ('Back', 'Latissimus dorsi (lats)', 10), ('Back', 'Upper back', 20), ('Back', 'Mid back', 30), ('Back', 'Lower back', 40),
  ('Shoulders', 'Front deltoid', 10), ('Shoulders', 'Lateral deltoid', 20), ('Shoulders', 'Rear deltoid', 30),
  ('Biceps', 'Biceps long head', 10), ('Biceps', 'Biceps short head', 20), ('Biceps', 'Brachialis', 30), ('Biceps', 'Brachioradialis', 40),
  ('Triceps', 'Triceps long head', 10), ('Triceps', 'Triceps lateral head', 20), ('Triceps', 'Triceps medial head', 30),
  ('Forearms', 'Forearm flexors', 10), ('Forearms', 'Forearm extensors', 20),
  ('Quadriceps', 'Rectus femoris', 10), ('Quadriceps', 'Vastus lateralis', 20), ('Quadriceps', 'Vastus medialis', 30), ('Quadriceps', 'Vastus intermedius', 40),
  ('Hamstrings', 'Biceps femoris', 10), ('Hamstrings', 'Semitendinosus', 20), ('Hamstrings', 'Semimembranosus', 30),
  ('Glutes', 'Gluteus maximus', 10), ('Glutes', 'Gluteus medius', 20), ('Glutes', 'Gluteus minimus', 30),
  ('Calves', 'Gastrocnemius', 10), ('Calves', 'Soleus', 20), ('Calves', 'Tibialis anterior', 30),
  ('Hips', 'Hip adductors', 10), ('Hips', 'Hip abductors', 20), ('Hips', 'Hip flexors', 30),
  ('Core', 'Rectus abdominis', 10), ('Core', 'Obliques', 20), ('Core', 'Transverse abdominis', 30), ('Core', 'Spinal erectors', 40),
  ('Traps & neck', 'Upper trapezius', 10), ('Traps & neck', 'Middle trapezius', 20), ('Traps & neck', 'Lower trapezius', 30), ('Traps & neck', 'Neck flexors', 40), ('Traps & neck', 'Neck extensors', 50)
) as seed(group_name, name, position)
join public.muscle_groups g on g.name = seed.group_name
on conflict (name) do nothing;
