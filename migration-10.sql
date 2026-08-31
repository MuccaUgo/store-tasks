-- ============================================================
-- Migrazione 10 — La data dell'aggiornamento nel Focus
-- L'aggiornamento si scrive spesso il giorno dopo: la data del
-- fatto è una cosa, il momento in cui lo si annota è un'altra.
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
