# 10 – `CommentServlet.java` — Spiegazione riga per riga

## Scopo del file
Servlet che gestisce l'inserimento di un commento (o risposta a un commento) su una ricetta. Riceve il POST dal form commenti di `dettaglio_ricetta.jsp`.

---

## Analisi riga per riga

### Annotazioni

```java
@WebServlet(name = "CommentServlet", urlPatterns = {"/recipe/comment"})
public class CommentServlet extends HttpServlet {
```

Registra la Servlet all'URL `/recipe/comment`. Non ha `@MultipartConfig` perché i commenti sono solo testo (nessun file da caricare).

---

### doPost

```java
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
```

Imposta UTF-8 prima di leggere i parametri. Fondamentale per i commenti in italiano con accenti.

---

### Verifica sessione

```java
        HttpSession session = request.getSession(false);
        Integer idUtente = session != null ? (Integer) session.getAttribute("id_utente") : null;
        if (idUtente == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }
```

Solo gli utenti loggati possono commentare. `getSession(false)` non crea una sessione vuota se non esiste.

---

### Lettura parametri

```java
        int idRicetta = parseInt(request.getParameter("id_ricetta"), 0);
        String testo = safe(request.getParameter("testo"));
        int parentCommento = parseInt(request.getParameter("parent_commento"), 0);
```

- `id_ricetta` → ID della ricetta su cui si commenta (campo hidden nel form)
- `testo` → corpo del commento
- `parent_commento` → se è una risposta, contiene l'ID del commento padre; se è un commento top-level, sarà 0 (il campo non è nel form base)

---

### Validazione

```java
        if (idRicetta <= 0 || testo.isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/dettaglio_ricetta.jsp?id=" + idRicetta + "#commenti");
            return;
        }
```

Se la ricetta non è specificata o il testo è vuoto, redirect alla sezione commenti della ricetta. Il `#commenti` è un **fragment URL**: il browser scorre automaticamente alla sezione con `id="commenti"` nella pagina.

---

### INSERT commento

```java
        try (Connection conn = Db.getConnection();
             PreparedStatement ps = conn.prepareStatement("INSERT INTO Commento (id_ricetta, id_utente, parent_commento, testo) VALUES (?, ?, ?, ?)")) {
            ps.setInt(1, idRicetta);
            ps.setInt(2, idUtente);
            if (parentCommento > 0) ps.setInt(3, parentCommento); else ps.setNull(3, java.sql.Types.INTEGER);
            ps.setString(4, testo);
            ps.executeUpdate();
        } catch (ClassNotFoundException e) {
            throw new ServletException("Driver JDBC non trovato.", e);
        } catch (SQLException e) {
            throw new ServletException("Errore nel salvataggio del commento: " + e.getMessage(), e);
        }
```

**Try-with-resources** con due risorse: `conn` e `ps` vengono entrambe chiuse automaticamente. 

`if (parentCommento > 0) ps.setInt(3, parentCommento); else ps.setNull(3, java.sql.Types.INTEGER)` → gestisce il nullable: il campo `parent_commento` è NULL per i commenti top-level, non zero. Usare 0 violerebbe la foreign key (non esiste un commento con ID 0).

`throw new ServletException(...)` → rilancia l'eccezione come `ServletException` (tipo richiesto dalla firma del metodo). Tomcat la intercetta e mostra la pagina di errore configurata in `web.xml` (redirect a `home.jsp`).

---

### Redirect post-commit

```java
        response.sendRedirect(request.getContextPath() + "/dettaglio_ricetta.jsp?id=" + idRicetta + "#commenti");
```

Redirect PRG alla pagina della ricetta, con ancora il fragment `#commenti` per portare l'utente direttamente alla sezione commenti dopo il refresh.

---

---

# 11 – `FollowServlet.java` — Spiegazione riga per riga

## Scopo del file
Servlet che gestisce il follow/unfollow di un utente. Riceve il POST dai pulsanti "Segui"/"Non seguire" di `profile.jsp`.

---

## Analisi riga per riga

### Verifica utente loggato e parametri

```java
        HttpSession session = request.getSession(false);
        Integer idUtente = session != null ? (Integer) session.getAttribute("id_utente") : null;
        if (idUtente == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        int idProfilo = 0;
        try { idProfilo = Integer.parseInt(request.getParameter("id")); } catch (Exception ignore) {}

        if (idProfilo == 0 || idProfilo == idUtente) {
            response.sendRedirect(request.getContextPath() + "/profile.jsp?id=" + idProfilo);
            return;
        }
```

`idProfilo == idUtente` → previene che un utente segua se stesso. Se l'utente tenta di farlo (manipolando il form), viene semplicemente rimandato al suo profilo senza fare nulla.

---

### Logica follow/unfollow

```java
        String action = request.getParameter("action");

        try (Connection conn = Db.getConnection()) {
            if ("unfollow".equals(action)) {
                try (PreparedStatement ps = conn.prepareStatement(
                        "DELETE FROM Seguito WHERE follower_id = ? AND followed_id = ?")) {
                    ps.setInt(1, idUtente);
                    ps.setInt(2, idProfilo);
                    ps.executeUpdate();
                }
            } else {
                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT IGNORE INTO Seguito (follower_id, followed_id) VALUES (?, ?)")) {
                    ps.setInt(1, idUtente);
                    ps.setInt(2, idProfilo);
                    ps.executeUpdate();
                }
            }
        } catch (Exception ex) {
            throw new ServletException("Errore nel salvataggio del follow: " + ex.getMessage(), ex);
        }
```

- `action = "unfollow"` → DELETE (rimuovi il follow)
- Qualsiasi altro valore (incluso null) → INSERT IGNORE (aggiungi il follow)
- `INSERT IGNORE` → se il follow esiste già (UNIQUE KEY), l'INSERT viene ignorato silenziosamente

---

### Redirect intelligente con Referer

```java
        String referer = request.getHeader("Referer");
        if (referer != null && !referer.isEmpty()) {
            response.sendRedirect(referer);
        } else {
            response.sendRedirect(request.getContextPath() + "/profile.jsp?id=" + idProfilo);
        }
```

`request.getHeader("Referer")` → header HTTP che contiene l'URL della pagina da cui è arrivata la richiesta. Se disponibile, rimanda alla stessa pagina (utile se il follow è stato fatto da una pagina diversa dal profilo, come la pagina network). Come fallback, va al profilo dell'utente seguito.

**Nota**: "Referer" è scritto con un solo 'r' anche nell'HTTP standard (storico errore ortografico nel RFC che è rimasto).

---

---

# 12 – `ProfileUpdateServlet.java` — Spiegazione riga per riga

## Scopo del file
Servlet che aggiorna il profilo utente (nome visualizzato, email, bio, avatar). Gestisce sia l'upload di un file avatar che l'inserimento di un URL avatar.

---

## Annotazioni

```java
@WebServlet(name = "ProfileUpdateServlet", urlPatterns = {"/profile/update"})
@MultipartConfig(maxFileSize = 5 * 1024 * 1024, maxRequestSize = 10 * 1024 * 1024)
public class ProfileUpdateServlet extends HttpServlet {
```

Limite di 5 MB per l'avatar (più conservativo di 8 MB delle ricette, perché gli avatar sono generalmente piccoli).

---

### Lettura parametri e avatar

```java
        String nomeVisualizzato = safe(request.getParameter("nome_visualizzato"));
        String email = safe(request.getParameter("email"));
        String bio = safe(request.getParameter("bio"));
        String currentAvatar = safe(request.getParameter("current_avatar_url"));
        String avatarUrl = currentAvatar;
        String manualAvatarUrl = safe(request.getParameter("avatar_url"));

        try {
            Part avatarPart = request.getPart("avatar_file");
            if (avatarPart != null && avatarPart.getSize() > 0 && avatarPart.getSubmittedFileName() != null && !avatarPart.getSubmittedFileName().trim().isEmpty()) {
                avatarUrl = request.getContextPath() + FileStore.savePart(avatarPart, getServletContext(), "avatars", "avatar_" + idUtente);
            } else if (!manualAvatarUrl.isEmpty()) {
                avatarUrl = manualAvatarUrl;
            }
        } catch (Exception ignore) {
            if (!manualAvatarUrl.isEmpty()) {
                avatarUrl = manualAvatarUrl;
            }
        }
```

Stessa logica di priorità di `RecipeSaveServlet`:
1. File caricato → salva con `FileStore.savePart()` nella cartella `avatars/`
2. URL manuale → usa l'URL inserito
3. Avatar attuale (default) → mantieni quello esistente

`"avatar_" + idUtente` → prefisso per il nome file, es. `"avatar_42"`. Questo raggruppa tutti gli avatar per ID utente nel nome file.

---

### Validazione

```java
        if (nomeVisualizzato.isEmpty() || email.isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/impostazioni.jsp?err=campi");
            return;
        }
```

Validazione minimale: nome e email sono obbligatori. Il parametro `?err=campi` potrebbe essere letto da `impostazioni.jsp` per mostrare un messaggio di errore (non ancora implementato in questa versione della JSP).

---

### UPDATE database

```java
        try (Connection conn = Db.getConnection();
             PreparedStatement ps = conn.prepareStatement("UPDATE Utente SET nome_visualizzato = ?, email = ?, avatar_url = ?, bio = ?, aggiornato_il = NOW() WHERE id_utente = ?")) {
            ps.setString(1, nomeVisualizzato);
            ps.setString(2, email);
            ps.setString(3, avatarUrl.isEmpty() ? null : avatarUrl);
            ps.setString(4, bio.isEmpty() ? null : bio);
            ps.setInt(5, idUtente);
            ps.executeUpdate();
            session.setAttribute("nome_utente", nomeVisualizzato);
            session.setAttribute("avatar_url", avatarUrl);
            response.sendRedirect(request.getContextPath() + "/impostazioni.jsp?ok=1");
        } catch (ClassNotFoundException e) {
            throw new ServletException("Driver JDBC non trovato.", e);
        } catch (SQLException e) {
            response.sendRedirect(request.getContextPath() + "/impostazioni.jsp?err=db");
        }
```

Dopo l'UPDATE:
- `session.setAttribute("nome_utente", nomeVisualizzato)` → aggiorna la sessione con il nuovo nome, così la navbar mostra subito il nome aggiornato senza bisogno di fare logout/login
- `session.setAttribute("avatar_url", avatarUrl)` → stessa cosa per l'avatar
- `?ok=1` → parametro che potrebbe essere usato da impostazioni.jsp per mostrare un messaggio di successo

---

## Flusso completo dei tre servlet

```
POST /recipe/comment
├── Verifica sessione
├── Legge id_ricetta, testo, parent_commento
├── Validazione (ricetta e testo non vuoti)
├── INSERT INTO Commento (con parent NULL se commento top-level)
└── Redirect → /dettaglio_ricetta.jsp?id=X#commenti

POST /profile/follow
├── Verifica sessione
├── Legge id (profilo target)
├── idProfilo==idUtente? → redirect (no self-follow)
├── action="unfollow"? → DELETE FROM Seguito
├── altrimenti → INSERT IGNORE INTO Seguito
└── Redirect al Referer o al profilo

POST /profile/update
├── Verifica sessione
├── Legge nome, email, bio, current_avatar_url, avatar_file, avatar_url
├── Gestisce avatar (file > URL > attuale)
├── Validazione (nome e email obbligatori)
├── UPDATE Utente SET nome=?, email=?, avatar_url=?, bio=?, aggiornato_il=NOW()
├── Aggiorna sessione (nome_utente, avatar_url)
└── Redirect → /impostazioni.jsp?ok=1
```
