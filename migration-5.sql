-- ============================================================
-- Migrazione 5 — tab Validation
-- Incolla nello SQL Editor di Supabase ed esegui.
-- Non cancella dati esistenti (fwe_validations è vuota).
-- ============================================================

-- 1. competenze su due livelli: un'area può avere sotto-competenze
alter table public.competencies
  add column if not exists parent_id uuid references public.competencies(id) on delete cascade;

-- 2. wave di ingresso degli FWE
alter table public.fwe
  add column if not exists wave int not null default 1;

-- 3. gli eventi di validazione: tabella in sola aggiunta.
--    Lo stato attuale di una competenza è semplicemente il suo ultimo evento.
drop table if exists public.fwe_validations cascade;

create table if not exists public.fwe_events (
  id bigint generated always as identity primary key,
  fwe_id uuid not null references public.fwe(id) on delete cascade,
  competency_id uuid not null references public.competencies(id) on delete cascade,
  level int not null,          -- -1 non richiesta · 0 da osservare · 1 osservato · 2 validato
  actor_id uuid references public.people(id) on delete set null,
  actor_name text not null,    -- resta leggibile anche se la persona lascia il team
  note text,                   -- obbligatoria solo quando si torna indietro
  created_at timestamptz not null default now()
);
create index if not exists fwe_events_lookup
  on public.fwe_events (fwe_id, competency_id, id);

alter table public.fwe_events enable row level security;

drop policy if exists "events read" on public.fwe_events;
drop policy if exists "events insert" on public.fwe_events;
create policy "events read"   on public.fwe_events for select to authenticated using (true);
create policy "events insert" on public.fwe_events for insert to authenticated with check (true);
-- volutamente nessuna policy di update o delete: un evento non si modifica

-- 4. realtime sulla nuova tabella
do $$
begin
  alter publication supabase_realtime add table public.fwe_events;
exception when duplicate_object then null;
end $$;

-- ------------------------------------------------------------
-- 5. struttura delle competenze
-- ------------------------------------------------------------

-- fa spazio a "Conoscenza prodotto" in terza posizione
update public.competencies set position = position + 1
  where parent_id is null and position >= 3;

insert into public.competencies (label, position)
select 'Conoscenza prodotto', 3
where not exists (
  select 1 from public.competencies where label = 'Conoscenza prodotto' and parent_id is null
);

-- sotto-competenze delle Competenze operative
insert into public.competencies (label, position, parent_id)
select v.label, v.pos,
       (select id from public.competencies where label = 'Competenze operative' and parent_id is null)
from (values ('Trade in', 1), ('Resi', 2), ('Taxfree', 3), ('Backup', 4), ('Edu offer', 5)) as v(label, pos)
where not exists (select 1 from public.competencies c where c.label = v.label and c.parent_id is not null);

-- sotto-competenze di Conoscenza prodotto
insert into public.competencies (label, position, parent_id)
select v.label, v.pos,
       (select id from public.competencies where label = 'Conoscenza prodotto' and parent_id is null)
from (values ('iPhone', 1), ('iPad', 2), ('Mac', 3), ('Apple Watch', 4)) as v(label, pos)
where not exists (select 1 from public.competencies c where c.label = v.label and c.parent_id is not null);
