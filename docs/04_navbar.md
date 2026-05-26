# navbar.jsp

## Descrizione
Barra di navigazione inclusa in tutte le pagine tramite `<jsp:include page="navbar.jsp" />`. Non è una pagina autonoma.

## Funzionamento passo per passo

### 1. Legge i dati dalla sessione
```java
Integer idUtenteLoggato = (Integer) session.getAttribute("id_utente");
String  nomeUtente      = (String)  session.getAttribute("nome_utente");
String  usernameLoggato = (String)  session.getAttribute("username");
String  avatarLoggato   = (String)  session.getAttribute("avatar_url");
```

### 2. Se l'utente è loggato, carica dati freschi dal DB
Apre una connessione e fa due query:
- Recupera nome, username, avatar aggiornati dalla tabella `Utente`
- Conta i messaggi non letti: `SELECT COUNT(*) FROM Messaggio WHERE destinatario_id = ? AND letto = FALSE`

### 3. Calcola la lettera iniziale
Se l'utente non ha un avatar, si usa la prima lettera del nome come fallback visivo.

### 4. Renderizza l'HTML
La navbar contiene:
- Logo + nome app (link a home.jsp)
- Barra di ricerca (form GET verso home.jsp?cerca=...)
- Se loggato: link "+ Ricetta", icona messaggi con badge, menu a tendina con avatar
- Se non loggato: link "Accedi" e "Registrati"

## Parametri ricevuti
Nessuno in input diretto. Legge dalla sessione.

## Gestione sessione
Solo lettura. Non modifica attributi di sessione.

## Interazione con classi Java
- **`Db.getConnection()`** — per caricare dati aggiornati
- **`UrlUtils.risolvi(ctx, avatarLoggato)`** — per costruire l'URL completo dell'avatar

## File collegati
- `main.js` — gestisce l'apertura/chiusura del menu a tendina
