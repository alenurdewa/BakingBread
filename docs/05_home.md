# 05 – `home.jsp` — Spiegazione riga per riga

## Scopo del file
È la pagina principale del feed. Mostra le ricette pubblicate da tutti gli utenti (in ordine cronologico inverso), con supporto alla ricerca per titolo/descrizione. Gestisce anche le azioni di "Mi Piace" e "Salva" direttamente (pattern Post-Redirect-Get).

---

## Struttura generale

```
home.jsp
├── [Scriptlet iniziale]
│   ├── Anti-cache
│   ├── Lettura ctx, idUtenteLoggato
│   ├── Gestione azioni POST (mi piace / salva)
│   │   └── redirect → home.jsp (PRG pattern)
│   └── Lettura parametro ricerca "q"
└── [HTML]
    ├── <jsp:include page="navbar.jsp" />
    └── Feed ricette (loop Java dentro HTML)
        ├── Query DB (con/senza ricerca, con/senza info like/salva)
        ├── Per ogni ricetta: card HTML
        └── Pulsanti azione (like, salva, modifica)
```

---

## Analisi riga per riga

### Anti-cache e variabili iniziali

```jsp
    String ctx = request.getContextPath();
    Integer idUtenteLoggato = (Integer) session.getAttribute("id_utente");
    String azione = request.getParameter("azione");
    String tipo = request.getParameter("tipo");
    int idTarget = 0;
    try { idTarget = Integer.parseInt(request.getParameter("id")); } catch (Exception e) {}
```

- `ctx` → path base dell'applicazione
- `azione` → tipo di azione richiesta (`"mi piace"` o `"salva"`)
- `tipo` → sottotipo dell'azione (`"aggiungi"` o `"rimuovi"`)
- `idTarget` → ID della ricetta su cui agire
- Il try-catch per il parseInt: se `request.getParameter("id")` è null o non numerico, rimane 0

---

### Gestione azioni (Mi Piace / Salva)

```jsp
    if (idUtenteLoggato != null && azione != null && idTarget > 0) {
        try {
            Connection conn = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/bakingbread?useSSL=false", "root", "");
```

Questo blocco viene eseguito solo se:
1. L'utente è loggato (`idUtenteLoggato != null`)
2. C'è un'azione specificata
3. C'è un ID valido della ricetta

```jsp
            if ("mi piace".equals(azione)) {
                if ("aggiungi".equals(tipo)) {
                    PreparedStatement ps = conn.prepareStatement(
                        "INSERT IGNORE INTO MiPiace (id_ricetta, id_utente) VALUES (?, ?)");
                    ps.setInt(1, idTarget);
                    ps.setInt(2, idUtenteLoggato);
                    ps.executeUpdate();
                    ps.close();
```

**`INSERT IGNORE`** è un'estensione MySQL: se la riga esiste già (violazione della UNIQUE KEY `uk_like_utente`), l'INSERT viene ignorato silenziosamente invece di generare un errore. Questo previene i like duplicati senza bisogno di controllare prima con una SELECT.

```jsp
                } else if ("rimuovi".equals(tipo)) {
                    PreparedStatement ps = conn.prepareStatement(
                        "DELETE FROM MiPiace WHERE id_ricetta = ? AND id_utente = ?");
                    ps.setInt(1, idTarget);
                    ps.setInt(2, idUtenteLoggato);
                    ps.executeUpdate();
                    ps.close();
                }
            } else if ("salva".equals(azione)) {
```

Struttura speculare per la funzione "Salva" (usa la tabella `RicettaSalvata` invece di `MiPiace`).

```jsp
            conn.close();
            response.sendRedirect("home.jsp");
            return;
```

**Pattern Post-Redirect-Get (PRG)**: dopo aver elaborato il POST, redirect a GET. Questo previene il problema "ricarica la pagina → invia di nuovo il form". Il `return` ferma subito l'esecuzione; senza di esso, il codice continuerebbe e la pagina verrebbe renderizzata due volte.

---

### Costruzione della query dinamica

```jsp
    StringBuilder sql = new StringBuilder(
        "SELECT r.id_ricetta, r.titolo, r.descrizione, r.categoria, " +
        "r.tempo_preparazione_min, r.immagine_url, r.creato_il, " +
        "u.id_utente, u.username, u.nome_visualizzato, u.avatar_url, " +
        "(SELECT COUNT(*) FROM MiPiace WHERE id_ricetta = r.id_ricetta) AS num_like, " +
        "(SELECT COUNT(*) FROM Commento WHERE id_ricetta = r.id_ricetta) AS num_commenti ");
```

Usa `StringBuilder` invece di `String +` per costruire la query in modo efficiente. Le subquery correlate `(SELECT COUNT(*) ...)` calcolano il numero di like e commenti per ogni ricetta nel risultato della query principale. Sono dette "subquery scalari" perché ritornano un singolo valore.

```jsp
    if (idUtenteLoggato != null) {
        sql.append(", (SELECT COUNT(*) FROM MiPiace WHERE id_ricetta = r.id_ricetta AND id_utente = ").append(idUtenteLoggato).append(") AS gia_like");
        sql.append(", (SELECT COUNT(*) FROM RicettaSalvata WHERE id_ricetta = r.id_ricetta AND id_utente = ").append(idUtenteLoggato).append(") AS gia_salvata");
    }
```

Se l'utente è loggato, aggiunge due colonne extra che indicano se l'utente corrente ha già messo like o salvato quella ricetta. Questo permette di mostrare i pulsanti nel giusto stato (attivo/inattivo). 

**Nota di sicurezza**: `idUtenteLoggato` qui viene inserito direttamente nella stringa SQL. Questo è tecnicamente una SQL injection, ma è sicuro in questo caso perché `idUtenteLoggato` viene dalla sessione (lato server) e non dall'input dell'utente. In un codice più rigoroso si userebbe comunque un PreparedStatement.

```jsp
    sql.append(" FROM Ricetta r ");
    sql.append("JOIN Utente u ON r.id_utente = u.id_utente ");
    sql.append("WHERE r.pubblicata = TRUE ");
    
    if (searchQuery != null && !searchQuery.trim().isEmpty()) {
        sql.append("AND (r.titolo LIKE ? OR r.descrizione LIKE ?) ");
    }
    
    sql.append("ORDER BY r.creato_il DESC LIMIT 50");
```

- `JOIN Utente` → unisce i dati della ricetta con quelli dell'autore
- `WHERE r.pubblicata = TRUE` → mostra solo ricette pubblicate
- La condizione LIKE viene aggiunta dinamicamente solo se c'è una ricerca
- `ORDER BY r.creato_il DESC` → le più recenti prima
- `LIMIT 50` → massimo 50 ricette per performance

```jsp
    PreparedStatement ps = conn.prepareStatement(sql.toString());
    
    if (searchQuery != null && !searchQuery.trim().isEmpty()) {
        String q = "%" + searchQuery.trim() + "%";
        ps.setString(1, q);
        ps.setString(2, q);
    }
```

`"%" + searchQuery + "%"` usa i wildcard SQL: `%` corrisponde a qualsiasi sequenza di caratteri. Es. con `searchQuery = "torta"`, la query cerca tutte le ricette con "torta" nel titolo o nella descrizione.

---

### Loop di rendering delle ricette

```jsp
    while (rs.next()) {
        count++;
        int idRicetta = rs.getInt("id_ricetta");
        String titolo = rs.getString("titolo");
        ...
        String immagineUrl = UrlUtils.resolve(ctx, rs.getString("immagine_url"));
        ...
        boolean giaLike = false;
        boolean giaSalvata = false;
        if (idUtenteLoggato != null) {
            giaLike = rs.getInt("gia_like") > 0;
            giaSalvata = rs.getInt("gia_salvata") > 0;
        }
        
        String displayImmagine = "linear-gradient(135deg, #f3f4f6 0%, #e5e7eb 100%)";
        if (immagineUrl != null && !immagineUrl.isEmpty()) {
            displayImmagine = "url('" + immagineUrl + "')";
        }
%>
```

Per ogni ricetta:
- Legge i campi dal ResultSet
- `UrlUtils.resolve` normalizza l'URL dell'immagine
- `gia_like > 0` → il COUNT restituisce 0 o 1; > 0 indica che il like esiste
- `displayImmagine` → se non c'è immagine, usa un gradiente CSS come placeholder

---

### Card HTML di ogni ricetta

```html
<article class="recipe-card animate-entrance">
    <div class="recipe-card-header">
        <a href="profile.jsp?id=<%= idAutore %>" class="recipe-card-avatar">
            <% if (avatarUrl != null && !avatarUrl.isEmpty()) { %>
                <img src="<%= avatarUrl %>" alt="<%= nomeVisualizzato %>">
            <% } else { %>
                <%= nomeVisualizzato.substring(0,1).toUpperCase() %>
            <% } %>
        </a>
```

L'avatar è linkato al profilo dell'autore. Se non c'è avatar, mostra la prima lettera del nome (su sfondo colorato via CSS).

```html
<a href="dettaglio_ricetta.jsp?id=<%= idRicetta %>">
    <div class="recipe-card-image" 
         style="background:<%= displayImmagine %>;background-size:cover;background-position:center;">
    </div>
</a>
```

L'immagine è implementata come `background-image` CSS invece di un elemento `<img>`. Questo permette di usare `background-size:cover` per il ritaglio automatico, e di usare il gradiente come fallback facilmente.

```html
<p class="recipe-card-desc">
    <%= descrizione != null && descrizione.length() > 120 ? 
        descrizione.substring(0, 120) + "..." : 
        (descrizione != null ? descrizione : "") %>
</p>
```

Tronca la descrizione a 120 caratteri con "..." se troppo lunga. Operatore ternario annidato: prima controlla se è > 120, poi gestisce il caso null.

---

### Pulsanti di azione

```html
<% String likeAction = giaLike ? "rimuovi" : "aggiungi"; %>
<% if (idUtenteLoggato != null) { %>
    <form method="POST" action="home.jsp" style="display:inline;">
        <input type="hidden" name="azione" value="mi piace">
        <input type="hidden" name="tipo" value="<%= likeAction %>">
        <input type="hidden" name="id" value="<%= idRicetta %>">
        <button type="submit" class="action-btn <%= giaLike ? "active" : "" %>">
            <svg ... fill="<%= giaLike ? "currentColor" : "none" %>" ...>
                <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0..."/>
            </svg>
            <%= numLike %>
        </button>
    </form>
```

Ogni pulsante di azione è un piccolo form:
- `action="home.jsp"` → invia alla stessa pagina
- I campi hidden passano i parametri senza mostrarli all'utente
- `tipo` cambia dinamicamente: se già piaciuto → "rimuovi", altrimenti → "aggiungi" (toggle)
- L'SVG del cuore ha `fill="currentColor"` quando il like è attivo (cuore pieno) e `fill="none"` altrimenti (cuore vuoto)
- La classe CSS `active` evidenzia il pulsante quando già cliccato

```html
<% } else { %>
    <a href="login.jsp" class="action-btn">
        <svg ...></svg>
        <%= numLike %>
    </a>
<% } %>
```

Se l'utente non è loggato, il "pulsante" like è invece un link che porta al login.

```html
<% if (idUtenteLoggato != null && idAutore == idUtenteLoggato) { %>
    <a href="crea_ricetta.jsp?modifica=<%= idRicetta %>" class="action-btn">
        <svg>...</svg>
    </a>
<% } %>
```

Il pulsante di modifica appare solo se l'utente loggato è l'autore di quella ricetta (`idAutore == idUtenteLoggato`).

---

### Stato vuoto

```html
<% if (count == 0) { %>
<div class="empty-state">
    <h3>Nessuna ricetta trovata</h3>
    <p>Inizia a seguire altri utenti o crea la tua prima ricetta!</p>
    <% if (idUtenteLoggato != null) { %>
        <a href="crea_ricetta.jsp" class="btn-primary mt-3">Crea Ricetta</a>
    <% } else { %>
        <a href="register.jsp" class="btn-primary mt-3">Registrati</a>
    <% } %>
</div>
<% } %>
```

Quando non ci sono ricette (database vuoto o ricerca senza risultati), mostra un messaggio con una call-to-action appropriata per lo stato dell'utente.

---

## Flusso completo home.jsp

```
GET /home.jsp
├── Controlla se c'è un'azione POST in attesa → no, skip
├── Legge parametro ?q= per la ricerca
├── Costruisce query SQL dinamicamente
│   ├── Con login: aggiunge colonne gia_like, gia_salvata
│   └── Con ricerca: aggiunge condizione LIKE
├── Esegue query, loop ResultSet
└── Per ogni ricetta: renderizza card HTML

POST /home.jsp?azione=mi_piace&tipo=aggiungi&id=5
├── INSERT IGNORE INTO MiPiace
└── Redirect GET /home.jsp

POST /home.jsp?azione=salva&tipo=rimuovi&id=5
├── DELETE FROM RicettaSalvata
└── Redirect GET /home.jsp
```
