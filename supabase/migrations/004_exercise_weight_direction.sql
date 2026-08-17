-- Run after the prior migrations for an existing Lift Log project.
-- This controls whether a heavier number is better, or whether it is assistance
-- where a lower number is better (for example, assisted pull-ups).
alter table public.exercises
  add column if not exists weight_direction text not null default 'higher_is_better';

alter table public.exercises
  drop constraint if exists exercises_weight_direction_check;

alter table public.exercises
  add constraint exercises_weight_direction_check
  check (weight_direction in ('higher_is_better', 'lower_is_better'));
