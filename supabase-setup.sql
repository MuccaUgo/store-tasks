-- ============================================================
-- Store Tasks — setup database Supabase (v2)
-- Incolla tutto nello SQL Editor di Supabase ed esegui.
-- NOTA: ricrea le tabelle da zero (cancella eventuali dati
-- inseriti con la versione precedente dello script).
-- ============================================================

drop table if exists public.fwe_validations cascade;
drop table if exists public.fwe             cascade;
drop table if exists public.competencies    cascade;
drop table if exists public.downloads       cascade;
drop table if exists public.people          cascade;
drop table if exists public.activity_log    cascade;

-- Team: chi usa l'app (login + assegnazioni DD)
create table public.people (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

-- DD (Daily Download): calendario delle presentazioni (solo Product)
create table public.downloads (
  id uuid primary key default gen_random_uuid(),
  date date not null,
  title text not null,                      -- anche provvisorio
  preparer_id uuid references public.people(id) on delete set null,
  uploaded boolean not null default false,
  presenter_id uuid references public.people(id) on delete set null,  -- chi lo delivera
  presented boolean not null default false,
  manager text,                             -- manager presente (testo libero)
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Competenze da validare per gli FWE
create table public.competencies (
  id uuid primary key default gen_random_uuid(),
  label text not null,
  position int not null default 0,
  active boolean not null default true
);

-- FWE: i nuovi arrivati (non hanno accesso all'app)
create table public.fwe (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  start_date date,
  notes text,
  created_at timestamptz not null default now()
);

-- Validazioni: competenza validata per un FWE, da chi e quando
create table public.fwe_validations (
  id uuid primary key default gen_random_uuid(),
  fwe_id uuid not null references public.fwe(id) on delete cascade,
  competency_id uuid not null references public.competencies(id) on delete cascade,
  validated_by uuid references public.people(id) on delete set null,
  validated_at timestamptz not null default now(),
  unique (fwe_id, competency_id)
);

-- Storico attività: solo-aggiunta
create table public.activity_log (
  id bigint generated always as identity primary key,
  actor text,
  action text not null,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- Row Level Security: accesso solo dopo il login
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

create policy "log read"   on public.activity_log
  for select to authenticated using (true);
create policy "log insert" on public.activity_log
  for insert to authenticated with check (true);

-- ------------------------------------------------------------
-- Aggiornamenti in tempo reale
-- ------------------------------------------------------------
alter publication supabase_realtime add table
  public.people, public.downloads, public.competencies,
  public.fwe, public.fwe_validations;

-- ------------------------------------------------------------
-- Dati iniziali
-- ------------------------------------------------------------

-- 10 utenti del team (cognomi di prova)
insert into public.people (name) values
  ('Rossi'), ('Bianchi'), ('Ferrari'), ('Russo'), ('Esposito'),
  ('Colombo'), ('Ricci'), ('Marino'), ('Greco'), ('Gallo');

-- Le 4 competenze da validare
insert into public.competencies (label, position) values
  ('Competenze operative', 1),
  ('Approccio', 2),
  ('Demo', 3),
  ('Business', 4);

-- 30 FWE da validare (cognomi di prova, senza accesso all'app)
insert into public.fwe (name) values
  ('Conti'), ('Bruno'), ('Rizzo'), ('Moretti'), ('De Luca'),
  ('Costa'), ('Giordano'), ('Mancini'), ('Lombardi'), ('Barbieri'),
  ('Fontana'), ('Santoro'), ('Mariani'), ('Rinaldi'), ('Caruso'),
  ('Ferrara'), ('Galli'), ('Martini'), ('Leone'), ('Longo'),
  ('Gentile'), ('Vitale'), ('Lombardo'), ('Serra'), ('Coppola'),
  ('De Santis'), ('D''Angelo'), ('Marchetti'), ('Parisi'), ('Villa');
