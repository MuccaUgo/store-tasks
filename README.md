# Store Tasks

Web app mobile-first per gestire le attività dello store in team (~12 persone):

- **DD (Daily Download)** — calendario dei prossimi giorni con argomento
  (Business/Support/Product/Creative/Fun); il team gestisce i **Product**:
  chi prepara, chi lo facilita — con una seconda persona facoltativa, che
  si aggiunge col **+** — e caricato sì/no. Sotto ogni DD si possono
  lasciare **commenti**
- **Focus** — i focus di store con gli aggiornamenti nel tempo. Dentro un
  focus si può aprire una **proposta**: si vota col nome (👍/👎, il voto si
  cambia e si ritira) e si commenta. Non serve un quorum: chiunque la chiude
  con **Decidi**, e diventa una **decisione** con l'esito. Una decisione si
  può sempre riportare a proposta — voti e commenti restano
- **Progetti** — ogni progetto è un tab a sé. Il primo è **Pilot** (Live
  Group Demo Pilot). L'unità di lavoro è il **gruppo** che copre un turno:
  in cima al tab ci sono **Brief** e **Debrief**, e agiscono sul gruppo di
  oggi. Il debrief chiede due numeri (connessioni e conversion), due liste
  che si scrivono una riga alla volta (cose positive e sfide) e due campi
  liberi (demo interattive più riuscite, frasi più riuscite). Le righe
  restano come punti del turno, aggiungibili anche dopo. La vista
  **Spunti** raccoglie tutto quanto, più gli spunti liberi
- **Team** — chi usa l'app
- **Storico** — registro di chi ha fatto cosa

La validazione degli FWE non è più gestita qui: il tab è stato tolto.
Le tabelle (`fwe`, `competencies`, `fwe_events`) restano nel database, così
il lavoro fatto non si perde e la sezione si può riaccendere.

Frontend statico (GitHub Pages) + database e login su Supabase (piano gratuito).

## Setup (una volta sola)

### 1. Database
Nel progetto Supabase → **SQL Editor** → incolla il contenuto di
`supabase-setup.sql` → **Run**, poi le migrazioni in ordine
(`migration-2.sql` … `migration-13.sql`) allo stesso modo.

Ogni migrazione si può rieseguire senza danni. L'app si accorge da sola di
cosa manca e nasconde solo quel pezzo: finché `migration-6.sql` non gira i
tab dei progetti non compaiono, finché non gira `migration-11.sql` nel Focus
non c'è il bottone «+ Proposta», e senza `migration-12.sql` e
`migration-13.sql` il DD resta senza seconda persona e senza commenti.
Il resto funziona come prima.
`migration-10.sql` è facoltativa.

### 2. Utente condiviso
L'utente condiviso è `marcocasati+storetasks@gmail.com` (alias Gmail del
proprietario: le email di sistema arrivano a lui). La sua password è la
password del team. Nota: Supabase rifiuta email con domini inesistenti,
quindi serve un dominio reale.

### 3. Pubblicazione su GitHub Pages
1. Crea un repository su GitHub (es. `store-tasks`) e carica questi file.
2. Repository → **Settings → Pages** → Source: `main` branch, cartella `/ (root)`.
3. Dopo ~1 minuto l'app è su `https://<tuo-utente>.github.io/store-tasks/`.

### 4. Su iPhone
Apri l'URL in Safari → **Condividi → Aggiungi a schermata Home**.
L'app appare come un'icona e si apre a schermo intero.

## Sicurezza

- La password non è nel codice: viene verificata da Supabase Auth.
- Tutte le tabelle hanno Row Level Security: senza login non si legge né scrive nulla.
- Lo storico attività è solo-aggiunta: nessun utente può modificarlo o cancellarlo.
- Percorso di upgrade previsto: account individuali (email/magic link), ruoli admin, 2FA.

## Configurazione

URL e chiave pubblica Supabase sono in cima allo `<script>` di `index.html`
(`SUPABASE_URL`, `SUPABASE_KEY`, `SHARED_EMAIL`). La chiave `anon/publishable`
è pensata per essere pubblica: i permessi reali li decide la Row Level Security.
