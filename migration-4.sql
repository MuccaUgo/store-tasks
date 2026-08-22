-- ============================================================
-- Migrazione 4 — tag destinatari del DD: PZ solo / All team
-- Incolla nello SQL Editor di Supabase ed esegui.
-- ============================================================

alter table public.downloads
  add column if not exists audience text not null default 'all';  -- 'pz' | 'all'
