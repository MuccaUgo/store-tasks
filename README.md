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
- **Storico** — registro di chi ha fatto cosa, con il **codice QR**
  dell'app da far inquadrare a chi la deve installare

La validazione degli FWE non è più gestita qui: il tab è stato tolto.
Le tabelle (`fwe`, `competencies`, `fwe_events`) restano nel database, così
il lavoro fatto non si perde e la sezione si può riaccendere.

Frontend statico (GitHub Pages) + database e login su Supabase (piano gratuito).

### PLGame, il gioco (prototipo)
In `plgame/index.html` c'è la simulazione in pixel art dello store di
Piazza Liberty, vista dall'alto. Tavoli: iPhone da A2 ad A5 e in B4–B5, iPad
in A1 e B2, Watch in B3 e C3, Mac in C2 e C4, cassa Express in B1; C1 e C5
sono liberi per aiutare i clienti con una domanda veloce. Chi entra dalla porta in alto a destra si
mette in fila dal **Point** e dice cosa cerca: acquisto (tavoli iPhone,
iPad/Watch, Mac, dove poi arriva uno Specialist), assistenza (il secondo
Point, sopra il primo tavolo del Genius Bar, fa il check-in e accompagna al
posto), accessori (alle pareti, con uno Specialist per lato; chi sa già
cosa vuole paga alla cassa Express in B1) o solo un'occhiata. I tavoli si
chiamano A1–A5, B1–B5, C1–C5 contando da destra, e D2–D4 per il Genius Bar
(i nomi non sono scritti, si vedono toccando il tavolo).

Ogni giorno si apre con l'**Apertura**: scegli l'argomento del **DD del
mattino** (Product, Support, Business, Creative, Fun, ognuno con un effetto
sulla giornata) e chi lo facilita, e decidi il **piano dei ruoli**: chi va
al Point, all'Express, agli accessori e al Point del Genius Bar. A ogni
cambio ruoli il gioco propone la rotazione e tu puoi cambiarla. Come una
squadra di calcio scegli anche la **formazione** del floor (Accoglienza,
Tavoli, Essenziale), perché non sempre ci sono tutti: qualcuno è in ferie,
qualcuno in malattia, e qualcuno può sentirsi male durante la giornata.
Allora decidi se coprire il suo posto, cambiare formazione o chiedere alla
squadra di andare più veloce per due ore, con più stress.
Ognuno nel team ha motivazione (velocità), stress (esperienza del cliente)
e competenza (errori e attach); con troppo stress il giorno dopo si è in
malattia. La squadra è di 43 persone, tutte full time: in vendita 12 Specialist,
6 Expert e 3 Pro; al Genius Bar 10 Technical Specialist, 5 Technical Expert
e 2 Genius; al Today at Apple 3 Creative e 2 Creative Pro. Ognuno ha due
giorni liberi in settimana, nel weekend lavorano tutti (il sabato è il
giorno più pieno). I livelli più alti arrivano a più competenza, vendono o
riparano meglio e reggono meglio lo stress; al Genius Bar le riparazioni
sono rapide, medie o complesse, e il Point lo fanno i Technical Specialist.
I Creative tengono le lezioni a turno, convincono qualche partecipante a
comprare e nel tempo libero aiutano agli accessori.
Il team parte poco competente e cresce col tempo. Ogni 1–2 ore i ruoli
ruotano (chi era in vendita va a Point, Express o accessori, e viceversa);
Point ed Express stressano di più. Durante la giornata si può mandare
qualcuno in **pausa** 15 minuti o fargli i **complimenti** (3 al giorno).
Ogni cliente che vuole comprare ha un bisogno nascosto: più il team è
competente, più spesso emerge e porta alla proposta e all'accessorio giusti.
Quando sul floor succede qualcosa di importante (qualcuno è al limite, una
grande vendita, un errore serio) il gioco si ferma su un **momento da
leader**: scegli come intervenire e vedi l'effetto su persone e clienti.
All'apertura entrano 5–10 clienti che aspettavano fuori, e alcuni clienti
sono scortesi e alzano lo stress di chi li serve. Alcuni clienti
lasciano un commento da 1 a 5: 5 vale +1, 4 vale 0, da 3 a 1 vale −1, e
l'NPS è la somma diviso il numero di commenti, per 100, diviso anche tra
Vendita e Genius Bar (un team formato e ben gestito sta intorno a 80, come
la media di Piazza Liberty). A 1× una giornata dura circa 7 minuti. Il Today at Apple per ora è sfondo: chi guarda a
volte si ferma lì. A fine giornata c'è il debrief.
È un file solo, senza dipendenze: si apre com'è, anche da GitHub Pages
(`…/plgame/`). Non tocca il database.

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
