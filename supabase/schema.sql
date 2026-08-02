-- BettenNetz Österreich — Supabase schema (real auth + transfers + realtime)
-- Run this once, top to bottom, in the SQL editor of a fresh Supabase project.
--
-- After running this file, the app still works standalone with the
-- client-side demo accounts (ACCS in index.html) until ALL of the following
-- are done — that's what flips SUPABASE_CONFIGURED to true and switches the
-- login screen from the demo mock over to real Supabase Auth:
--   1. For each hospital account: Authentication → Users → Add user, with
--      email "<username>@bettennetz.local" (e.g. akh.wien@bettennetz.local)
--      and a real password. Do NOT reuse the old demo passwords.
--   2. Copy each created user's UID and run the matching insert at the
--      bottom of this file to link it to a hospital_profiles row.
--   3. Fill SUPABASE_URL and SUPABASE_ANON_KEY into index.html.

-- ---------------------------------------------------------------------------
-- hospital_profiles — maps a Supabase Auth user to a hospital identity/role.
-- Provisioned manually (see step 2 above); hospitals cannot self-register
-- or change their own role.
-- ---------------------------------------------------------------------------
create table if not exists hospital_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  hospital text not null check (char_length(hospital) between 1 and 120),
  city text not null check (char_length(city) between 1 and 80),
  bl text not null check (char_length(bl) between 1 and 20),
  role text not null check (role in ('admin','staff','goeg'))
);

alter table hospital_profiles enable row level security;

-- A hospital can read its own profile (needed right after login); GÖG can
-- read every profile.
create policy "profiles_select_own_or_goeg" on hospital_profiles
  for select to authenticated
  using (
    user_id = auth.uid()
    or exists (select 1 from hospital_profiles p where p.user_id = auth.uid() and p.role = 'goeg')
  );

-- ---------------------------------------------------------------------------
-- transfers
-- ---------------------------------------------------------------------------
create table if not exists transfers (
  id uuid primary key default gen_random_uuid(),
  tid text not null unique,
  from_hospital text not null check (char_length(from_hospital) between 1 and 120),
  to_hospital text not null check (char_length(to_hospital) between 1 and 120),
  fach text not null check (fach in (
    'Allgemeinchirurgie','Herzchirurgie / Kardiologie','Neurochirurgie',
    'Orthopädie / Unfallchirurgie','Gynäkologie','Geburtshilfe / Entbindung',
    'Urologie','Onkologie'
  )),
  prio text not null check (prio in ('Normal','Dringend','Notfall')),
  status text not null default 'pending' check (status in ('pending','accepted','declined')),
  created_at timestamptz not null default now()
);

alter table transfers enable row level security;

-- A hospital sees a transfer only if it's the sender or the recipient;
-- GÖG (role='goeg') sees every transfer, matching its national oversight role.
create policy "transfers_select_own_or_goeg" on transfers
  for select to authenticated
  using (
    from_hospital = (select hospital from hospital_profiles where user_id = auth.uid())
    or to_hospital = (select hospital from hospital_profiles where user_id = auth.uid())
    or exists (select 1 from hospital_profiles p where p.user_id = auth.uid() and p.role = 'goeg')
  );

-- A hospital may only create requests *from itself* — prevents one hospital
-- from spoofing another's identity as the sender.
create policy "transfers_insert_own" on transfers
  for insert to authenticated
  with check (
    from_hospital = (select hospital from hospital_profiles where user_id = auth.uid())
  );

-- Only the receiving hospital may act on a request, and only while pending
-- (no re-deciding an already-accepted/declined request).
create policy "transfers_update_recipient" on transfers
  for update to authenticated
  using (
    to_hospital = (select hospital from hospital_profiles where user_id = auth.uid())
    and status = 'pending'
  )
  with check (
    to_hospital = (select hospital from hospital_profiles where user_id = auth.uid())
  );

-- Column-level grant: even the recipient may only ever change `status` —
-- never rewrite from_hospital/to_hospital/fach/prio on an existing row.
revoke update on transfers from authenticated;
grant update (status) on transfers to authenticated;

alter publication supabase_realtime add table transfers;

-- ---------------------------------------------------------------------------
-- capacity_history — one snapshot per hospital per save(), powering the
-- "Berichte" trend chart with real data instead of the client-side demo
-- numbers. Not wired up in index.html yet — save() would need to insert a
-- row here (overall utilization %, or per-category if the chart is later
-- broken out by Fachbereich) each time a hospital publishes.
-- ---------------------------------------------------------------------------
create table if not exists capacity_history (
  id uuid primary key default gen_random_uuid(),
  hospital text not null check (char_length(hospital) between 1 and 120),
  pct integer not null check (pct between 0 and 100),
  recorded_at timestamptz not null default now()
);

alter table capacity_history enable row level security;

create index if not exists capacity_history_hospital_idx
  on capacity_history (hospital, recorded_at desc);

-- A hospital may insert/read only its own history; GÖG reads everyone's.
create policy "capacity_history_select_own_or_goeg" on capacity_history
  for select to authenticated
  using (
    hospital = (select hospital from hospital_profiles where user_id = auth.uid())
    or exists (select 1 from hospital_profiles p where p.user_id = auth.uid() and p.role = 'goeg')
  );

create policy "capacity_history_insert_own" on capacity_history
  for insert to authenticated
  with check (
    hospital = (select hospital from hospital_profiles where user_id = auth.uid())
  );

-- ---------------------------------------------------------------------------
-- Seed demo transfer rows (no real patient data, safe to keep).
-- ---------------------------------------------------------------------------
insert into transfers (tid, from_hospital, to_hospital, fach, prio, status, created_at)
values
  ('TRF-2847', 'LKH Univ. Graz',   'AKH Wien', 'Herzchirurgie / Kardiologie',     'Notfall',  'pending',  now() - interval '2 hour'),
  ('TRF-2846', 'Klinikum Wels',    'AKH Wien', 'Allgemeinchirurgie',              'Dringend', 'pending',  now() - interval '2.5 hour'),
  ('TRF-2831', 'LKH Salzburg',     'AKH Wien', 'Orthopädie / Unfallchirurgie',    'Normal',   'accepted', now() - interval '4 hour')
on conflict (tid) do nothing;

-- ---------------------------------------------------------------------------
-- hospital_profiles seed template — after creating each Auth user (step 1
-- above), copy its UID from Authentication → Users and run the matching
-- insert below. Template for the three current demo accounts:
-- ---------------------------------------------------------------------------
-- insert into hospital_profiles (user_id, hospital, city, bl, role) values
--   ('paste-akh-wien-user-uid-here', 'AKH Wien', 'Wien', 'Wien', 'admin');
--
-- insert into hospital_profiles (user_id, hospital, city, bl, role) values
--   ('paste-kh-linz-user-uid-here', 'Kepler Universitätsklinikum', 'Linz', 'OÖ', 'staff');
--
-- insert into hospital_profiles (user_id, hospital, city, bl, role) values
--   ('paste-goeg-user-uid-here', 'GÖG Gesundheit Österreich', 'Wien', 'AT', 'goeg');
