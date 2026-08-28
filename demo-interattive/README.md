# Demo Interattive

Il catalogo delle demo da fare in store: che cosa mostrare, a chi, con quale
frase si apre e quali sono i passi. E il registro di quelle che vengono fatte
davvero, per sapere quali vivono in reparto e quali restano solo scritte.

Sito a sé, database a sé. Sta accanto a **Store Tasks**, non dentro.

## Come è fatto

- **Catalogo** — le demo raggruppate per prodotto, con ricerca e filtri.
  Ogni scheda si apre e mostra i passi numerati, il momento che fa effetto,
  cosa serve prima di iniziare. Le demo **in evidenza** (la stella) stanno
  in cima: sono quelle che stiamo spingendo adesso.
- **“L'ho fatta”** — un tocco a fine demo: com'è andata (wow · ok · fiacca)
  e una riga di commento. È in sola aggiunta: una demo fatta non si cancella.
- **Uso** — quante sono pronte, quante fatte negli ultimi 30 giorni, quali
  non è mai uscita dal catalogo, e chi le porta in reparto.
- **Storico** — il registro giorno per giorno.

Le schede si scrivono e si correggono dall'app: chi scopre un passaggio
migliore lo cambia lì, e lo vedono tutti.

## Setup

### 1. Database
Nel progetto Supabase → **SQL Editor** → incolla `schema.sql` → **Run**.
Si può rieseguire senza danni. Il primo giro inserisce dieci demo di
partenza; da lì in poi il catalogo lo scrive il team.

### 2. Login
Stesso utente condiviso e stessa password del team di Store Tasks. Il nome
di chi usa l'app si sceglie al primo avvio e resta sul telefono.

### 3. Pubblicazione su GitHub Pages
Repository → **Settings → Pages** → Source: `main`, cartella `/ (root)`.
Dopo circa un minuto il sito è online.

### 4. Su iPhone
Apri l'URL in Safari → **Condividi → Aggiungi a schermata Home**.

## Configurazione

URL e chiave pubblica Supabase sono in cima allo `<script>` di `index.html`
(`SUPABASE_URL`, `SUPABASE_KEY`, `SHARED_EMAIL`). La chiave `anon/publishable`
è pensata per essere pubblica: i permessi reali li decide la Row Level Security.

## Sicurezza

- La password non è nel codice: la verifica Supabase Auth.
- Row Level Security su entrambe le tabelle: senza login non si legge nulla.
- Il registro delle demo fatte è solo-aggiunta: nessuno può riscriverlo.
