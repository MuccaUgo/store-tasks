-- ============================================================
-- Demo Interattive — schema del catalogo
-- Incolla nello SQL Editor del progetto Supabase ed esegui.
-- Si può rieseguire senza danni: crea solo quello che manca.
-- Non tocca le tabelle di Store Tasks.
-- ============================================================

-- Una demo = una scheda del catalogo: cosa mostrare, a chi, e come.
-- I passi stanno in jsonb perché si scrivono e si leggono sempre insieme.
create table if not exists public.demos (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null default 'iPhone',   -- iPhone · iPad · Mac · Watch · Audio · Servizi · Altro
  hook text,                                 -- la frase con cui si apre
  who text,                                  -- a quale cliente sta bene
  duration text not null default 'breve',    -- lampo · breve · completa
  level text not null default 'facile',      -- facile · media · avanzata
  steps jsonb not null default '[]'::jsonb,  -- i passi, in ordine
  needs text,                                -- cosa serve prima di iniziare
  wow text,                                  -- il momento che fa effetto
  owner text,                                -- chi tiene aggiornata la scheda
  status text not null default 'bozza',      -- bozza · pronta · ritirata
  featured boolean not null default false,   -- la demo che spingiamo adesso
  position int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists demos_lookup on public.demos (status, category, position);

-- Ogni volta che una demo viene fatta davvero in reparto.
-- In sola aggiunta: è il registro che dice quali demo vivono
-- sul pavimento del negozio e quali restano solo scritte.
create table if not exists public.demo_runs (
  id bigint generated always as identity primary key,
  demo_id uuid not null references public.demos(id) on delete cascade,
  actor_name text not null,
  outcome text not null default 'ok',        -- wow · ok · fiacca
  note text,
  created_at timestamptz not null default now()
);
create index if not exists demo_runs_lookup on public.demo_runs (demo_id, created_at);

-- ------------------------------------------------------------
-- Accesso: si legge e si scrive solo dopo il login
-- ------------------------------------------------------------
alter table public.demos     enable row level security;
alter table public.demo_runs enable row level security;

drop policy if exists "demos all"   on public.demos;
drop policy if exists "runs read"   on public.demo_runs;
drop policy if exists "runs insert" on public.demo_runs;

create policy "demos all"   on public.demos
  for all to authenticated using (true) with check (true);
create policy "runs read"   on public.demo_runs
  for select to authenticated using (true);
create policy "runs insert" on public.demo_runs
  for insert to authenticated with check (true);
-- volutamente nessuna policy di update o delete: una demo fatta resta

-- ------------------------------------------------------------
-- Aggiornamenti in tempo reale sugli altri telefoni
-- ------------------------------------------------------------
do $$
begin
  alter publication supabase_realtime add table public.demos;
exception when duplicate_object then null;
end $$;
do $$
begin
  alter publication supabase_realtime add table public.demo_runs;
exception when duplicate_object then null;
end $$;

-- ------------------------------------------------------------
-- Il catalogo di partenza. Si riscrive tutto dall'app:
-- serve solo a non aprire il sito su una pagina vuota.
-- ------------------------------------------------------------
do $$
begin
  if exists (select 1 from public.demos) then return; end if;

  insert into public.demos
    (name, category, hook, who, duration, level, steps, needs, wow, status, featured, position)
  values
  ('Intelligenza visiva', 'iPhone',
   'Hai già l''iPhone? Guarda cosa fa la fotocamera adesso.',
   'Chi entra a curiosare, anche senza un modello in mente',
   'lampo', 'facile',
   to_jsonb(array[
     'Tieni premuto il tasto Controllo fotocamera',
     'Inquadra un oggetto del reparto e chiedi che cos''è',
     'Tocca Cerca per trovarlo online in un secondo',
     'Ripeti su un testo: traduzione immediata'
   ]),
   'iPhone con Apple Intelligence attiva e connessione',
   'Il telefono riconosce quello che stai guardando: nessuno se lo aspetta',
   'pronta', true, 1),

  ('Doppia acquisizione', 'iPhone',
   'Ti faccio vedere come si riprende una scena e la faccia di chi la guarda.',
   'Genitori, chi viaggia, chi fa video per i social',
   'breve', 'facile',
   to_jsonb(array[
     'Apri Fotocamera e passa a Video',
     'Attiva la doppia registrazione',
     'Riprendi il cliente mentre inquadra qualcosa dietro di sé',
     'Riguarda subito il video con le due immagini insieme'
   ]),
   'iPhone con doppia acquisizione, spazio libero per registrare',
   'Si rivede nel video insieme a quello che stava guardando',
   'pronta', false, 2),

  ('Selfie con inquadratura automatica', 'iPhone',
   'Fai una foto a tutto il gruppo senza chiedere a nessuno di stringersi.',
   'Famiglie, coppie, gruppi di amici',
   'lampo', 'facile',
   to_jsonb(array[
     'Apri Fotocamera e passa alla frontale',
     'Scatta con una persona, poi fatti raggiungere da un''altra',
     'Mostra l''inquadratura che si allarga da sola',
     'Ruota l''iPhone: la foto resta dritta'
   ]),
   'iPhone con fotocamera frontale a inquadratura automatica',
   'La foto si allarga da sola quando arriva qualcun altro',
   'pronta', false, 3),

  ('Ripulisci in Foto', 'iPhone',
   'Hai una foto rovinata da qualcuno che passava? Provala qui.',
   'Chi è appena tornato da un viaggio, chi mostra le foto dei figli',
   'breve', 'facile',
   to_jsonb(array[
     'Apri una foto con un elemento di troppo sullo sfondo',
     'Tocca Modifica, poi Ripulisci',
     'Passa il dito sull''elemento da togliere',
     'Confronta prima e dopo tenendo premuto sulla foto'
   ]),
   'Una foto di prova già pronta sul dispositivo',
   'Il prima/dopo tenendo premuto: è lì che si sente il wow',
   'pronta', false, 4),

  ('Note: registra e riassumi', 'iPhone',
   'Quante volte prendi appunti mentre qualcuno parla?',
   'Studenti, chi passa la giornata in riunione',
   'breve', 'media',
   to_jsonb(array[
     'Apri Note e crea una nota nuova',
     'Avvia la registrazione e fai parlare il cliente per trenta secondi',
     'Mostra la trascrizione che compare mentre parla',
     'Chiedi il riassunto e leggilo insieme a lui'
   ]),
   'iPhone con Apple Intelligence in italiano, angolo non troppo rumoroso',
   'Sente la propria voce diventare testo e poi riassunto',
   'pronta', false, 5),

  ('Cerca nelle foto: gli screenshot', 'iPhone',
   'Quanti screenshot hai nel rullino? Proviamo a trovarne uno.',
   'Chi ha il telefono pieno e non trova mai niente',
   'lampo', 'facile',
   to_jsonb(array[
     'Apri Foto e vai su Cerca',
     'Scrivi una parola che sta dentro uno screenshot',
     'Mostra il risultato: cerca anche il testo nelle immagini',
     'Ripeti con una parola scelta dal cliente'
   ]),
   'Un dispositivo demo con qualche screenshot di prova',
   'Trova il testo dentro le immagini, non solo il nome del file',
   'pronta', false, 6),

  ('Matematica in Note con Apple Pencil', 'iPad',
   'Scrivi un conto a mano e guarda cosa succede.',
   'Studenti, genitori che comprano per la scuola',
   'breve', 'media',
   to_jsonb(array[
     'Apri Note su iPad con Apple Pencil',
     'Scrivi a mano un''espressione e chiudila con l''uguale',
     'Il risultato compare con la tua calligrafia',
     'Cambia un numero: il risultato si aggiorna da solo'
   ]),
   'iPad con Apple Pencil abbinata e carica',
   'La calligrafia del cliente che si completa da sola',
   'pronta', false, 7),

  ('iPhone sul Mac', 'Mac',
   'Ti serve una cosa che hai sul telefono mentre lavori al Mac?',
   'Chi valuta un Mac e ha già un iPhone',
   'breve', 'media',
   to_jsonb(array[
     'Apri iPhone Mirroring sul Mac',
     'Mostra il telefono che compare sullo schermo',
     'Apri un''app dal Mac usando trackpad e tastiera',
     'Trascina un file tra i due dispositivi'
   ]),
   'Mac e iPhone con lo stesso ID Apple sulla stessa rete',
   'Usa il telefono dal Mac senza toccarlo: la continuità si vede',
   'pronta', false, 8),

  ('Doppio tocco su Apple Watch', 'Watch',
   'Hai le mani occupate? Guarda come si risponde così.',
   'Chi corre, chi ha bambini in braccio, chi cucina',
   'lampo', 'facile',
   to_jsonb(array[
     'Fai indossare l''Apple Watch al cliente',
     'Mostra il doppio tocco di indice e pollice',
     'Rispondi a una notifica senza usare l''altra mano',
     'Scorri la Vista Smart con lo stesso gesto'
   ]),
   'Apple Watch con doppio tocco, allacciato al polso del cliente',
   'Comanda l''orologio senza toccarlo',
   'pronta', false, 9),

  ('Cancellazione del rumore in reparto', 'Audio',
   'Senti quanto è rumoroso qui? Prova a spegnerlo.',
   'Chiunque passi vicino al banco degli accessori',
   'lampo', 'facile',
   to_jsonb(array[
     'Fai indossare gli AirPods al cliente',
     'Parti in modalità Trasparenza, con il rumore del negozio',
     'Passa alla cancellazione del rumore e stai zitto tre secondi',
     'Torna in Trasparenza e fai sentire la differenza'
   ]),
   'AirPods carichi e igienizzati, abbinati a un dispositivo demo',
   'I tre secondi di silenzio in mezzo al negozio',
   'pronta', false, 10);
end $$;
