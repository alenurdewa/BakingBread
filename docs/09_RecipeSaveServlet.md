# 09 – `RecipeSaveServlet.java` — Spiegazione riga per riga

## Scopo del file
Servlet che gestisce il salvataggio (creazione e modifica) di una ricetta. Riceve i dati dal form di `crea_ricetta.jsp`, gestisce l'upload dell'immagine, salva tutto nel database in un'unica **transazione atomica** (ingredienti, passaggi, ricetta), e reindirizza alla pagina di dettaglio.

---

## Struttura generale

```
RecipeSaveServlet.java
├── Annotazioni @WebServlet e @MultipartConfig
├── Classe interna IngredientRow (DTO)
└── doPost()
    ├── Verifica sessione utente
    ├── Lettura parametri form
    ├── Apertura connessione DB con transazione
    ├── Se editing: UPDATE + DELETE ingredienti/passaggi
    ├── Se nuovo: INSERT + recupero ID generato
    ├── Salvataggio ingredienti (con ensureIngredient)
    ├── Salvataggio passaggi
    ├── Commit transazione
    └── Redirect a dettaglio_ricetta.jsp
```

---

## Analisi riga per riga

### Package e import

```java
package com.bakingbread.web;
```

Il package indica la struttura delle cartelle: questa classe si trova in `src/java/com/bakingbread/web/`. I package in Java servono a organizzare il codice e a evitare conflitti di nomi.

```java
import com.bakingbread.util.Db;
import com.bakingbread.util.FileStore;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;
```

- `com.bakingbread.util.Db` → helper del progetto per aprire la connessione DB
- `com.bakingbread.util.FileStore` → helper per salvare file su disco
- `javax.servlet.*` → API standard Java EE per le Servlet
- `javax.servlet.http.Part` → rappresenta una parte di un form multipart (file caricato)

---

### Annotazioni della classe

```java
@WebServlet(name = "RecipeSaveServlet", urlPatterns = {"/recipe/save"})
@MultipartConfig(maxFileSize = 8 * 1024 * 1024, maxRequestSize = 20 * 1024 * 1024)
public class RecipeSaveServlet extends HttpServlet {
```

**`@WebServlet`**: registra questa Servlet all'URL `/recipe/save`. È alternativo alla configurazione in `web.xml` (che in questo progetto è usata entrambe le modi). L'annotazione ha precedenza bassa rispetto al `web.xml`.

**`@MultipartConfig`**: abilita il supporto per `multipart/form-data` (form con upload di file). Senza questa annotazione, `request.getPart()` lancerebbe un'eccezione. Parametri:
- `maxFileSize = 8 * 1024 * 1024` → dimensione massima del singolo file: **8 MB** (8 × 1024 × 1024 = 8.388.608 byte)
- `maxRequestSize = 20 * 1024 * 1024` → dimensione massima della intera richiesta: **20 MB**

**`extends HttpServlet`**: ogni Servlet HTTP deve estendere questa classe base. Fornisce metodi come `doGet()`, `doPost()`, ecc. da sovrascrivere.

---

### Classe interna IngredientRow

```java
private static final class IngredientRow {
    final String nome;
    final String quantita;
    final String unita;
    IngredientRow(String nome, String quantita, String unita) {
        this.nome = nome;
        this.quantita = quantita;
        this.unita = unita;
    }
}
```

Classe interna statica (`static`) che funge da semplice contenitore dati (DTO - Data Transfer Object) per un ingrediente. `final` sui campi indica che non cambiano dopo la costruzione (immutabilità). `private static final class` significa: privata alla classe esterna, statica (non ha riferimento all'istanza esterna), e non sottoclassabile. Usata per raccogliere i dati degli ingredienti prima di salvarli nel DB.

---

### Firma del metodo doPost

```java
@Override
protected void doPost(HttpServletRequest request, HttpServletResponse response) 
        throws ServletException, IOException {
    request.setCharacterEncoding("UTF-8");
    response.setCharacterEncoding("UTF-8");
```

`@Override` indica che questo metodo sovrascrive quello della superclasse `HttpServlet`. Tomcat chiama `doPost()` automaticamente quando arriva una richiesta HTTP POST all'URL `/recipe/save`. 

`setCharacterEncoding("UTF-8")` va impostato **prima** di leggere qualsiasi parametro; altrimenti i caratteri speciali (accenti, ecc.) nelle stringhe del form potrebbero essere corrotti.

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

`request.getSession(false)` → ottiene la sessione esistente senza crearne una nuova. Se la sessione non esiste, ritorna `null`. Con `true` creerebbe una sessione vuota se non esiste. L'operatore ternario evita NullPointerException: se `session` è null, non si tenta `.getAttribute()`.

---

### Lettura parametri del form

```java
    int idRicetta = parseInt(request.getParameter("id_ricetta"), 0);
    boolean editing = idRicetta > 0;

    String titolo = safe(request.getParameter("titolo"));
    String descrizione = safe(request.getParameter("descrizione"));
    String categoria = safe(request.getParameter("categoria"));
    int prep = parseInt(request.getParameter("tempo_preparazione"), 0);
    int cottura = parseInt(request.getParameter("tempo_cottura"), 0);
    int porzioni = Math.max(1, parseInt(request.getParameter("porzioni"), 4));
    String difficolta = safe(request.getParameter("difficolta"));
    String dieta = safe(request.getParameter("dieta"));
    boolean pubblica = request.getParameter("pubblica") != null;
    String currentImageUrl = safe(request.getParameter("current_image_url"));
    String manualImageUrl = safe(request.getParameter("immagine_url"));
    String imageUrl = currentImageUrl;
```

- `idRicetta > 0` → se > 0, siamo in modalità editing
- `safe()` → metodo privato che converte null in "" e fa trim()
- `parseInt()` → metodo privato che parsa la stringa o ritorna il default
- `Math.max(1, ...)` → assicura almeno 1 porzione
- `pubblica = request.getParameter("pubblica") != null` → le checkbox HTML inviano il parametro solo se spuntate; se non spuntata, `getParameter` ritorna null. Quindi `!= null` equivale a "checkbox spuntata"
- `imageUrl = currentImageUrl` → valore iniziale: mantieni l'immagine attuale; verrà sovrascritto se si carica una nuova

---

### Gestione upload immagine

```java
    Part imagePart = null;
    try {
        imagePart = request.getPart("recipe_image_file");
    } catch (Exception ignore) {
        imagePart = null;
    }
```

`request.getPart("recipe_image_file")` → recupera la parte del form multipart corrispondente all'input file con `name="recipe_image_file"`. Può lanciare eccezione se il form non è multipart o se c'è un problema nell'upload.

---

### Validazione titolo

```java
    if (titolo.isEmpty()) {
        response.sendRedirect(request.getContextPath() + "/crea_ricetta.jsp?errore=1");
        return;
    }
```

Unica validazione server-side qui: il titolo non può essere vuoto. In un'app reale ci sarebbero più validazioni.

---

### Transazione database

```java
    try (Connection conn = Db.getConnection()) {
        conn.setAutoCommit(false);
        int savedRecipeId = idRicetta;
        try {
            // ... tutte le operazioni DB ...
            conn.commit();
            response.sendRedirect(request.getContextPath() + "/dettaglio_ricetta.jsp?id=" + savedRecipeId);
        } catch (Exception ex) {
            try { conn.rollback(); } catch (SQLException ignore) {}
            throw new ServletException("Errore nel salvataggio della ricetta: " + ex.getMessage(), ex);
        } finally {
            try { conn.setAutoCommit(true); } catch (SQLException ignore) {}
        }
    }
```

**Transazione**: gruppo di operazioni DB che vengono eseguite tutte o nessuna (atomicità).

- `conn.setAutoCommit(false)` → disabilita il commit automatico. Di default MySQL fa commit dopo ogni istruzione; qui vogliamo controllarlo manualmente.
- `conn.commit()` → rende permanenti tutte le operazioni della transazione se tutto va bene
- `conn.rollback()` → annulla tutte le operazioni se c'è un errore (la ricetta non viene salvata a metà)
- `conn.setAutoCommit(true)` nel finally → ripristina il comportamento normale

**Perché la transazione è importante qui?** Si salvano dati su più tabelle (Ricetta, RicettaIngrediente, Passaggio). Se il salvataggio degli ingredienti fallisse dopo aver creato la ricetta, ci sarebbe una ricetta senza ingredienti. Con la transazione, o tutto viene salvato o nulla.

**Try-with-resources** (`try (Connection conn = ...)`): Java 7+ feature. La connessione viene chiusa automaticamente all'uscita dal blocco try, anche in caso di eccezione. Equivale a mettere `conn.close()` in un blocco finally.

---

### Salvataggio immagine

```java
            if (imagePart != null && imagePart.getSize() > 0 && imagePart.getSubmittedFileName() != null && !imagePart.getSubmittedFileName().trim().isEmpty()) {
                imageUrl = request.getContextPath() + FileStore.savePart(imagePart, getServletContext(), "recipes", "ricetta_" + idUtente);
            } else if (!manualImageUrl.isEmpty()) {
                imageUrl = manualImageUrl;
            }
```

Priorità per l'immagine:
1. **File uploadato**: solo se `size > 0` e ha un nome → salva con `FileStore.savePart()` e costruisce l'URL
2. **URL manuale**: se non c'è file ma c'è un URL inserito manualmente
3. **currentImageUrl** (default impostato prima): mantieni l'immagine attuale

---

### Modalità EDITING: UPDATE + DELETE

```java
                if (editing) {
                    try (PreparedStatement ps = conn.prepareStatement(
                            "UPDATE Ricetta SET titolo = ?, descrizione = ?, categoria = ?, " +
                            "tempo_preparazione_min = ?, tempo_cottura_min = ?, porzioni = ?, " +
                            "difficolta = ?, dieta = ?, immagine_url = ?, pubblicata = ?, " +
                            "aggiornato_il = NOW() " +
                            "WHERE id_ricetta = ? AND id_utente = ?")) {
                        ps.setString(1, titolo);
                        ps.setString(2, descrizione);
                        ps.setString(3, categoria.isEmpty() ? null : categoria);
                        if (prep > 0) ps.setInt(4, prep); else ps.setNull(4, java.sql.Types.INTEGER);
                        if (cottura > 0) ps.setInt(5, cottura); else ps.setNull(5, java.sql.Types.INTEGER);
                        ps.setInt(6, porzioni);
                        ps.setString(7, difficolta.isEmpty() ? "facile" : difficolta);
                        ps.setString(8, dieta.isEmpty() ? null : dieta);
                        ps.setString(9, imageUrl.isEmpty() ? null : imageUrl);
                        ps.setBoolean(10, pubblica);
                        ps.setInt(11, idRicetta);
                        ps.setInt(12, idUtente);  // ← sicurezza: solo il proprietario può modificare
                        if (ps.executeUpdate() == 0) {
                            throw new SQLException("Ricetta non trovata o non autorizzata.");
                        }
                    }
```

`WHERE id_ricetta = ? AND id_utente = ?` → doppia condizione di sicurezza. Se `executeUpdate()` ritorna 0, nessuna riga è stata aggiornata: o la ricetta non esiste o appartiene a qualcun altro. In questo caso viene lanciata un'eccezione che triggera il rollback.

`ps.setNull(4, java.sql.Types.INTEGER)` → imposta esplicitamente NULL nel campo numerico se il valore è 0 (tempo non specificato). Necessario perché `PreparedStatement` non accetta direttamente `null` per un campo `int`.

```java
                    try (PreparedStatement ps = conn.prepareStatement("DELETE FROM RicettaIngrediente WHERE id_ricetta = ?")) {
                        ps.setInt(1, idRicetta);
                        ps.executeUpdate();
                    }
                    try (PreparedStatement ps = conn.prepareStatement("DELETE FROM Passaggio WHERE id_ricetta = ?")) {
                        ps.setInt(1, idRicetta);
                        ps.executeUpdate();
                    }
```

**Strategia delete-and-reinsert**: invece di fare un diff tra ingredienti/passaggi vecchi e nuovi, si eliminano tutti e si reinseriscono. Più semplice da implementare e corretto perché l'ordine e le quantità possono cambiare arbitrariamente. I DELETE non preoccupano per la consistenza perché siamo in una transazione.

---

### Modalità CREAZIONE: INSERT con chiave generata

```java
                } else {
                    try (PreparedStatement ps = conn.prepareStatement(
                            "INSERT INTO Ricetta (...) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                            PreparedStatement.RETURN_GENERATED_KEYS)) {
                        // ... setString/setInt per ogni campo ...
                        ps.executeUpdate();
                        try (ResultSet rs = ps.getGeneratedKeys()) {
                            if (rs.next()) {
                                savedRecipeId = rs.getInt(1);
                            } else {
                                throw new SQLException("Impossibile recuperare l'ID della ricetta.");
                            }
                        }
                    }
                }
```

`PreparedStatement.RETURN_GENERATED_KEYS` → indica al driver JDBC di restituire la chiave auto-generata dopo l'INSERT. Poi `ps.getGeneratedKeys()` restituisce un ResultSet con l'ID generato da MySQL (`AUTO_INCREMENT`). `rs.getInt(1)` legge il primo campo (l'ID). Questo ID sarà usato per inserire ingredienti e passaggi.

---

### Salvataggio ingredienti

```java
                List<IngredientRow> ingredienti = new ArrayList<IngredientRow>();
                String[] ingredientiNome = request.getParameterValues("ingrediente_nome");
                String[] ingredientiQta = request.getParameterValues("ingrediente_quantita");
                String[] ingredientiUnita = request.getParameterValues("ingrediente_unita");
                if (ingredientiNome != null) {
                    for (int i = 0; i < ingredientiNome.length; i++) {
                        String nome = safe(ingredientiNome[i]);
                        if (!nome.isEmpty()) {
                            String qta = ingredientiQta != null && ingredientiQta.length > i ? safe(ingredientiQta[i]) : "";
                            String unita = ingredientiUnita != null && ingredientiUnita.length > i ? safe(ingredientiUnita[i]) : "";
                            ingredienti.add(new IngredientRow(nome, qta, unita));
                        }
                    }
                }
```

`request.getParameterValues("ingrediente_nome")` → quando ci sono più campi con lo stesso `name` nel form (la lista dinamica di ingredienti), questo metodo ritorna un array con tutti i valori. I tre array corrispondono alle tre colonne di ogni riga ingrediente.

Il controllo `ingredientiQta.length > i` gestisce il caso in cui gli array abbiano lunghezze diverse (es. se il campo quantità è vuoto viene omesso dalla richiesta in alcuni browser).

```java
                for (int i = 0; i < ingredienti.size(); i++) {
                    IngredientRow row = ingredienti.get(i);
                    int idIngrediente = ensureIngredient(conn, row.nome);
                    try (PreparedStatement ps = conn.prepareStatement(
                            "INSERT INTO RicettaIngrediente (id_ricetta, id_ingrediente, quantita, unita_misura, ordine_visualizzazione) VALUES (?, ?, ?, ?, ?)")) {
                        ps.setInt(1, savedRecipeId);
                        ps.setInt(2, idIngrediente);
                        ps.setString(3, row.quantita.isEmpty() ? null : row.quantita);
                        ps.setString(4, row.unita.isEmpty() ? null : row.unita);
                        ps.setInt(5, i + 1);  // ordine 1-based
                        ps.executeUpdate();
                    }
                }
```

Per ogni ingrediente:
1. `ensureIngredient(conn, row.nome)` → trova o crea l'ingrediente nella tabella `Ingrediente`
2. Inserisce il collegamento ricetta-ingrediente in `RicettaIngrediente` con quantità, unità e ordine

`ordine_visualizzazione = i + 1` (1-based invece di 0-based) per avere un ordine intuitivo (Ingrediente 1, 2, 3...).

---

### Metodo ensureIngredient

```java
    private int ensureIngredient(Connection conn, String nome) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement("SELECT id_ingrediente FROM Ingrediente WHERE nome = ?")) {
            ps.setString(1, nome);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        }
        try (PreparedStatement ps = conn.prepareStatement("INSERT INTO Ingrediente (nome) VALUES (?)", PreparedStatement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, nome);
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) return rs.getInt(1);
            }
        }
        throw new SQLException("Impossibile salvare l'ingrediente: " + nome);
    }
```

Pattern **"trova o crea"** (upsert semplificato):
1. Cerca l'ingrediente per nome
2. Se trovato → ritorna l'ID esistente
3. Se non trovato → lo inserisce e ritorna il nuovo ID

Questo mantiene la tabella `Ingrediente` normalizzata: lo stesso ingrediente (es. "Farina") non viene duplicato anche se usato da molte ricette. La chiave `UNIQUE` sul nome in `Ingrediente` garantisce l'unicità a livello di database.

---

### Salvataggio passaggi

```java
                String[] passaggi = request.getParameterValues("passaggio_descrizione");
                if (passaggi != null) {
                    int ordine = 1;
                    for (String raw : passaggi) {
                        String descr = safe(raw);
                        if (!descr.isEmpty()) {
                            try (PreparedStatement ps = conn.prepareStatement(
                                    "INSERT INTO Passaggio (id_ricetta, ordine, descrizione) VALUES (?, ?, ?)")) {
                                ps.setInt(1, savedRecipeId);
                                ps.setInt(2, ordine++);
                                ps.setString(3, descr);
                                ps.executeUpdate();
                            }
                        }
                    }
                }
```

I passaggi vengono inseriti nell'ordine in cui compaiono nel form. `ordine++` usa il valore corrente e poi incrementa (post-increment).

---

### Metodi privati helper

```java
    private static String safe(String value) {
        return value == null ? "" : value.trim();
    }

    private static int parseInt(String value, int defaultValue) {
        try { return Integer.parseInt(value); } catch (Exception ex) { return defaultValue; }
    }
```

Due helper statici riutilizzabili in tutta la Servlet:
- `safe()` → converte null in "" e rimuove spazi bianchi
- `parseInt()` → converte stringa in int con valore di default (invece di lanciare eccezione su input non valido)

---

## Flusso completo RecipeSaveServlet

```
POST /recipe/save
├── Verifica sessione → redirect login se non loggato
├── Legge parametri form (titolo, categoria, tempi, ingredienti[], passaggi[], file)
├── editing = (idRicetta > 0)
├── titolo.isEmpty() → redirect errore
├── Apre connessione DB, setAutoCommit(false)
├── Salva immagine (file upload > URL manuale > immagine attuale)
├── Se editing:
│   ├── UPDATE Ricetta WHERE id_ricetta=? AND id_utente=?
│   ├── DELETE RicettaIngrediente WHERE id_ricetta=?
│   └── DELETE Passaggio WHERE id_ricetta=?
├── Se nuovo:
│   ├── INSERT INTO Ricetta (tutti i campi)
│   └── Recupera ID generato (RETURN_GENERATED_KEYS)
├── Per ogni ingrediente:
│   ├── ensureIngredient() → SELECT o INSERT nella tabella Ingrediente
│   └── INSERT INTO RicettaIngrediente
├── Per ogni passaggio:
│   └── INSERT INTO Passaggio
├── conn.commit() → rende tutto permanente
└── Redirect → /dettaglio_ricetta.jsp?id=[savedRecipeId]

Se qualsiasi operazione fallisce:
└── conn.rollback() → annulla tutto
```
