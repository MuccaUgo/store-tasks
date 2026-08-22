-- ============================================================
-- Migrazione 2 — solo DD Product, campo Manager, titolo obbligatorio
-- Incolla nello SQL Editor di Supabase ed esegui.
-- ============================================================

-- via i DD di prova (argomenti casuali): si riparte puliti
delete from public.downloads;

-- il concetto di "argomento" non serve più: sono tutti Product
alter table public.downloads drop column if exists topic;

-- nuovo campo: manager presente (testo libero, opzionale)
alter table public.downloads add column if not exists manager text;

-- il titolo ora è obbligatorio
alter table public.downloads alter column title set not null;
