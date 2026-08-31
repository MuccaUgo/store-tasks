-- ============================================================
-- Migrazione 8 — Brief e Debrief come li scrivete davvero
-- Incolla nello SQL Editor di Supabase ed esegui.
-- Aggiunge i punti ✅/❌ del turno, il brief per persona, e porta
-- dentro la settimana 24-30/08 e i turni fino al 05/09.
-- ============================================================

-- 1. I punti del turno: ogni ✅ e ogni ❌ è una riga, aggiungibile
--    in qualsiasi momento e da chiunque, come si fa sulla nota.
create table if not exists public.shift_points (
  id bigint generated always as identity primary key,
  slot_id uuid not null references public.project_slots(id) on delete cascade,
  kind text not null,              -- 'good' (✅) · 'bad' (❌)
  text text not null,
  actor_id uuid references public.people(id) on delete set null,
  actor_name text not null,
  created_at timestamptz not null default now()
);
create index if not exists shift_points_lookup on public.shift_points (slot_id, id);

-- 2. Il brief di inizio turno, spuntato da ognuno per sé
create table if not exists public.briefs (
  id bigint generated always as identity primary key,
  slot_id uuid not null references public.project_slots(id) on delete cascade,
  person_id uuid references public.people(id) on delete set null,
  person_name text not null,
  items jsonb not null default '[]'::jsonb,   -- le voci spuntate
  created_at timestamptz not null default now(),
  unique (slot_id, person_name)
);
create index if not exists briefs_lookup on public.briefs (slot_id);

-- 3. Persone raggiunte: il numero che conta insieme alle conversion
alter table public.debriefs add column if not exists reached int;

-- 4. "Point" è come lo chiamate adesso
update public.slot_people set role = 'Point' where role = 'OnPoint';

alter table public.shift_points enable row level security;
alter table public.briefs       enable row level security;

drop policy if exists "team full access" on public.briefs;
create policy "team full access" on public.briefs
  for all to authenticated using (true) with check (true);

-- i punti si aggiungono e si correggono, ma non si cancellano di nascosto
drop policy if exists "points read"   on public.shift_points;
drop policy if exists "points insert" on public.shift_points;
drop policy if exists "points delete" on public.shift_points;
create policy "points read"   on public.shift_points for select to authenticated using (true);
create policy "points insert" on public.shift_points for insert to authenticated with check (true);
create policy "points delete" on public.shift_points for delete to authenticated using (true);

do $$
declare t text;
begin
  foreach t in array array['shift_points','briefs'] loop
    begin
      execute format('alter publication supabase_realtime add table public.%I', t);
    exception when duplicate_object then null;
    end;
  end loop;
end $$;

-- ------------------------------------------------------------
-- La settimana dagli appunti condivisi
-- ------------------------------------------------------------
do $$
declare
  p uuid;
  s uuid;
  rec record;
  n  text;
begin
  select id into p from public.projects where name = 'Pilot';
  if p is null then return; end if;
  if exists (select 1 from public.project_slots where project_id = p and date = date '2026-09-05')
    then return; end if;

  update public.projects set ends_on = date '2026-09-05' where id = p;

  -- gli specialist con cui iniziare, aggiornati
  insert into public.project_items (project_id, kind, label, position, checked)
  select p, 'specialist', v.label, v.pos, true from (values
    ('Giulio', 14), ('Lovece', 15), ('Anisia', 16)
  ) as v(label, pos)
  where not exists (select 1 from public.project_items i
                    where i.project_id = p and i.kind = 'specialist' and i.label = v.label);
  update public.project_items set checked = true
    where project_id = p and kind = 'specialist' and label in ('Marwa', 'Matilde');

  -- i turni cambiati in corsa rispetto alla prima stesura
  update public.slot_people sp set person_name = 'Albert', person_id = (select id from public.people where name = 'Albert')
    from public.project_slots ps
   where sp.slot_id = ps.id and ps.project_id = p and ps.date = date '2026-08-27'
     and sp.role = 'Specialist' and sp.person_name = 'Ferrario';
  update public.slot_people sp set person_name = 'Mario', person_id = (select id from public.people where name = 'Mario')
    from public.project_slots ps
   where sp.slot_id = ps.id and ps.project_id = p and ps.date = date '2026-08-27'
     and sp.role = 'Point' and sp.person_name = 'Sofia';
  update public.slot_people sp set person_name = 'Matilde', person_id = (select id from public.people where name = 'Matilde')
    from public.project_slots ps
   where sp.slot_id = ps.id and ps.project_id = p and ps.date = date '2026-08-28'
     and sp.role = 'Specialist' and sp.person_name = 'Michele';
  update public.slot_people sp set person_name = 'Bandini', person_id = (select id from public.people where name = 'Bandini')
    from public.project_slots ps
   where sp.slot_id = ps.id and ps.project_id = p and ps.date = date '2026-08-29' and ps.start_time = '14:00'
     and sp.role = 'Point' and sp.person_name = 'Lupi';

  -- chi ha staffato brief e debrief della settimana passata
  for rec in select * from (values
    (date '2026-08-28', '16:00', 'Manu'),
    (date '2026-08-29', '14:00', 'Katia, Pirovano'),
    (date '2026-08-29', '16:00', 'Manu'),
    (date '2026-08-30', '14:00', 'Casati, Mike'),
    (date '2026-08-30', '16:00', 'Manu, Casati')
  ) as t(d, t1, staff)
  loop
    select id into s from public.project_slots where project_id = p and date = rec.d and start_time = rec.t1;
    if s is not null then
      insert into public.slot_people (slot_id, role, person_name, person_id, position)
      select s, 'Brief/Debrief', trim(x.nm),
             (select id from public.people pp where pp.name = trim(x.nm)), x.ord
      from unnest(string_to_array(rec.staff, ',')) with ordinality as x(nm, ord);
    end if;
  end loop;

  -- i turni della settimana nuova
  for rec in select * from (values
    (date '2026-08-31', '16:00', '18:00', 'Grattoni, Ricca',        'Grieco',        'Corraducci, Manu',  'Brief dopo il DD'),
    (date '2026-09-01', '16:00', '18:00', 'Grattoni, Campodipietra','Nikita',        'Mike, Macs',        ''),
    (date '2026-09-02', '16:15', '18:15', 'Lovece, Matilde',        'Demontis',      'Bandini, Angela',   'Brief 16:00-16:15 · debrief 18:15-18:30'),
    (date '2026-09-03', '16:00', '18:00', 'Campodipietra, Vezio',   'Sofia',         'Angela',            ''),
    (date '2026-09-04', '16:00', '18:00', 'Mario, Nico',            'Albert',        'Katia',             ''),
    (date '2026-09-05', '14:00', '16:00', 'Preziosi, Campodipietra','Mezzena',       '',                  'Brief e debrief da staffare'),
    (date '2026-09-05', '16:00', '18:00', 'Grattoni, Vezio',        'Arianna',       '',                  'Brief e debrief da staffare')
  ) as t(d, t1, t2, spec, point, bd, nota)
  loop
    insert into public.project_slots (project_id, date, start_time, end_time, note)
    values (p, rec.d, rec.t1, rec.t2, nullif(rec.nota, ''))
    returning id into s;

    insert into public.slot_people (slot_id, role, person_name, person_id, position)
    select s, r.role, trim(x.nm),
           (select pp.id from public.people pp where pp.name = trim(x.nm)), x.ord
    from (values ('Specialist', rec.spec), ('Point', rec.point), ('Brief/Debrief', rec.bd)) as r(role, list),
         lateral unnest(string_to_array(r.list, ',')) with ordinality as x(nm, ord)
    where trim(x.nm) <> '';
  end loop;
end $$;

-- ------------------------------------------------------------
-- I debrief dei gruppi della settimana 24-30/08, dagli appunti.
-- Ogni ✅ e ogni ❌ della nota diventa un punto del turno.
-- ------------------------------------------------------------
do $$
declare
  p uuid; s uuid; rec record;
begin
  select id into p from public.projects where name = 'Pilot';
  if p is null then return; end if;
  if exists (select 1 from public.shift_points limit 1) then return; end if;

  -- le demo davvero fatte in settimana, così le trovi fra le chip
  insert into public.project_items (project_id, kind, label, position)
  select p, 'demo', v.label, v.pos from (values
    ('Image Playground / Genmoji', 7),
    ('Memo vocali con trascrizione', 8),
    ('Modalità sport', 9),
    ('Cerca nella libreria', 10),
    ('Camera Control', 11)
  ) as v(label, pos)
  where not exists (select 1 from public.project_items i
                    where i.project_id = p and i.kind = 'demo' and i.label = v.label);

  -- il primo debrief seminato conteneva già due righe: ora vivono come punti
  update public.debriefs set worked = null, icebreaker = null
   where project_id = p and author_name = 'Nota condivisa';

  -- i numeri di ogni gruppo
  for rec in select * from (values
    (date '2026-08-25', '16:00', null::int, 2,    '["Image Playground / Genmoji"]'),
    (date '2026-08-27', '16:00', null::int, null::int, '["Note registrazione audio/strumenti di scrittura", "Cerca nelle app (screenshot)"]'),
    (date '2026-08-28', '16:00', null::int, 2,    '["Image Playground / Genmoji", "Intelligenza visiva"]'),
    (date '2026-08-29', '14:00', null::int, null::int, '["Doppia acquisizione"]'),
    (date '2026-08-29', '16:00', 20,        6,    '["Memo vocali con trascrizione", "Modalità sport", "Selfie inquadratura automatica Center Stage", "Ripulisci", "Cerca nella libreria", "Intelligenza visiva"]'),
    (date '2026-08-30', '14:00', 6,         4,    '["Intelligenza visiva", "Note registrazione audio/strumenti di scrittura"]'),
    (date '2026-08-30', '16:00', 20,        2,    '["Camera Control", "Intelligenza visiva", "Memo vocali con trascrizione"]')
  ) as t(d, t1, reached, conv, demos)
  loop
    select id into s from public.project_slots
      where project_id = p and date = rec.d and start_time = rec.t1;
    if s is not null then
      insert into public.debriefs (project_id, slot_id, author_name, reached, conversions, demos)
      values (p, s, 'Nota condivisa', rec.reached, rec.conv, rec.demos::jsonb);
    end if;
  end loop;

  -- i punti, uno per riga come sulla nota
  for rec in select * from (values
    (date '2026-08-24','16:00','good','Sorpresa da parte dei clienti, effetto wow'),
    (date '2026-08-24','16:00','good','Frase rompighiaccio di Vladi: "Hai già l''iPhone?"'),
    (date '2026-08-24','16:00','good','Frase rompighiaccio di Nico: "Vieni che ti faccio vedere una funzione"'),
    (date '2026-08-24','16:00','good','Demo sempre diverse'),
    (date '2026-08-24','16:00','good','Maggiore conversion quando c''era meno traffico'),
    (date '2026-08-24','16:00','good','Emma al Point ha sempre indirizzato le persone curiose al tavolo'),

    (date '2026-08-25','16:00','good','Coda in evidenza per non perdere il momento della decisione'),
    (date '2026-08-25','16:00','good','Usare i commenti nelle note con la demo già fatta, per non ripetersi'),
    (date '2026-08-25','16:00','good','Fare demo tra guida e host mentre non c''era nessuno ha funzionato'),
    (date '2026-08-25','16:00','good','Avere in mente tutte le demo da fare'),
    (date '2026-08-25','16:00','good','Partnership con il Point: code ai tavoli a fianco, così ascoltavano e si incuriosivano'),
    (date '2026-08-25','16:00','good','Lettura della stanza: oggi tante code e meno browser'),
    (date '2026-08-25','16:00','good','Demo efficace: Image Playground, Genmoji a tema compleanno per il compleanno del cliente, chiuso con acquisto'),
    (date '2026-08-25','16:00','bad','Non mettere clienti in attesa allo stesso tavolo'),

    (date '2026-08-26','16:00','good','Avvisare i team member che è live la staff demo'),
    (date '2026-08-26','16:00','good','Tavolo A2 molto più efficace e con più interesse'),
    (date '2026-08-26','16:00','good','Intercettare le persone'),
    (date '2026-08-26','16:00','bad','Parlare a ruota da soli porta a diventare un T@A'),
    (date '2026-08-26','16:00','bad','La guida non deve perdere il controllo sulla folla'),

    (date '2026-08-27','16:00','good','Usate demo condivise durante la settimana (es. note, mail creativa)'),
    (date '2026-08-27','16:00','good','A2 porta a parlare della promo Edu'),
    (date '2026-08-27','16:00','good','Il Point non ha fatto accomodare nessuno in attesa'),
    (date '2026-08-27','16:00','bad','È mancato il brief: niente preparazione, guida, why'),
    (date '2026-08-27','16:00','bad','I tavoli A intercettano il cliente assistenza'),
    (date '2026-08-27','16:00','bad','A4 è l''unico tavolo con tutti i colori degli iPhone: gli specialist ci portano i clienti durante la CJ'),
    (date '2026-08-27','16:00','bad','La guida finisce spesso per fare da point/filtro per i clienti intercettati'),
    (date '2026-08-27','16:00','bad','La guida non ha mai fatto CP: i ragazzi non sapevano di doverlo fare'),
    (date '2026-08-27','16:00','bad','Gran parte del team non è abituata al One To Many: serve formazione'),

    (date '2026-08-28','16:00','good','Nico, col tavolo vuoto, ha portato in A4 un cliente che guardava un iPhone al tavolo accanto'),
    (date '2026-08-28','16:00','good','Image Playground e intelligenza visiva sempre effetto wow: poi i clienti le rifacevano insieme'),
    (date '2026-08-28','16:00','good','Intesa tra guida e host: one to few riuscito, si coinvolgevano altre persone'),
    (date '2026-08-28','16:00','bad','Mancata valorizzazione delle due ore'),
    (date '2026-08-28','16:00','bad','Team che non conosce il pilot e prende l''attività con poca serietà'),

    (date '2026-08-29','14:00','good','Complicità nella coppia: si sono divertiti'),
    (date '2026-08-29','14:00','good','Posizionare il cliente rispetto a quello che accadeva al tavolo'),
    (date '2026-08-29','14:00','good','La guida ha ingaggiato le persone intorno per farle assistere alle demo'),
    (date '2026-08-29','14:00','good','Nel fine settimana meglio A4 che A2: all''ingresso c''è sovraffollamento'),
    (date '2026-08-29','14:00','good','Frase rompighiaccio: "Se vuoi guardiamo le differenze tra il tuo iPhone e questo"'),
    (date '2026-08-29','14:00','good','Attenzione ai dettagli: cover dell''Inter, "vai spesso allo stadio? hai visto la doppia acquisizione?" Effetto wow'),
    (date '2026-08-29','14:00','good','Complicità nel fare C&P in modo naturale'),
    (date '2026-08-29','14:00','good','Il Point ha posizionato bene le persone: in A5 chi aspettava ascoltava'),
    (date '2026-08-29','14:00','good','Spegnere il microfono quando l''interazione diventa più personale'),
    (date '2026-08-29','14:00','good','5 handoff diretti e 2 session recap'),
    (date '2026-08-29','14:00','good','Demo efficace: doppia acquisizione, lo stadio'),
    (date '2026-08-29','14:00','bad','Point davanti alle scale poco visibile: i clienti andavano diretti in A2 a chiedere'),
    (date '2026-08-29','14:00','bad','Il manager in divisa diventa un point e inibisce'),
    (date '2026-08-29','14:00','bad','Interazioni allo stesso tavolo'),
    (date '2026-08-29','14:00','bad','FWE che andavano a chiedere aiuto a guida e host'),
    (date '2026-08-29','14:00','bad','Non avere presenti i prodotti non in stock'),

    (date '2026-08-29','16:00','good','Portare le persone: "siamo qui per guardare" → "allora ti facciamo vedere cosa puoi fare"'),
    (date '2026-08-29','16:00','good','Parallelismo con l''iPhone che avevano, con demo sempre diverse'),
    (date '2026-08-29','16:00','bad','Mancata presentazione'),
    (date '2026-08-29','16:00','bad','Demo non interattive: far fare'),
    (date '2026-08-29','16:00','bad','Focalizzarsi troppo su un cliente solo'),
    (date '2026-08-29','16:00','bad','Cassa vicina invece che dalla parte opposta'),
    (date '2026-08-29','16:00','bad','Connetti e personalizza stoppa il flow: trovare il momento giusto'),

    (date '2026-08-30','14:00','good','Coinvolte 6 persone'),
    (date '2026-08-30','14:00','good','Frase di ingaggio: "Avvicinatevi, venite"'),
    (date '2026-08-30','14:00','good','Demo efficace: Visual Intelligence sul modello di scarpe del cliente, come cercarlo su internet'),
    (date '2026-08-30','14:00','good','Demo efficace: strumenti di scrittura, creazione di una tabella'),
    (date '2026-08-30','14:00','bad','Posizione A2 non adatta: meglio B2 o A4'),
    (date '2026-08-30','14:00','bad','Difficoltà a interagire'),
    (date '2026-08-30','14:00','bad','Clienti timidi: seguivano le demo da tavoli diversi'),
    (date '2026-08-30','14:00','bad','Il rumore ha avuto un impatto negativo'),

    (date '2026-08-30','16:00','good','Interazione con tante persone, circa 20'),
    (date '2026-08-30','16:00','good','Ottimo lavoro di squadra'),
    (date '2026-08-30','16:00','good','Ingaggio funzionante: avvisare che parte una demo e iniziarla con la guida, poi incuriosire le persone'),
    (date '2026-08-30','16:00','good','Frase di ingaggio: "Che dispositivo utilizzi?"'),
    (date '2026-08-30','16:00','good','Demo in inglese per un cliente internazionale'),
    (date '2026-08-30','16:00','good','Proposti servizi: aziendali e Creator Studio'),
    (date '2026-08-30','16:00','good','Fatte scoprire funzionalità a clienti che già avevano il prodotto'),
    (date '2026-08-30','16:00','good','Demo funzionanti: tante app aperte su Neo; Camera Control e visual intelligence su Bose e su screenshot; trascrizione audio'),
    (date '2026-08-30','16:00','bad','Poche conversion: 2 persone'),
    (date '2026-08-30','16:00','bad','Aver preferito il tavolo continuity'),
    (date '2026-08-30','16:00','bad','Il microfono spaventa alcuni clienti: partire spento e attivarlo dopo')
  ) as t(d, t1, kind, txt)
  loop
    select id into s from public.project_slots
      where project_id = p and date = rec.d and start_time = rec.t1;
    if s is not null then
      insert into public.shift_points (slot_id, kind, text, actor_name)
      values (s, rec.kind, rec.txt, 'Nota condivisa');
    end if;
  end loop;
end $$;
