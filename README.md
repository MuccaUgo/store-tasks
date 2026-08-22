# Store Tasks

Web app mobile-first per gestire le attività dello store in team (~12 persone):

- **Download** — presentazioni: chi le prepara, se sono caricate, chi le presenta
- **FWE** — nuovi arrivati: checklist di competenze da validare, con firma e data
- **Team** — gestione persone e competenze
- **Storico** — registro di chi ha fatto cosa

Frontend statico (GitHub Pages) + database e login su Supabase (piano gratuito).

## Setup (una volta sola)

### 1. Database
Nel progetto Supabase → **SQL Editor** → incolla il contenuto di
`supabase-setup.sql` → **Run**.

### 2. Utente condiviso
Supabase → **Authentication → Users → Add user → Create new user**:

- Email: `team@store-tasks.app`
- Password: la password del team (quella che i colleghi useranno per entrare)
- Spunta **Auto Confirm User**

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
