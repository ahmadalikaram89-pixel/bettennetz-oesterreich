-- BettenNetz Österreich — transfers table + realtime sync
-- Run this once in the Supabase SQL editor of the dedicated BettenNetz project.

create table if not exists transfers (
  id uuid primary key default gen_random_uuid(),
  tid text not null unique,
  from_hospital text not null,
  fach text not null,
  prio text not null,
  status text not null default 'pending' check (status in ('pending','accepted','declined')),
  created_at timestamptz not null default now()
);

alter table transfers enable row level security;

-- Demo-only: the app has no real Supabase auth yet (login is still the
-- client-side mock), so the anon key needs open read/write here. Tighten
-- this once real hospital auth is wired up.
create policy "transfers_select_anon" on transfers
  for select to anon using (true);

create policy "transfers_insert_anon" on transfers
  for insert to anon with check (true);

create policy "transfers_update_anon" on transfers
  for update to anon using (true);

alter publication supabase_realtime add table transfers;

-- Seed with the same demo rows the static prototype used to ship with.
insert into transfers (tid, from_hospital, fach, prio, status, created_at)
values
  ('TRF-2847', 'LKH Univ. Graz',   'Herzchirurgie / Kardiologie',     'Notfall',  'pending',  now() - interval '2 hour'),
  ('TRF-2846', 'Klinikum Wels',    'Allgemeinchirurgie',              'Dringend', 'pending',  now() - interval '2.5 hour'),
  ('TRF-2831', 'LKH Salzburg',     'Orthopädie / Unfallchirurgie',    'Normal',   'accepted', now() - interval '4 hour')
on conflict (tid) do nothing;
