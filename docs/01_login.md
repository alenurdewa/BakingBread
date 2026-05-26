# login.jsp

## Descrizione
Pagina di accesso all'applicazione. È la prima pagina che vede un utente non autenticato.

## Funzionamento passo per passo

### 1. Controllo sessione esistente
All'inizio della pagina viene letto l'attributo `id_utente` dalla sessione HTTP.
Se è già presente, l'utente è già loggato e viene reindirizzato direttamente a `home.jsp`.
```java
Integer idUtenteLoggato = (Integer) session.getAttribute("id_utente");
if (idUtenteLoggato != null) { response.sendRedirect("home.jsp"); }
```

### 2. GET — Mostra il form
Se la richiesta è di tipo GET, viene mostrato il form HTML con due campi: `username` e `password`.

### 3. POST — Elabora il login
Quando l'utente clicca "Accedi", il browser invia una richiesta POST. La pagina:
1. Legge `username` e `password` dai parametri della richiesta.
2. Valida che i campi non siano vuoti.
3. Apre una connessione al database tramite `Db.getConnection()`.
4. Esegue una query `SELECT` per trovare l'utente per username.
5. Se trovato, estrae il `password_hash` dal DB.
6. Ricalcola l'hash SHA-256 con il salt estratto e confronta.
7. Se la password è corretta, crea la sessione e reindirizza a `home.jsp`.

### Algoritmo di verifica password
Il formato nel DB è: `SALT (32 char hex) + HASH (64 char hex)` = 96 caratteri totali.
```
storedHash.substring(0, 32) → salt in hex → decodificato in 16 byte
MessageDigest.update(saltBytes) → digest(password.getBytes("UTF-8")) → confronta con storedHash.substring(32)
```

## Parametri ricevuti (POST)
| Campo | Tipo | Obbligatorio | Descrizione |
|-------|------|:---:|-------------|
| `username` | String | ✓ | Nome utente |
| `password` | String | ✓ | Password in chiaro |

## Gestione sessione
In caso di login corretto, vengono impostati:
```java
session.setAttribute("id_utente",   idUtente);
session.setAttribute("username",    dbUsername);
session.setAttribute("nome_utente", nomeVisualizzato);
session.setAttribute("avatar_url",  avatarUrl);
```

## Interazione con classi Java
- **`Db.getConnection()`** — apre la connessione al database MySQL

## File collegati
- `login.js` — gestisce il toggle mostra/nascondi password
- `css/global.css` + `css/auth.css` — stili della pagina
