# Store Tasks

Web app mobile-first per gestire le attività dello store in team (~12 persone):

- **DD (Daily Download)** — calendario dei prossimi giorni con argomento
  (Business/Support/Product/Creative/Fun); il team gestisce i **Product**:
  chi prepara, caricato sì/no, chi presenta, presentato sì/no
- **Validation** — FWE (nuovi arrivati, senza accesso all'app): checklist di
  competenze da validare (Competenze operative, Approccio, Demo, Business),
  con firma di chi valida e data
- **Team** — gestione persone e competenze
- **Storico** — registro di chi ha fatto cosa

Dati iniziali: 10 utenti del team e 30 FWE (cognomi di prova), DD dei
prossimi 14 giorni con argomenti casuali.

Frontend statico (GitHub Pages) + database e login su Supabase (piano gratuito).

## Setup (una volta sola)

### 1. Database
Nel progetto Supabase → **SQL Editor** → incolla il contenuto di
`supabase-setup.sql` → **Run**.

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
