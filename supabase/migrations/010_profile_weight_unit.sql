-- Store a per-user display and entry preference. Set weights remain canonical
-- kilograms in the database, so changing this setting never changes history.
alter table public.profiles
  add column if not exists weight_unit text not null default 'kg'
  check (weight_unit in ('kg', 'lb'));
