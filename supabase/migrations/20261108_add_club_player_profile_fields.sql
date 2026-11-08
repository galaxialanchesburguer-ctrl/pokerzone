alter table public.club_players
  add column if not exists email text,
  add column if not exists birth_date date,
  add column if not exists gender text;
