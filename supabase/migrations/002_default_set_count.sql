-- Run this after 001_initial.sql for an existing Lift Log database.
alter table public.profiles
  add column if not exists default_set_count smallint not null default 3
  check (default_set_count between 1 and 20);

-- Empty pre-added set rows use zero as a draft value until the user enters a real set.
alter table public.sets drop constraint if exists sets_reps_check;
alter table public.sets add constraint sets_reps_check check (reps >= 0 and reps <= 1000);
