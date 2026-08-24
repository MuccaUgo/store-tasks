-- ============================================================
-- Migrazione 6 — Progetti (tab indipendenti) + primo progetto "Pilot"
-- Incolla nello SQL Editor di Supabase ed esegui.
-- Non tocca nulla di quello che c'è già: aggiunge solo tabelle nuove.
-- ============================================================

-- Un progetto = un tab nella barra in basso.
create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,          -- l'etichetta del tab: corta
  full_name text,                     -- il nome per esteso, nel titolo
  icon text not null default '🎯',    -- emoji del tab
  starts_on date,
  ends_on date,
  status text not null default 'active',   -- 'active' | 'archived'
  position int not null default 0,
  created_at timestamptz not null default now()
);

-- I turni del progetto (giorno + fascia oraria).
create table if not exists public.project_slots (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  date date not null,
  start_time text,                    -- '16:00'
  end_time text,                      -- '18:00'
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists project_slots_lookup on public.project_slots (project_id, date);

-- Chi copre un turno, e con che ruolo.
create table if not exists public.slot_people (
  id uuid primary key default gen_random_uuid(),
  slot_id uuid not null references public.project_slots(id) on delete cascade,
  role text not null,                 -- Specialist · OnPoint · Keyrole · Coach
  person_name text not null,          -- resta leggibile anche per chi non usa l'app
  person_id uuid references public.people(id) on delete set null,
  position int not null default 0
);
create index if not exists slot_people_lookup on public.slot_people (slot_id);

-- Le liste del progetto: demo tra cui scegliere, punti del brief,
-- specialist da coinvolgere. 'checked' serve alle liste a spunta.
create table if not exists public.project_items (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  kind text not null,                 -- 'demo' | 'brief' | 'specialist'
  label text not null,
  position int not null default 0,
  checked boolean not null default false,
  active boolean not null default true
);
create index if not exists project_items_lookup on public.project_items (project_id, kind);

-- Il debrief di fine turno: in sola aggiunta, come le validazioni.
-- È qui che il pilot smette di essere impressioni e diventa numeri.
create table if not exists public.debriefs (
  id bigint generated always as identity primary key,
  project_id uuid not null references public.projects(id) on delete cascade,
  slot_id uuid references public.project_slots(id) on delete set null,
  author_id uuid references public.people(id) on delete set null,
  author_name text not null,
  in_list int,                        -- persone messe in lista
  bags int,                           -- shopping bag salvate
  conversions int,
  traffic text,                       -- 'poco' | 'medio' | 'tanto'
  demos jsonb not null default '[]'::jsonb,   -- etichette delle demo fatte
  best_demo text,
  icebreaker text,
  worked text,                        -- cosa ha funzionato
  improve text,                       -- cosa cambieresti
  created_at timestamptz not null default now()
);
create index if not exists debriefs_lookup on public.debriefs (project_id, slot_id);

-- Gli spunti: quello che nella nota condivisa finiva in mezzo alla prosa.
create table if not exists public.insights (
  id bigint generated always as identity primary key,
  project_id uuid not null references public.projects(id) on delete cascade,
  slot_id uuid references public.project_slots(id) on delete set null,
  kind text not null default 'osservazione',  -- osservazione | idea | problema | domanda
  text text not null,
  author_id uuid references public.people(id) on delete set null,
  author_name text not null,
  resolved boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists insights_lookup on public.insights (project_id, id);

-- Una domanda senza risposta è il difetto della nota: qui si risponde.
create table if not exists public.insight_replies (
  id bigint generated always as identity primary key,
  insight_id bigint not null references public.insights(id) on delete cascade,
  text text not null,
  author_id uuid references public.people(id) on delete set null,
  author_name text not null,
  created_at timestamptz not null default now()
);
create index if not exists insight_replies_lookup on public.insight_replies (insight_id, id);

-- ------------------------------------------------------------
-- Row Level Security: come per il resto dell'app, si legge e si
-- scrive solo dopo il login. I debrief non si modificano.
-- ------------------------------------------------------------
alter table public.projects        enable row level security;
alter table public.project_slots   enable row level security;
alter table public.slot_people     enable row level security;
alter table public.project_items   enable row level security;
alter table public.debriefs        enable row level security;
alter table public.insights        enable row level security;
alter table public.insight_replies enable row level security;

do $$
declare t text;
begin
  foreach t in array array['projects','project_slots','slot_people','project_items','insights','insight_replies'] loop
    execute format('drop policy if exists "team full access" on public.%I', t);
    execute format('create policy "team full access" on public.%I for all to authenticated using (true) with check (true)', t);
  end loop;
end $$;

drop policy if exists "debrief read"   on public.debriefs;
drop policy if exists "debrief insert" on public.debriefs;
create policy "debrief read"   on public.debriefs for select to authenticated using (true);
create policy "debrief insert" on public.debriefs for insert to authenticated with check (true);
-- volutamente nessuna policy di update o delete: un debrief firmato resta

-- realtime, così i turni e gli spunti si aggiornano su tutti i telefoni
do $$
declare t text;
begin
  foreach t in array array['projects','project_slots','slot_people','project_items','debriefs','insights','insight_replies'] loop
    begin
      execute format('alter publication supabase_realtime add table public.%I', t);
    exception when duplicate_object then null;
    end;
  end loop;
end $$;

-- ------------------------------------------------------------
-- Primo progetto: il Live Group Demo Pilot, dalla nota condivisa
-- ------------------------------------------------------------
do $$
declare
  p uuid;
  s uuid;
  rec record;
begin
  if exists (select 1 from public.projects where name = 'Pilot') then return; end if;

  insert into public.projects (name, full_name, icon, starts_on, ends_on, position)
  values ('Pilot', 'Live Group Demo Pilot', '🎯', date '2026-08-24', date '2026-08-30', 1)
  returning id into p;

  -- le demo tra cui scegliere le 4/5 del pilot
  insert into public.project_items (project_id, kind, label, position)
  select p, 'demo', v.label, v.pos from (values
    ('Intelligenza visiva', 1),
    ('Doppia acquisizione', 2),
    ('Selfie inquadratura automatica Center Stage', 3),
    ('Ripulisci', 4),
    ('Note registrazione audio/strumenti di scrittura', 5),
    ('Cerca nelle app (screenshot)', 6)
  ) as v(label, pos);

  -- i punti del brief di inizio turno
  insert into public.project_items (project_id, kind, label, position)
  select p, 'brief', v.label, v.pos from (values
    ('Hai letto la guida? (PR80520)', 1),
    ('Hai già in mente delle demo? (se no, mostrare demo semplici)', 2),
    ('Ricordare il target (browser, acquisti non programmati)', 3),
    ('Peer Tips: recap dei comportamenti', 4),
    ('Capire come usare la strumentazione', 5)
  ) as v(label, pos);

  -- gli specialist più estroversi con cui iniziare (spunta dalla nota)
  insert into public.project_items (project_id, kind, label, position, checked)
  select p, 'specialist', v.label, v.pos, v.ok from (values
    ('Vladi', 1, true), ('Bottigliero', 2, true), ('Marwa', 3, false),
    ('Roberto Vezio', 4, true), ('Francesca Preziosi', 5, false),
    ('Campodipietra', 6, true), ('Grieco', 7, false), ('Lupi', 8, true),
    ('Lamparelli', 9, false), ('Dada', 10, false), ('Ferrario', 11, true),
    ('Stolfi', 12, true), ('Matilde', 13, false)
  ) as v(label, pos, ok);

  -- i turni del 24-30 agosto
  for rec in select * from (values
    (date '2026-08-24', '16:00', '18:00', 'Vladi, Stolfi',               'Emma',          'Jessi, Manu',                                        'Claudio S.'),
    (date '2026-08-25', '16:00', '18:00', 'Stolfi, Vladi',               'Anisia',        'Jessi, Manu, Bandini, Max',                          ''),
    (date '2026-08-26', '16:00', '18:00', 'Campodipietra, Roberto',      'Ashley',        'Katia, Dario, Lorenzo, Casati, Max',                 ''),
    (date '2026-08-27', '16:00', '18:00', 'Ferrario, Marwa',             'Sofia',         'Casati, Max, Corraducci, Bandini, Lanfranchi, Cono', ''),
    (date '2026-08-28', '16:00', '18:00', 'Michele, Stolfi',             'Albert',        '',                                                   ''),
    (date '2026-08-29', '14:00', '16:00', 'Anisia, Vezio',               'Lupi',          '',                                                   ''),
    (date '2026-08-29', '16:00', '18:00', 'Martina Lovece, Cantamessa',  'Piazza',        '',                                                   ''),
    (date '2026-08-30', '14:00', '16:00', 'Ferrario, Albert',            'Campodipietra', '',                                                   ''),
    (date '2026-08-30', '16:00', '18:00', 'Bottigliero, Campodipietra',  'Sofia',         '',                                                   '')
  ) as t(d, t1, t2, spec, onp, keyr, coach)
  loop
    insert into public.project_slots (project_id, date, start_time, end_time)
    values (p, rec.d, rec.t1, rec.t2)
    returning id into s;

    insert into public.slot_people (slot_id, role, person_name, person_id, position)
    select s, r.role, trim(n.nm),
           (select pp.id from public.people pp where pp.name = trim(n.nm)),
           n.ord
    from (values ('Specialist', rec.spec), ('OnPoint', rec.onp),
                 ('Keyrole', rec.keyr),    ('Coach', rec.coach)) as r(role, list),
         lateral unnest(string_to_array(r.list, ',')) with ordinality as n(nm, ord)
    where trim(n.nm) <> '';
  end loop;

  -- quello che il lunedì aveva già prodotto, salvato come primo debrief
  select id into s from public.project_slots
    where project_id = p and date = date '2026-08-24' limit 1;

  insert into public.debriefs (project_id, slot_id, author_name, conversions, icebreaker, worked)
  values (p, s, 'Nota condivisa', 5, 'Hai già l''iPhone? (Vladi)',
          'Sorpresa da parte dei clienti, effetto wow');

  -- e le osservazioni sparse nella nota, ognuna al suo posto
  insert into public.insights (project_id, slot_id, kind, text, author_name) values
    (p, s, 'idea',         'Vieni che ti faccio vedere una funzione (Nico)', 'Nota condivisa'),
    (p, s, 'osservazione', 'Demo sempre diverse',                            'Nota condivisa'),
    (p, s, 'osservazione', 'Maggiore conversion quando c''era meno traffico', 'Nota condivisa'),
    (p, s, 'domanda',      'Cosa fare quando ci sono tante persone? Mostro una funzione', 'Nota condivisa');
end $$;
