# 03 – `logout.jsp` — Spiegazione riga per riga

## Scopo del file
Termina la sessione dell'utente loggato, invalida il cookie "Ricordami" (sia lato browser che lato database) e reindirizza al login.

---

## Analisi riga per riga

### Direttive

```jsp
<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*" %>
```

Importa solo `java.sql.*` perché l'unica operazione database è una DELETE del token di sessione.

---

### Anti-cache

```jsp
    response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);
```

Critico per il logout: senza questi header, il browser potrebbe mettere in cache la richiesta di logout e non eseguirla effettivamente la volta successiva.

---

### Recupero ID utente dalla sessione

```jsp
    Integer idUtente = (Integer) session.getAttribute("id_utente");
```

Legge l'ID dell'utente prima di invalidare la sessione (dopo `session.invalidate()` la sessione non esiste più e non si può leggere nulla da essa).

---

### Invalidazione del token "Ricordami" nel database

```jsp
    if (idUtente != null) {
        try {
            Cookie[] cookies = request.getCookies();
            if (cookies != null) {
                for (Cookie c : cookies) {
                    if ("remember_token".equals(c.getName())) {
                        String token = c.getValue();
```

Scorre i cookie inviati dal browser cercando `remember_token`. Questo blocco viene eseguito solo se l'utente era loggato (`idUtente != null`).

```jsp
                        Class.forName("com.mysql.cj.jdbc.Driver");
                        java.sql.Connection conn = DriverManager.getConnection(
                            "jdbc:mysql://localhost:3306/bakingbread?useSSL=false", "root", "");
                        PreparedStatement ps = conn.prepareStatement(
                            "DELETE FROM SessioneToken WHERE id_utente = ? AND token = ?");
                        ps.setInt(1, idUtente);
                        ps.setString(2, token);
                        ps.executeUpdate();
                        ps.close();
                        conn.close();
```

Elimina il token dal database. La combinazione `id_utente AND token` è più sicura del solo token: anche se qualcuno avesse il valore del token, non potrebbe eliminare token di altri utenti.

Nota: `java.sql.Connection` invece di solo `Connection` perché in questo scope non è stato importato il tipo con `import java.sql.Connection` (è accessibile perché è importato `java.sql.*` nella direttiva, ma scritto per chiarezza).

```jsp
                    }
                }
            }
        } catch (Exception e) {
            // ignora errori durante logout
        }
    }
```

Qualsiasi errore viene silenziosamente ignorato. Il logout deve sempre riuscire dal punto di vista dell'utente, anche se c'è un problema con il database.

---

### Eliminazione cookie lato browser

```jsp
    Cookie rememberCookie = new Cookie("remember_token", "");
    rememberCookie.setMaxAge(0);
    rememberCookie.setPath("/");
    rememberCookie.setHttpOnly(true);
    response.addCookie(rememberCookie);
```

Per eliminare un cookie HTTP si invia lo stesso cookie con:
- **Valore vuoto** `""`
- **`setMaxAge(0)`** → MaxAge=0 dice al browser di eliminare immediatamente il cookie

`setPath("/")` deve corrispondere esattamente al path usato quando il cookie è stato creato, altrimenti il browser non lo associa allo stesso cookie.

---

### Invalidazione della sessione

```jsp
    session.invalidate();
```

Questo è il passo più importante. `session.invalidate()`:
1. Elimina tutti gli attributi della sessione (`id_utente`, `nome_utente`, `username`, ecc.)
2. Invalida l'ID di sessione (il cookie `JSESSIONID` non sarà più riconosciuto dal server)
3. Il browser continuerà ad inviare `JSESSIONID` nelle richieste successive, ma il server lo ignorerà e creerà una nuova sessione vuota

---

### Redirect al login

```jsp
    response.sendRedirect("login.jsp");
```

Reindirizza l'utente alla pagina di login. Il browser seguirà il redirect con una nuova richiesta GET. A questo punto la sessione è invalidata, il cookie eliminato e il token rimosso dal database: il logout è completo.

---

## Flusso completo logout.jsp

```
GET/POST /logout.jsp
├── Legge id_utente dalla sessione (prima di invalidarla)
├── Se utente era loggato:
│   ├── Cerca cookie "remember_token"
│   └── Se trovato:
│       ├── DELETE FROM SessioneToken WHERE id_utente=? AND token=?
│       └── (ignora errori database)
├── Invia cookie "remember_token" vuoto con MaxAge=0 (elimina il cookie)
├── session.invalidate() ← elimina la sessione HTTP
└── redirect → login.jsp
```

## Sicurezza

Il logout è corretto perché:
1. **Invalida la sessione server-side** (non basta cancellare il cookie JSESSIONID lato client)
2. **Rimuove il token dal database** (anche se qualcuno avesse intercettato il cookie "ricordami", non funzionerà più)
3. **Cancella il cookie browser** (pulizia lato client)

Un logout che fa solo `session.invalidate()` senza rimuovere il token dal DB sarebbe incompleto: l'utente potrebbe riloggarsi automaticamente alla prossima visita grazie al cookie "ricordami".
