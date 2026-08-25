-- ============================================================
-- Migrazione 7 — Focus Flow
-- Incolla nello SQL Editor di Supabase ed esegui.
-- Non tocca nulla di esistente: aggiunge solo tre tabelle nuove.
-- ============================================================

-- I focus di store: cose che portiamo avanti nel tempo
create table if not exists public.focus (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  goal text,                 -- il risultato desiderato
  indicator text,            -- come ci accorgiamo che sta funzionando
  owner_id uuid references public.people(id) on delete set null,
  status text not null default 'attivo',   -- attivo · concluso · abbandonato
  outcome text,              -- com'è andata a finire
  created_at timestamptz not null default now(),
  closed_at timestamptz
);

-- Gli aggiornamenti: un punto sulla scia per ognuno
create table if not exists public.focus_updates (
  id bigint generated always as identity primary key,
  focus_id uuid not null references public.focus(id) on delete cascade,
  body text not null,
  actor_id uuid references public.people(id) on delete set null,
  actor_name text not null,
  created_at timestamptz not null default now()
);
create index if not exists focus_updates_lookup
  on public.focus_updates (focus_id, created_at);

-- Il serbatoio delle idee: cattura in due parole
create table if not exists public.ideas (
  id uuid primary key default gen_random_uuid(),
  body text not null,
  actor_name text,
  promoted_focus_id uuid references public.focus(id) on delete set null,
  archived boolean not null default false,
  created_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- Accesso: solo dopo il login, come per il resto dell'app
-- ------------------------------------------------------------
alter table public.focus         enable row level security;
alter table public.focus_updates enable row level security;
alter table public.ideas         enable row level security;

drop policy if exists "focus all"    on public.focus;
drop policy if exists "fupd read"    on public.focus_updates;
drop policy if exists "fupd insert"  on public.focus_updates;
drop policy if exists "fupd delete"  on public.focus_updates;
drop policy if exists "ideas all"    on public.ideas;

create policy "focus all"   on public.focus
  for all to authenticated using (true) with check (true);
create policy "fupd read"   on public.focus_updates
  for select to authenticated using (true);
create policy "fupd insert" on public.focus_updates
  for insert to authenticated with check (true);
create policy "fupd delete" on public.focus_updates
  for delete to authenticated using (true);
create policy "ideas all"   on public.ideas
  for all to authenticated using (true) with check (true);

-- ------------------------------------------------------------
-- Aggiornamenti in tempo reale sugli altri telefoni
-- ------------------------------------------------------------
do $$
begin
  alter publication supabase_realtime add table public.focus;
exception when duplicate_object then null;
end $$;
do $$
begin
  alter publication supabase_realtime add table public.focus_updates;
exception when duplicate_object then null;
end $$;
do $$
begin
  alter publication supabase_realtime add table public.ideas;
exception when duplicate_object then null;
end $$;
