-- ============================================================
-- Migrazione 11 — Proposte e decisioni dentro un focus
-- Incolla nello SQL Editor di Supabase ed esegui.
-- Non tocca i dati esistenti: gli aggiornamenti già scritti
-- restano aggiornamenti (kind = 'agg').
-- ============================================================

-- Un punto sulla scia ora può essere di tre tipi:
--   agg        · un aggiornamento, come prima
--   proposta   · qualcosa da decidere: si vota e si commenta
--   decisione  · una proposta chiusa, con l'esito
alter table public.focus_updates
  add column if not exists kind text not null default 'agg';

-- Solo per le decisioni: com'è finita, chi ha deciso e quando
alter table public.focus_updates add column if not exists outcome text;
alter table public.focus_updates add column if not exists decided_at timestamptz;
alter table public.focus_updates add column if not exists decided_by text;

create index if not exists focus_updates_kind
  on public.focus_updates (focus_id, kind);

-- Serve poter modificare la riga: una proposta diventa decisione
-- (e può tornare proposta) restando la stessa riga, così voti e
-- commenti non si perdono per strada.
drop policy if exists "fupd update" on public.focus_updates;
create policy "fupd update" on public.focus_updates
  for update to authenticated using (true) with check (true);

-- ------------------------------------------------------------
-- I voti: uno a testa, col nome, sempre ritirabile
-- ------------------------------------------------------------
create table if not exists public.focus_votes (
  id bigint generated always as identity primary key,
  update_id bigint not null references public.focus_updates(id) on delete cascade,
  actor_id uuid references public.people(id) on delete set null,
  actor_name text not null,
  value smallint not null check (value in (-1, 1)),
  created_at timestamptz not null default now(),
  unique (update_id, actor_name)
);
create index if not exists focus_votes_lookup on public.focus_votes (update_id);

-- ------------------------------------------------------------
-- I commenti sotto una proposta
-- ------------------------------------------------------------
create table if not exists public.focus_comments (
  id bigint generated always as identity primary key,
  update_id bigint not null references public.focus_updates(id) on delete cascade,
  body text not null,
  actor_id uuid references public.people(id) on delete set null,
  actor_name text not null,
  created_at timestamptz not null default now()
);
create index if not exists focus_comments_lookup on public.focus_comments (update_id, id);

-- ------------------------------------------------------------
-- Accesso: solo dopo il login, come per il resto dell'app
-- ------------------------------------------------------------
alter table public.focus_votes    enable row level security;
alter table public.focus_comments enable row level security;

drop policy if exists "fvotes all"    on public.focus_votes;
drop policy if exists "fcomments all" on public.focus_comments;

create policy "fvotes all"    on public.focus_votes
  for all to authenticated using (true) with check (true);
create policy "fcomments all" on public.focus_comments
  for all to authenticated using (true) with check (true);

-- ------------------------------------------------------------
-- Aggiornamenti in tempo reale sugli altri telefoni
-- ------------------------------------------------------------
do $$
begin
  alter publication supabase_realtime add table public.focus_votes;
exception when duplicate_object then null;
end $$;
do $$
begin
  alter publication supabase_realtime add table public.focus_comments;
exception when duplicate_object then null;
end $$;
