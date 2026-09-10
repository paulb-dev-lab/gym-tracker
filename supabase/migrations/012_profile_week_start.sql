-- Store the start of each user's workout week. Fixed weekdays are interpreted
-- in the user's device timezone; rolling_7_days is the previous 7x24 hours.
alter table public.profiles
  add column if not exists week_starts_on text not null default 'monday'
  check (week_starts_on in ('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday', 'rolling_7_days'));
