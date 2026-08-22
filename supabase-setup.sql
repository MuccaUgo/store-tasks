-- ============================================================
-- Store Tasks — setup database Supabase
-- Incolla tutto questo nello SQL Editor di Supabase ed esegui.
-- ============================================================

-- Team: le persone dello store
create table public.people (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

-- Download: le presentazioni da preparare/caricare/presentare
create table public.downloads (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  date date not null,
  preparer_id uuid references public.people(id) on delete set null,
  uploaded boolean not null default false,
  presenter_id uuid references public.people(id) on delete set null,
  presented boolean not null default false,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Competenze da validare per i nuovi arrivati (lista gestibile dall'app)
create table public.competencies (
  id uuid primary key default gen_random_uuid(),
  label text not null,
  position int not null default 0,
  active boolean not null default true
);

-- FWE: i nuovi arrivati
create table public.fwe (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  start_date date,
  notes text,
  created_at timestamptz not null default now()
);

-- Validazioni: quale competenza è stata validata, per chi, da chi
create table public.fwe_validations (
  id uuid primary key default gen_random_uuid(),
  fwe_id uuid not null references public.fwe(id) on delete cascade,
  competency_id uuid not null references public.competencies(id) on delete cascade,
  validated_by uuid references public.people(id) on delete set null,
  validated_at timestamptz not null default now(),
  unique (fwe_id, competency_id)
);

-- Storico attività: chi ha fatto cosa (non modificabile dagli utenti)
create table public.activity_log (
  id bigint generated always as identity primary key,
  actor text,
  action text not null,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- Row Level Security: tutto chiuso, aperto solo a chi ha
-- fatto il login (ruolo "authenticated").
-- ------------------------------------------------------------
alter table public.people          enable row level security;
alter table public.downloads       enable row level security;
alter table public.competencies    enable row level security;
alter table public.fwe             enable row level security;
alter table public.fwe_validations enable row level security;
alter table public.activity_log    enable row level security;

create policy "team full access" on public.people
  for all to authenticated using (true) with check (true);
create policy "team full access" on public.downloads
  for all to authenticated using (true) with check (true);
create policy "team full access" on public.competencies
  for all to authenticated using (true) with check (true);
create policy "team full access" on public.fwe
  for all to authenticated using (true) with check (true);
create policy "team full access" on public.fwe_validations
  for all to authenticated using (true) with check (true);

-- Lo storico si può leggere e aggiungere, mai modificare o cancellare
create policy "log read"   on public.activity_log
  for select to authenticated using (true);
create policy "log insert" on public.activity_log
  for insert to authenticated with check (true);

-- ------------------------------------------------------------
-- Aggiornamenti in tempo reale sui dispositivi collegati
-- ------------------------------------------------------------
alter publication supabase_realtime add table
  public.people, public.downloads, public.competencies,
  public.fwe, public.fwe_validations;

-- ------------------------------------------------------------
-- Qualche competenza di esempio (modificabili dall'app)
-- ------------------------------------------------------------
insert into public.competencies (label, position) values
  ('Accoglienza cliente', 1),
  ('Gestione coda', 2),
  ('Procedure di cassa', 3),
  ('Conoscenza prodotto', 4);
