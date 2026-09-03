-- ============================================================
-- Migrazione 12 — Una seconda persona che facilita il DD
-- Incolla nello SQL Editor di Supabase ed esegui.
-- Non tocca i dati esistenti: la colonna nasce vuota.
-- ============================================================

-- Chi facilita può non essere da solo: il secondo posto è facoltativo
alter table public.downloads
  add column if not exists presenter2_id uuid references public.people(id) on delete set null;

create index if not exists downloads_presenter2
  on public.downloads (presenter2_id);
