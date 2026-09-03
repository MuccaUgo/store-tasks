-- ============================================================
-- Migrazione 13 — Commenti sui DD
-- Incolla nello SQL Editor di Supabase ed esegui.
-- Aggiunge solo una tabella nuova: non tocca nulla di esistente.
-- ============================================================

create table if not exists public.dd_comments (
  id bigint generated always as identity primary key,
  download_id uuid not null references public.downloads(id) on delete cascade,
  body text not null,
  actor_id uuid references public.people(id) on delete set null,
  actor_name text not null,
  created_at timestamptz not null default now()
);
create index if not exists dd_comments_lookup
  on public.dd_comments (download_id, id);

alter table public.dd_comments enable row level security;

drop policy if exists "ddcomments all" on public.dd_comments;
create policy "ddcomments all" on public.dd_comments
  for all to authenticated using (true) with check (true);

do $$
begin
  alter publication supabase_realtime add table public.dd_comments;
exception when duplicate_object then null;
end $$;
