# 07 – `crea_ricetta.jsp` — Spiegazione riga per riga

## Scopo del file
Form per creare una nuova ricetta o modificarne una esistente. Usa un unico file per entrambe le operazioni: se viene passato il parametro `?modifica=ID`, entra in modalità editing e precarica i dati esistenti.

---

## Analisi riga per riga

### Verifica sessione e modalità editing

```jsp
    Integer idUtente = (Integer) session.getAttribute("id_utente");
    if (idUtente == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String ctx = request.getContextPath();
    int idRicettaModifica = 0;
    try { idRicettaModifica = Integer.parseInt(request.getParameter("modifica")); } catch (Exception ignore) {}
    boolean isModifica = idRicettaModifica > 0;
```

Se il parametro `?modifica=5` è presente e valido, `isModifica = true` e `idRicettaModifica = 5`. Altrimenti si è in modalità creazione.

---

### Caricamento dati per la modifica

```jsp
    Map<String, Object> ricetta = null;
    List<Map<String, Object>> ingredienti = new ArrayList<Map<String, Object>>();
    List<Map<String, Object>> passaggi = new ArrayList<Map<String, Object>>();

    if (isModifica) {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/bakingbread?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true", "root", "");
            PreparedStatement ps = conn.prepareStatement("SELECT * FROM Ricetta WHERE id_ricetta = ? AND id_utente = ?");
            ps.setInt(1, idRicettaModifica);
            ps.setInt(2, idUtente);
```

**Importante**: la query usa sia `id_ricetta = ?` che `id_utente = ?`. Questo impedisce a un utente di modificare le ricette di un altro: anche se conosce l'ID della ricetta altrui, la query non troverà nulla perché `id_utente` non corrisponde.

```jsp
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                ricetta = new HashMap<String, Object>();
                ricetta.put("titolo", rs.getString("titolo"));
                ricetta.put("descrizione", rs.getString("descrizione"));
                ...
                ricetta.put("pubblicata", rs.getBoolean("pubblicata"));
            }
```

Carica tutti i campi della ricetta in una `Map<String, Object>`. Una Map permette di tenere tipi diversi (String, Integer, Boolean) in un'unica struttura senza definire una classe specifica.

```jsp
            if (ricetta != null) {
                ps = conn.prepareStatement("SELECT i.nome, ri.quantita, ri.unita_misura FROM RicettaIngrediente ri JOIN Ingrediente i ON ri.id_ingrediente = i.id_ingrediente WHERE ri.id_ricetta = ? ORDER BY ri.ordine_visualizzazione");
                ...
                ps = conn.prepareStatement("SELECT descrizione FROM Passaggio WHERE id_ricetta = ? ORDER BY ordine");
```

Carica ingredienti e passaggi solo se la ricetta esiste (ricetta != null). Due query separate: una per gli ingredienti (con JOIN alla tabella Ingrediente normalizzata), una per i passaggi.

---

### Valori di default / pre-compilazione

```jsp
    String titoloVal = ricetta != null && ricetta.get("titolo") != null ? (String) ricetta.get("titolo") : "";
    String prepVal = ricetta != null && ricetta.get("tempo_preparazione_min") != null ? String.valueOf(ricetta.get("tempo_preparazione_min")) : "15";
    ...
    boolean pubblicata = ricetta == null || Boolean.TRUE.equals(ricetta.get("pubblicata"));
```

Per ogni campo, usa il valore dalla Map se in modalità modifica, altrimenti usa un valore di default ragionevole (15 min di prep, 30 min cottura, 4 porzioni, ecc.).

`Boolean.TRUE.equals(...)` è il modo sicuro per confrontare Boolean nullable: `ricetta.get("pubblicata")` potrebbe essere `null` (se il campo DB è NULL), e chiamare `.equals()` su un Boolean null causerebbe NullPointerException.

---

### Form HTML

```html
<form class="recipe-form" method="post" action="<%= ctx %>/recipe/save" enctype="multipart/form-data">
    <input type="hidden" name="id_ricetta" value="<%= isModifica ? idRicettaModifica : "" %>">
    <input type="hidden" name="current_image_url" value="<%= immagineVal == null ? "" : immagineVal %>">
```

- `method="post"` → necessario per inviare dati
- `action="/recipe/save"` → punta a `RecipeSaveServlet`
- `enctype="multipart/form-data"` → **obbligatorio** per upload di file; senza questo, i file non vengono inviati
- Il campo hidden `id_ricetta` dice al servlet se è una creazione (vuoto) o modifica (con ID)
- Il campo hidden `current_image_url` preserva l'URL dell'immagine esistente se non ne viene caricata una nuova

---

### Upload immagine (file + URL)

```html
<input type="file" name="recipe_image_file" id="recipe_image_file" accept="image/*" 
       class="file-input" onchange="handleRecipeImagePreview(this)">
<input type="url" name="immagine_url" placeholder="https://..." value="<%= immagineVal == null ? "" : immagineVal %>">
```

Due modi alternativi per fornire un'immagine:
1. **Upload file** → `type="file"` con `accept="image/*"` (solo immagini). `onchange` chiama la funzione JS per l'anteprima immediata.
2. **URL esterno** → l'utente può incollare un URL di un'immagine online

Il servlet dà priorità all'upload sul URL.

---

### Select con opzione pre-selezionata

```html
<select id="categoria" name="categoria">
    <option value="">Seleziona...</option>
    <option value="Antipasto" <%= "Antipasto".equals(categoriaVal) ? "selected" : "" %>>Antipasto</option>
    <option value="Primo" <%= "Primo".equals(categoriaVal) ? "selected" : "" %>>Primo piatto</option>
    ...
</select>
```

Per ogni opzione, usa l'espressione JSP per aggiungere `selected` se il valore corrisponde a quello caricato dal database. Questo è il modo classico per pre-selezionare un'opzione in un `<select>` in JSP.

---

### Lista dinamica ingredienti

```html
<div id="ingredienti-container" class="dynamic-list">
    <% if (!ingredienti.isEmpty()) { %>
        <% for (Map<String, Object> ing : ingredienti) { %>
            <div class="row-item">
                <input type="text" name="ingrediente_nome" placeholder="Ingrediente" value="<%= ing.get("nome") %>" required>
                <input type="text" name="ingrediente_quantita" placeholder="Quantità" value="<%= ing.get("quantita") != null ? ing.get("quantita") : "" %>">
                <input type="text" name="ingrediente_unita" placeholder="Unità" value="<%= ing.get("unita") != null ? ing.get("unita") : "" %>">
                <button type="button" class="icon-btn" onclick="rimuoviRiga(this)">×</button>
            </div>
        <% } %>
    <% } else { %>
        <div class="row-item">...</div>
    <% } %>
</div>
```

In modalità modifica, genera un `<div class="row-item">` per ogni ingrediente esistente, pre-compilato con i dati. In modalità creazione, genera un singolo row vuoto come punto di partenza.

Il JavaScript (`recipe.js`) aggiunge nuovi row dinamicamente quando si clicca "Aggiungi ingrediente", e li rimuove con "×". I campi hanno tutti lo stesso `name=` (es. `ingrediente_nome`) — quando ci sono più campi con lo stesso nome, il server li riceve come array tramite `request.getParameterValues("ingrediente_nome")`.

---

## Flusso completo crea_ricetta.jsp

```
GET /crea_ricetta.jsp
├── Utente non loggato? → redirect login
└── Mostra form vuoto (modalità creazione)

GET /crea_ricetta.jsp?modifica=5
├── Utente non loggato? → redirect login
├── Query DB: ricetta WHERE id=5 AND id_utente=[loggato]
├── Query DB: ingredienti della ricetta
├── Query DB: passaggi della ricetta
└── Mostra form pre-compilato (modalità modifica)

POST /recipe/save ← gestito da RecipeSaveServlet
```

---

---

# 08 – `dettaglio_ricetta.jsp` — Spiegazione riga per riga

## Scopo del file
Pagina di dettaglio di una singola ricetta. Mostra tutti i dati (immagine, titolo, autore, meta, ingredienti, passaggi, rating, commenti). Richiede autenticazione.

---

## Analisi riga per riga

### Classe interna helper per HTML escaping

```jsp
<%!
    private String esc(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }
%>
```

Dichiarazione di metodo a livello di classe per l'HTML escaping. Usato ovunque venga stampato contenuto generato dall'utente (titoli, descrizioni, commenti, ecc.).

---

### Classi interne per i dati

```jsp
    class Ingredient { String nome, quantita, unita; Ingredient(String n, String q, String u) { nome=n; quantita=q; unita=u; } }
    class Step { int ordine; String descrizione; Step(int o, String d) { ordine=o; descrizione=d; } }
    class Comment { int id, parentId, userId; String nome, username, avatar, testo; Timestamp data; Comment(...) { ... } }
```

Tre mini-classi definite dentro lo scriptlet per tenere i dati strutturati prima del rendering. Questa è una tecnica JSP per evitare strutture dati primitive (Map di Map) poco leggibili.

---

### Caricamento dati dalla ricetta

```jsp
    Class.forName("com.mysql.cj.jdbc.Driver");
    Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/bakingbread?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true", "root", "");

    PreparedStatement ps = conn.prepareStatement("SELECT r.*, u.nome_visualizzato, u.username, u.avatar_url, u.id_utente AS autore_id FROM Ricetta r JOIN Utente u ON r.id_utente = u.id_utente WHERE r.id_ricetta = ?");
    ps.setInt(1, idRicetta);
    ResultSet rs = ps.executeQuery();
```

`SELECT r.*` seleziona tutte le colonne della ricetta. `u.id_utente AS autore_id` usa un alias perché entrambe le tabelle hanno `id_utente` e bisogna distinguerli.

---

### Caricamento valutazioni (rating)

```jsp
    ps = conn.prepareStatement("SELECT COALESCE(AVG(stelle), 0) AS media_stelle, COUNT(*) AS num_voti FROM Valutazione WHERE id_ricetta = ?");
    ps.setInt(1, idRicetta);
    rs = ps.executeQuery();
    if (rs.next()) {
        ricetta.put("media_stelle", rs.getDouble("media_stelle"));
        ricetta.put("num_voti", rs.getInt("num_voti"));
    }
```

`COALESCE(AVG(stelle), 0)` → se non ci sono valutazioni, `AVG` restituisce NULL; `COALESCE` lo sostituisce con 0. Media e conteggio vengono salvati nella Map `ricetta`.

---

### Struttura commenti (albero padre-figlio)

```jsp
    List<Comment> topComments = new ArrayList<Comment>();
    Map<Integer, List<Comment>> replies = new HashMap<Integer, List<Comment>>();
    
    while (rs.next()) {
        Comment c = new Comment(...);
        totaleCommenti++;
        if (c.parentId > 0) {
            List<Comment> list = replies.get(c.parentId);
            if (list == null) { list = new ArrayList<Comment>(); replies.put(c.parentId, list); }
            list.add(c);
        } else {
            topComments.add(c);
        }
    }
```

I commenti hanno struttura ad albero (commenti top-level e risposte). La logica:
- Commenti con `parent_commento = NULL` (parentId = 0) → vanno in `topComments`
- Commenti con `parent_commento = X` → vanno in `replies.get(X)` (mappa ID padre → lista figli)

Questa struttura permette di renderizzare facilmente i commenti con le loro risposte nidificate.

---

### Rendering commenti annidati

```html
<% for (Comment c : topComments) { %>
    <div class="comment-card">
        <p><%= esc(c.testo) %></p>
        <% List<Comment> child = replies.get(c.id); if (child != null && !child.isEmpty()) { %>
            <div class="comment-replies">
                <% for (Comment r : child) { %>
                    <div class="comment-reply">
                        <p><%= esc(r.testo) %></p>
                    </div>
                <% } %>
            </div>
        <% } %>
    </div>
<% } %>
```

Per ogni commento top-level, cerca le sue risposte nella mappa `replies`. Se esistono, le renderizza in un div nidificato. Semplice e efficiente perché tutti i dati sono già in memoria.

---

### Calcolo rating e controllo autore

```jsp
    double media = ricetta.get("media_stelle") != null ? ((Number) ricetta.get("media_stelle")).doubleValue() : 0;
    boolean isAutore = idUtenteLoggato != null && idUtenteLoggato.intValue() == ((Number) ricetta.get("autore_id")).intValue();
```

`((Number) ricetta.get("media_stelle")).doubleValue()` usa il cast a `Number` (superclasse di Integer e Double) per gestire sia il caso in cui MySQL restituisca il risultato come `Double` o `BigDecimal`.

---

### Formattazione rating nell'HTML

```html
<div class="meta-chip">Rating: <strong><%= String.format(java.util.Locale.US, "%.1f", media) %></strong> (<%= voti %>)</div>
```

`String.format(Locale.US, "%.1f", media)` formatta il double con 1 decimale. Specifica `Locale.US` per assicurare che il separatore decimale sia il punto `.` (non la virgola `,` usata nella Locale italiana).

---

## Flusso completo dettaglio_ricetta.jsp

```
GET /dettaglio_ricetta.jsp?id=5
├── Utente non loggato? → redirect login
├── id non valido (≤ 0)? → redirect home
├── Query DB: dati ricetta + autore (JOIN)
├── Query DB: media stelle e numero voti (Valutazione)
├── Se ricetta non trovata → redirect home
├── Query DB: ingredienti (JOIN con Ingrediente)
├── Query DB: passaggi (ORDER BY ordine)
├── Query DB: commenti (JOIN con Utente, ORDER BY data)
│   └── Costruisce struttura ad albero (topComments + replies map)
└── Renderizza HTML completo:
    ├── Hero ricetta (immagine, titolo, autore, meta, rating)
    ├── Griglia contenuto (ingredienti + passaggi)
    └── Sezione commenti (form + lista commenti annidati)
```
