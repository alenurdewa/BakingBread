# 06 – `profile.jsp` — Spiegazione riga per riga

## Scopo del file
Mostra il profilo pubblico di un utente: foto, nome, bio, statistiche (ricette/follower/seguiti) e griglia delle ricette pubblicate. Gestisce anche i pulsanti "Segui"/"Non seguire" tramite il servlet `FollowServlet`.

---

## Analisi riga per riga

### Direttive

```jsp
<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, com.bakingbread.util.UrlUtils" %>
<%@ page import="java.util.*" %>
```

Tre import separati (sintassi equivalente a metterli tutti in uno).

---

### Metodo di escape HTML

```jsp
<%!
    private String esc(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;")
                    .replace("<", "&lt;")
                    .replace(">", "&gt;")
                    .replace("\"", "&quot;")
                    .replace("'", "&#39;");
    }
%>
```

Dichiarazione (`<%!`) di un metodo di classe. Converte i caratteri HTML speciali nelle loro entità HTML sicure. Questo è un **countermeasure XSS** (Cross-Site Scripting): senza escape, se un utente avesse come nome `<script>alert('hack')</script>`, questo codice verrebbe eseguito nei browser degli altri utenti. Con l'escape, diventa testo inoffensivo.

---

### Determinazione del profilo da visualizzare

```jsp
    Integer idUtenteLoggato = (Integer) session.getAttribute("id_utente");
    String ctx = request.getContextPath();
    int idProfilo = 0;
    try { idProfilo = Integer.parseInt(request.getParameter("id")); } catch (Exception ignore) {}
    if (idProfilo == 0 && idUtenteLoggato != null) idProfilo = idUtenteLoggato;
    if (idProfilo == 0) { response.sendRedirect("home.jsp"); return; }
```

Logica per determinare quale profilo mostrare:
1. Prova a leggere `?id=123` dall'URL
2. Se non presente o non valido (idProfilo == 0) e l'utente è loggato → mostra il proprio profilo
3. Se ancora 0 (utente non loggato e nessun ID) → redirect alla home

---

### Variabili di stato

```jsp
    boolean isSeguito = false;
    boolean isProprioProfilo = idUtenteLoggato != null && idUtenteLoggato.intValue() == idProfilo;
```

- `isSeguito` → l'utente loggato segue questo profilo? (default false, aggiornato dal DB)
- `isProprioProfilo` → confronta ID loggato con ID profilo. Usa `.intValue()` perché `Integer` è un oggetto e `==` confronterebbe i riferimenti, non i valori. Con `.intValue()` confronta i valori primitivi `int`.

---

### Classe interna RecipeCard

```jsp
    class RecipeCard { 
        int id; 
        String titolo, immagine; 
        RecipeCard(int id, String titolo, String immagine) { 
            this.id=id; this.titolo=titolo; this.immagine=immagine; 
        } 
    }
    List<RecipeCard> recipes = new ArrayList<RecipeCard>();
```

Una classe Java definita all'interno dello scriptlet. Questo è un pattern inusuale ma valido in JSP. Serve come struttura dati semplice per raccogliere i dati delle ricette dal database prima di renderizzare l'HTML. Equivale a un semplice DTO (Data Transfer Object).

---

### Query database

```jsp
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/bakingbread?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true", "root", "");
        
        PreparedStatement ps = conn.prepareStatement("SELECT username, nome_visualizzato, bio, avatar_url, creato_il FROM Utente WHERE id_utente = ?");
        ps.setInt(1, idProfilo);
        ResultSet rs = ps.executeQuery();
        if (rs.next()) { 
            username = rs.getString("username"); 
            nomeVisualizzato = rs.getString("nome_visualizzato"); 
            bio = rs.getString("bio"); 
            avatarUrl = UrlUtils.resolve(ctx, rs.getString("avatar_url")); 
            creatoIl = rs.getTimestamp("creato_il"); 
        }
        rs.close(); ps.close();
        if (nomeVisualizzato.isEmpty()) { conn.close(); response.sendRedirect("home.jsp"); return; }
```

Se non trova un utente con quell'ID (o il nome visualizzato è vuoto), reindirizza alla home invece di mostrare una pagina vuota.

```jsp
        ps = conn.prepareStatement("SELECT COUNT(*) FROM Ricetta WHERE id_utente = ? AND pubblicata = TRUE");
        ps.setInt(1, idProfilo); rs = ps.executeQuery(); if (rs.next()) numRicette = rs.getInt(1); rs.close(); ps.close();
        
        ps = conn.prepareStatement("SELECT COUNT(*) FROM Seguito WHERE followed_id = ?");
        ps.setInt(1, idProfilo); rs = ps.executeQuery(); if (rs.next()) numFollower = rs.getInt(1); rs.close(); ps.close();
        
        ps = conn.prepareStatement("SELECT COUNT(*) FROM Seguito WHERE follower_id = ?");
        ps.setInt(1, idProfilo); rs = ps.executeQuery(); if (rs.next()) numSeguiti = rs.getInt(1); rs.close(); ps.close();
```

Tre query separate per le statistiche. Potrebbe essere una sola query con COUNT condizionali, ma è più leggibile così.

```jsp
        if (!isProprioProfilo && idUtenteLoggato != null) {
            ps = conn.prepareStatement("SELECT 1 FROM Seguito WHERE follower_id = ? AND followed_id = ?");
            ps.setInt(1, idUtenteLoggato); ps.setInt(2, idProfilo); rs = ps.executeQuery(); 
            isSeguito = rs.next(); 
            rs.close(); ps.close();
        }
```

Controlla se l'utente loggato segue il profilo visualizzato. `SELECT 1` è più efficiente di `SELECT *`: non trasferisce dati inutili, interessa solo sapere se esiste la riga. `rs.next()` restituisce `true` se c'è almeno una riga, `false` altrimenti.

---

### Pulsante Segui / Non Seguire

```html
<% if (!isProprioProfilo && idUtenteLoggato != null) { %>
<form method="POST" action="<%= ctx %>/profile/follow" style="display:inline;">
    <input type="hidden" name="id" value="<%= idProfilo %>">
    <% if (isSeguito) { %>
    <input type="hidden" name="action" value="unfollow">
    <button type="submit" class="btn-outline">Non seguire</button>
    <% } else { %>
    <button type="submit" class="btn-primary">Segui</button>
    <% } %>
</form>
<% } %>
```

Il form invia a `/profile/follow` (che è gestito da `FollowServlet.java`). Quando `isSeguito` è true, aggiunge un campo hidden `action=unfollow` e mostra "Non seguire"; altrimenti non aggiunge il campo (il servlet interpreta l'assenza come "segui") e mostra "Segui". Questo non viene mostrato sul proprio profilo.

---

### Griglia ricette

```html
<div class="recipe-grid profile-recipe-grid">
    <% for (RecipeCard r : recipes) { %>
        <a class="recipe-card" href="<%= ctx %>/dettaglio_ricetta.jsp?id=<%= r.id %>">
            <% if (r.immagine != null && !r.immagine.trim().isEmpty()) { %>
                <img src="<%= esc(UrlUtils.resolve(ctx, r.immagine)) %>" alt="<%= esc(r.titolo) %>">
            <% } else { %>
                <div class="recipe-card-placeholder"></div>
            <% } %>
            <div class="recipe-card-overlay"><h3><%= esc(r.titolo) %></h3></div>
        </a>
    <% } %>
    <% if (recipes.isEmpty()) { %><p class="empty-state">Nessuna ricetta pubblicata.</p><% } %>
</div>
```

Ogni ricetta è un link (`<a class="recipe-card">`) con un overlay con il titolo. `UrlUtils.resolve(ctx, r.immagine)` risolve l'URL relativo dell'immagine. Tutto l'output è passato per `esc()` per prevenire XSS.

---

### Data di iscrizione

```html
<% if (creatoIl != null) { %><p class="profile-meta">Membro dal <%= creatoIl.toString().substring(0, 10) %></p><% } %>
```

`creatoIl.toString()` produce una stringa come `"2024-03-15 14:32:10.0"`. `.substring(0, 10)` prende solo i primi 10 caratteri: `"2024-03-15"` (formato ISO 8601). È una soluzione semplice anche se non localizzata.

---

## Flusso completo profile.jsp

```
GET /profile.jsp?id=42
├── Determina idProfilo (da ?id= o dalla sessione)
├── Query DB: dati utente (username, bio, avatar, data iscrizione)
├── Query DB: numRicette, numFollower, numSeguiti (3 COUNT separate)
├── Se utente loggato e non proprio profilo: controlla isSeguito
├── Query DB: lista ultime 24 ricette pubblicate
└── Renderizza HTML:
    ├── Header profilo (avatar, nome, bio, statistiche)
    ├── Pulsante Segui/Non seguire (se non proprio profilo)
    └── Griglia ricette

POST /profile/follow ← gestito da FollowServlet (non da questa JSP)
```
