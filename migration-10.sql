-- ============================================================
-- Migrazione 10 — FACOLTATIVA
-- L'app non ne ha bisogno: la data del fatto la tiene nel momento
-- dell'aggiornamento, e una correzione riscrive la riga.
-- Questa migrazione aggiunge solo una colonna dedicata, l'indice
-- per l'ordinamento e il permesso di modifica diretta.
-- ============================================================

alter table public.focus_updates
  add column if not exists happened_on date;

update public.focus_updates
   set happened_on = (created_at at time zone 'Europe/Rome')::date
 where happened_on is null;

alter table public.focus_updates
  alter column happened_on set default current_date;

create index if not exists focus_updates_quando
  on public.focus_updates (focus_id, happened_on desc, id desc);

-- un aggiornamento si può correggere: mancava il permesso
drop policy if exists "fupd update" on public.focus_updates;
create policy "fupd update" on public.focus_updates
  for update to authenticated using (true) with check (true);
