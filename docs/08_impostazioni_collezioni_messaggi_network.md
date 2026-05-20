# 08 – `impostazioni.jsp` — Spiegazione riga per riga

## Scopo del file
Pagina per modificare il profilo dell'utente: nome, email, bio e avatar. Carica i dati correnti dal DB e mostra un form pre-compilato. L'invio è gestito da `ProfileUpdateServlet`.

---

## Analisi riga per riga

### Caricamento dati utente

```jsp
    Integer idUtente = (Integer) session.getAttribute("id_utente");
    if (idUtente == null) { response.sendRedirect("login.jsp"); return; }
    String ctx = request.getContextPath();
    String nomeVisualizzato = "", username = "", email = "", bio = "", avatarUrl = "";
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/bakingbread?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true", "root", "");
        PreparedStatement ps = conn.prepareStatement("SELECT nome_visualizzato, username, email, bio, avatar_url FROM Utente WHERE id_utente = ?");
        ps.setInt(1, idUtente);
        ResultSet rs = ps.executeQuery();
        if (rs.next()) { nomeVisualizzato = rs.getString("nome_visualizzato"); username = rs.getString("username"); ... }
        rs.close(); ps.close(); conn.close();
    } catch (Exception ex) { response.sendRedirect("home.jsp"); return; }
```

Carica dal DB i dati dell'utente loggato per pre-compilare il form. In caso di errore DB, redirect a home (fail gracefully).

---

### Form di aggiornamento

```html
<form action="<%= ctx %>/profile/update" method="post" enctype="multipart/form-data" class="settings-form">
    <input type="hidden" name="current_avatar_url" value="<%= avatarUrl == null ? "" : avatarUrl %>">
```

- `action="/profile/update"` → gestito da `ProfileUpdateServlet`
- `enctype="multipart/form-data"` → necessario per upload avatar
- Il campo hidden `current_avatar_url` preserva l'avatar corrente se non ne viene caricato uno nuovo

---

### Anteprima avatar

```html
<label class="btn-outline file-button">
    Cambia foto
    <input type="file" id="avatar_file" name="avatar_file" accept="image/*" 
           class="hidden-file-input" onchange="previewProfileAvatar(this)">
</label>
<input type="url" name="avatar_url" placeholder="URL immagine opzionale" class="url-input" value="<%= avatarUrl == null ? "" : esc(avatarUrl) %>">
```

Il `<label>` wrappa l'`<input type="file">`: cliccando l'etichetta si apre il selettore file. L'input file è nascosto con CSS (`hidden-file-input`). `onchange="previewProfileAvatar(this)"` mostra l'anteprima immediatamente dopo la selezione (vedi `profile.js`). Come alternativa, si può inserire un URL.

---

---

# 09 – `collezioni.jsp` — Spiegazione riga per riga

## Scopo del file
Mostra tutte le ricette salvate dall'utente loggato (la sua "lista dei desideri" di ricette). Permette di rimuoverle dalla lista.

---

## Query principale

```jsp
    String sql = "SELECT r.id_ricetta, r.titolo, r.immagine_url, " +
                 "r.tempo_preparazione_min, u.nome_visualizzato, u.avatar_url " +
                 "FROM RicettaSalvata rs " +
                 "JOIN Ricetta r ON rs.id_ricetta = r.id_ricetta " +
                 "JOIN Utente u ON r.id_utente = u.id_utente " +
                 "WHERE rs.id_utente = ? AND r.pubblicata = TRUE " +
                 "ORDER BY rs.salvata_il DESC";
```

Join a tre vie:
- `RicettaSalvata` (tabella pivot) → contiene quali utenti hanno salvato quali ricette
- `Ricetta` → per i dettagli della ricetta
- `Utente` → per i dati dell'autore della ricetta

`ORDER BY rs.salvata_il DESC` → le più recentemente salvate prima.

---

## Pulsante rimozione

```html
<form method="POST" action="dettaglio_ricetta.jsp?id=<%= idRicetta %>" style="position:absolute;top:10px;right:10px;">
    <input type="hidden" name="azione" value="salva">
    <input type="hidden" name="tipo" value="rimuovi">
    <button type="submit" class="btn-icon" title="Rimuovi dai salvati">
        <svg ...></svg>
    </button>
</form>
```

Nota: questo form invia a `dettaglio_ricetta.jsp`, ma quella JSP non gestisce questo POST. Probabilmente è un bug o un residuo di una feature non completata. In home.jsp c'è la stessa logica funzionante.

---

---

# 10 – `messaggi.jsp` — Spiegazione riga per riga

## Scopo del file
Sistema di messaggistica privata. Mostra la lista delle conversazioni (sidebar) e i messaggi di una conversazione selezionata (area principale). Gestisce anche l'invio di nuovi messaggi.

---

## Analisi riga per riga

### Gestione azioni POST

```jsp
    String azione = request.getParameter("azione");
    if ("invia_messaggio".equals(azione) && chatConId > 0) {
        String testo = request.getParameter("testo");
        if (testo != null && !testo.trim().isEmpty()) {
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                Connection conn = DriverManager.getConnection(dbUrl, "root", "");
                PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO Messaggio (mittente_id, destinatario_id, testo) VALUES (?, ?, ?)");
                ps.setInt(1, idUtenteLoggato);
                ps.setInt(2, chatConId);
                ps.setString(3, testo.trim());
                ps.executeUpdate();
                ps.close();
                conn.close();
            } catch (Exception e) {}
        }
        response.sendRedirect("messaggi.jsp?chat=" + chatConId);
        return;
    }
```

Gestisce l'invio di un messaggio: inserisce nella tabella `Messaggio` e reindirizza alla stessa pagina (PRG). Questo evita che il refresh della pagina reinvii il messaggio.

```jsp
    if ("nuova_chat".equals(azione)) {
        int idDestinatario = 0;
        try { idDestinatario = Integer.parseInt(request.getParameter("destinatario")); } catch (Exception e) {}
        ...
        response.sendRedirect("messaggi.jsp?chat=" + idDestinatario);
        return;
    }
```

Gestisce l'avvio di una nuova conversazione. Identica alla logica `invia_messaggio` ma con il destinatario che viene dal form invece che dal parametro URL.

---

### Query conversazioni (sidebar)

```jsp
    PreparedStatement ps = conn.prepareStatement(
        "SELECT u.id_utente, u.username, u.nome_visualizzato, u.avatar_url, " +
        "  (SELECT testo FROM Messaggio m2 WHERE (m2.mittente_id = ? AND m2.destinatario_id = u.id_utente) " +
        "   OR (m2.mittente_id = u.id_utente AND m2.destinatario_id = ?) " +
        "   ORDER BY m2.creato_il DESC LIMIT 1) AS ultimo_msg, " +
        "  (SELECT creato_il FROM Messaggio m2 WHERE ...) AS ultimo_data, " +
        "  (SELECT COUNT(*) FROM Messaggio m3 WHERE m3.mittente_id = u.id_utente " +
        "   AND m3.destinatario_id = ? AND m3.letto = FALSE) AS non_letti " +
        "FROM Utente u " +
        "WHERE u.id_utente IN (" +
        "  SELECT DISTINCT CASE WHEN m.mittente_id = ? THEN m.destinatario_id ELSE m.mittente_id END " +
        "  FROM Messaggio m WHERE m.mittente_id = ? OR m.destinatario_id = ?) " +
        "ORDER BY ultimo_data DESC");
    for (int i = 1; i <= 7; i++) ps.setInt(i, idUtenteLoggato);
```

Query complessa con subquery correlate. Per ogni utente con cui l'utente loggato ha scambiato messaggi:
- `(SELECT testo ... LIMIT 1)` → testo dell'ultimo messaggio
- `(SELECT creato_il ... LIMIT 1)` → data dell'ultimo messaggio
- `(SELECT COUNT(*) ... letto = FALSE)` → messaggi non letti inviati da quell'utente

La subquery nel `WHERE` usa `DISTINCT CASE WHEN` per trovare tutti gli interlocutori: se il mittente è l'utente loggato → prende il destinatario, altrimenti prende il mittente.

`for (int i = 1; i <= 7; i++) ps.setInt(i, idUtenteLoggato)` → imposta tutti e 7 i placeholder `?` con lo stesso valore.

---

### Marcatura messaggi come letti

```jsp
    PreparedStatement psRead = conn.prepareStatement(
        "UPDATE Messaggio SET letto = TRUE WHERE mittente_id = ? AND destinatario_id = ? AND letto = FALSE");
    psRead.setInt(1, chatConId);
    psRead.setInt(2, idUtenteLoggato);
    psRead.executeUpdate();
    psRead.close();
```

Quando l'utente apre una conversazione, tutti i messaggi non letti ricevuti dall'altro utente vengono marcati come letti. Questo aggiorna anche il badge nella navbar (al refresh successivo).

---

### JavaScript per scroll automatico

```javascript
var messagesBody = document.getElementById('messagesBody');
if (messagesBody) {
    messagesBody.scrollTop = messagesBody.scrollHeight;
}
```

Scorre automaticamente al fondo dell'area messaggi quando la pagina si carica, mostrando i messaggi più recenti (comportamento tipico delle chat app).

---

---

# 11 – `network.jsp` — Spiegazione riga per riga

## Scopo del file
Pagina "Rete" dell'utente: mostra i follower, le persone seguite e le conversazioni. Gestisce le azioni di follow/unfollow/messaggio.

---

## Sistema a tab

```jsp
    String tab = request.getParameter("tab");
    if (tab == null) tab = "follower";
```

Il parametro URL `?tab=` seleziona quale sezione mostrare: `follower`, `seguiti` o `messaggi`. Default: `follower`.

---

## Gestione azioni

```jsp
    if (azione != null && idTarget > 0) {
        try {
            Connection conn = DriverManager.getConnection(dbUrl, "root", "");
            
            if ("segui".equals(azione)) {
                PreparedStatement ps = conn.prepareStatement(
                    "INSERT IGNORE INTO Seguito (follower_id, followed_id) VALUES (?, ?)");
```

Gestisce quattro azioni:
- `segui` → INSERT nella tabella Seguito
- `non_seguire` → DELETE dalla tabella Seguito
- `invia_messaggio` → INSERT nella tabella Messaggio
- `elimina_messaggio` → DELETE dalla tabella Messaggio (solo propri messaggi)

---

## Tab Follower

```jsp
    PreparedStatement ps = conn.prepareStatement(
        "SELECT u.id_utente, u.username, u.nome_visualizzato, u.avatar_url, s.creato_il " +
        "FROM Seguito s JOIN Utente u ON s.follower_id = u.id_utente " +
        "WHERE s.followed_id = ? ORDER BY s.creato_il DESC LIMIT 50");
    ps.setInt(1, idUtenteLoggato);
```

Trova tutti gli utenti che seguono l'utente loggato: `WHERE s.followed_id = ?` (io sono il "followed", loro sono i "follower").

## Tab Seguiti

```jsp
    PreparedStatement ps = conn.prepareStatement(
        "SELECT u.id_utente, u.username, u.nome_visualizzato, u.avatar_url, s.creato_il " +
        "FROM Seguito s JOIN Utente u ON s.followed_id = u.id_utente " +
        "WHERE s.follower_id = ? ORDER BY s.creato_il DESC LIMIT 50");
    ps.setInt(1, idUtenteLoggato);
```

Trova tutti gli utenti che l'utente loggato segue: `WHERE s.follower_id = ?` (io sono il "follower", loro sono i "followed").

---

---

# 12 – `modifica_ricetta.jsp` — Spiegazione completa

## Scopo del file
Semplicissimo file di redirect. Non mostra contenuto.

```jsp
<%
    String ctx = request.getContextPath();
    String id = request.getParameter("id");
    if (id == null || id.trim().isEmpty()) {
        response.sendRedirect(ctx + "/crea_ricetta.jsp");
        return;
    }
    response.sendRedirect(ctx + "/crea_ricetta.jsp?modifica=" + id);
%>
```

Redirige a `crea_ricetta.jsp?modifica=ID`. Esiste per mantenere un URL legacy: se qualcuno linkava a `/modifica_ricetta.jsp?id=5`, ora viene rimandato al form unificato.

---

---

# 13 – `createDatabase.jsp` — Spiegazione riga per riga

## Scopo del file
Utility di setup: esegue il file `schema.sql` per creare il database e tutte le tabelle. Va eseguita una volta sola al setup iniziale.

---

## Analisi riga per riga

```jsp
String sqlFile = application.getRealPath("/WEB-INF/sql/schema.sql");
```

`application.getRealPath()` converte un percorso relativo alla web app nel percorso assoluto sul filesystem del server. `application` è l'oggetto implicito JSP `ServletContext`.

```jsp
Connection conn = DriverManager.getConnection(DSN, USER, PASSWORD);
stmt = conn.createStatement();

BufferedReader br = new BufferedReader(new FileReader(sqlFile));
StringBuilder sb = new StringBuilder();
String line;
while ((line = br.readLine()) != null) {
    line = line.trim();
    if (line.isEmpty() || line.startsWith("--")) continue; // ignora commenti e linee vuote
    sb.append(line).append(" ");
    if (line.endsWith(";")) { // fine statement SQL
        stmt.execute(sb.toString());
        sb.setLength(0); // reset buffer
    }
}
```

Legge il file SQL riga per riga:
- Ignora righe vuote e commenti (che iniziano con `--`)
- Accumula righe in uno StringBuilder
- Quando trova un `;` (fine statement SQL), esegue l'istruzione accumulata e svuota il buffer
- Questo gestisce statement SQL che si estendono su più righe (come i `CREATE TABLE`)

**Nota di sicurezza**: questa pagina non ha autenticazione! Chiunque possa raggiungere l'URL `/createDatabase.jsp` può resettare il database. In produzione andrebbe rimossa o protetta.

---

---

# 14 – `recupero_password.jsp` — Nota

## Scopo del file
Placeholder per la funzionalità di recupero password, non ancora implementata.

```jsp
<%@ page contentType="text/html;charset=UTF-8" %>
<!DOCTYPE html>
<html lang="it">
...
<p class="text-muted">La funzione di recupero password non è ancora attiva.</p>
<a href="login.jsp" class="btn-primary">Torna al login</a>
...
```

Non ha codice Java server-side. Mostra solo un messaggio statico e un link di ritorno. Pagina intentionally incompleta (feature non implementata).
