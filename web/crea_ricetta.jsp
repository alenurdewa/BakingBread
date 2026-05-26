<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="javax.servlet.http.Part" %>
<%@ page import="com.bakingbread.util.*" %>
<%@ page import="com.bakingbread.model.*" %>
<%--
    ============================================================
    FILE: crea_ricetta.jsp
    SCOPO: Form per creare una nuova ricetta o modificarne una.
    - Se URL contiene ?modifica=N → carica i dati esistenti
    - GET  → mostra il form (vuoto o precompilato)
    - POST → salva la ricetta nel database con ingredienti e step
    La pagina gestisce anche l'upload dell'immagine di copertina
    tramite la classe FileStore.
    ============================================================
--%>
<%
    response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    String ctx = request.getContextPath();

    // Verifica che l'utente sia loggato
    Integer idUtenteLoggato = (Integer) session.getAttribute("id_utente");
    if (idUtenteLoggato == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String errorMsg   = "";
    String successMsg = "";

    // --------------------------------------------------------
    // Legge il parametro "modifica": se presente siamo in
    // modalità modifica di una ricetta esistente
    // --------------------------------------------------------
    int idRicettaModifica = 0; // 0 = nuova ricetta
    String modificaParam = request.getParameter("modifica");
    if (modificaParam != null && !modificaParam.trim().isEmpty()) {
        try {
            idRicettaModifica = Integer.parseInt(modificaParam.trim());
        } catch (NumberFormatException e) {
            idRicettaModifica = 0; // Parametro non valido: crea nuova ricetta
        }
    }

    boolean isModifica = (idRicettaModifica > 0); // True se stiamo modificando

    // --------------------------------------------------------
    // Variabili del form (precompilate in modifica, vuote in crea)
    // --------------------------------------------------------
    String   fTitolo        = "";
    String   fDescrizione   = "";
    String   fCategoria     = "";
    String   fDifficolta    = "facile";
    int      fTempoPrep     = 0;
    int      fTempoCottura  = 0;
    int      fPorzioni      = 4;
    String   fImmagineUrl   = "";
    boolean  fPubblicata    = true;

    // Array di stringhe per gli ingredienti pre-esistenti
    String[] fIngNomi      = new String[0];
    String[] fIngQuantita  = new String[0];
    String[] fIngUnita     = new String[0];

    // Array di stringhe per i passaggi pre-esistenti
    String[] fPassaggi     = new String[0];

    // --------------------------------------------------------
    // GESTIONE POST: salva la ricetta
    // --------------------------------------------------------
    if ("POST".equalsIgnoreCase(request.getMethod())) {

        // Legge i campi del form
        String titolo       = request.getParameter("titolo");
        String descrizione  = request.getParameter("descrizione");
        String categoria    = request.getParameter("categoria");
        String difficolta   = request.getParameter("difficolta");
        String tempoPrepStr = request.getParameter("tempo_preparazione");
        String tempoCotStr  = request.getParameter("tempo_cottura");
        String porzioniStr  = request.getParameter("porzioni");
        String immagineUrl  = request.getParameter("immagine_url");
        boolean pubblicata  = "on".equals(request.getParameter("pubblicata"));

        // Legge gli array di ingredienti (ogni campo è un array di valori)
        // getParameterValues restituisce già String[] senza bisogno di ArrayList
        String[] ingNomi     = request.getParameterValues("ingrediente_nome");
        String[] ingQuantita = request.getParameterValues("ingrediente_quantita");
        String[] ingUnita    = request.getParameterValues("ingrediente_unita");

        // Legge l'array dei passaggi
        String[] passaggi = request.getParameterValues("passaggio_descrizione");

        // Validazione dei campi obbligatori
        if (titolo == null || titolo.trim().isEmpty()) {
            errorMsg = "Il titolo è obbligatorio.";
        } else {
            // Conversione stringhe → numeri interi (con valore di default se non valido)
            int tempoPrep    = 0;
            int tempoCottura = 0;
            int porzioni     = 4;
            try { tempoPrep    = Integer.parseInt(tempoPrepStr); } catch (Exception e) {}
            try { tempoCottura = Integer.parseInt(tempoCotStr);  } catch (Exception e) {}
            try { porzioni     = Integer.parseInt(porzioniStr);  } catch (Exception e) {}

            Connection conn = null;
            try {
                conn = Db.getConnection();
                conn.setAutoCommit(false); // Avvia una transazione: o tutto o niente

                // ---- Gestisce l'upload dell'immagine di copertina ----
                String nuovaImmagineUrl = immagineUrl; // parte dal valore URL inserito
                try {
                    Part immaginePart = request.getPart("immagine_file");
                    String immagineSalvata = FileStore.salva(
                        immaginePart,
                        application,
                        "recipes",
                        "recipe_" + idUtenteLoggato
                    );
                    // Se è stato caricato un file, ha la priorità sull'URL inserito
                    if (immagineSalvata != null) {
                        nuovaImmagineUrl = immagineSalvata;
                    }
                } catch (Exception uploadEx) {
                    // Nessun file caricato: usa l'URL inserito nel form
                }

                int idRicettaFinale; // ID della ricetta salvata (nuovo o aggiornato)

                if (isModifica) {
                    // ---- MODALITÀ MODIFICA: verifica proprietà e aggiorna ----

                    // Controlla che questa ricetta appartenga all'utente loggato
                    PreparedStatement psCheck = conn.prepareStatement(
                        "SELECT id_utente FROM Ricetta WHERE id_ricetta = ?"
                    );
                    psCheck.setInt(1, idRicettaModifica);
                    ResultSet rsCheck = psCheck.executeQuery();
                    boolean proprietario = false;
                    if (rsCheck.next()) {
                        proprietario = (rsCheck.getInt("id_utente") == idUtenteLoggato);
                    }
                    rsCheck.close();
                    psCheck.close();

                    if (!proprietario) {
                        // Non è il proprietario: errore di sicurezza
                        conn.rollback();
                        errorMsg = "Non sei autorizzato a modificare questa ricetta.";
                        conn.close();
                        conn = null;
                        return; // Blocca l'esecuzione
                    }

                    // Aggiorna i campi della ricetta nel DB
                    PreparedStatement psUpd = conn.prepareStatement(
                        "UPDATE Ricetta SET titolo=?, descrizione=?, categoria=?, difficolta=?, " +
                        "tempo_preparazione_min=?, tempo_cottura_min=?, porzioni=?, " +
                        "immagine_url=?, pubblicata=? WHERE id_ricetta=?"
                    );
                    psUpd.setString(1, titolo.trim());
                    psUpd.setString(2, descrizione != null ? descrizione.trim() : "");
                    psUpd.setString(3, categoria);
                    psUpd.setString(4, difficolta);
                    psUpd.setInt(5, tempoPrep);
                    psUpd.setInt(6, tempoCottura);
                    psUpd.setInt(7, porzioni);
                    psUpd.setString(8, nuovaImmagineUrl != null ? nuovaImmagineUrl.trim() : "");
                    psUpd.setBoolean(9, pubblicata);
                    psUpd.setInt(10, idRicettaModifica);
                    psUpd.executeUpdate();
                    psUpd.close();

                    idRicettaFinale = idRicettaModifica;

                    // Elimina ingredienti e passaggi vecchi per reinserirli aggiornati
                    PreparedStatement psDelIng = conn.prepareStatement(
                        "DELETE FROM RicettaIngrediente WHERE id_ricetta = ?"
                    );
                    psDelIng.setInt(1, idRicettaFinale);
                    psDelIng.executeUpdate();
                    psDelIng.close();

                    PreparedStatement psDelPass = conn.prepareStatement(
                        "DELETE FROM RicettaPassaggio WHERE id_ricetta = ?"
                    );
                    psDelPass.setInt(1, idRicettaFinale);
                    psDelPass.executeUpdate();
                    psDelPass.close();

                } else {
                    // ---- MODALITÀ CREAZIONE: inserisce una nuova ricetta ----
                    PreparedStatement psIns = conn.prepareStatement(
                        "INSERT INTO Ricetta (id_utente, titolo, descrizione, categoria, " +
                        "difficolta, tempo_preparazione_min, tempo_cottura_min, porzioni, " +
                        "immagine_url, pubblicata) VALUES (?,?,?,?,?,?,?,?,?,?)",
                        PreparedStatement.RETURN_GENERATED_KEYS
                    );
                    psIns.setInt(1, idUtenteLoggato);
                    psIns.setString(2, titolo.trim());
                    psIns.setString(3, descrizione != null ? descrizione.trim() : "");
                    psIns.setString(4, categoria);
                    psIns.setString(5, difficolta);
                    psIns.setInt(6, tempoPrep);
                    psIns.setInt(7, tempoCottura);
                    psIns.setInt(8, porzioni);
                    psIns.setString(9, nuovaImmagineUrl != null ? nuovaImmagineUrl.trim() : "");
                    psIns.setBoolean(10, pubblicata);
                    psIns.executeUpdate();

                    // Recupera l'ID auto-generato per la nuova ricetta
                    ResultSet rsKeys = psIns.getGeneratedKeys();
                    idRicettaFinale = 0;
                    if (rsKeys.next()) {
                        idRicettaFinale = rsKeys.getInt(1);
                    }
                    rsKeys.close();
                    psIns.close();
                }

                // ---- Inserisce gli ingredienti ----
                if (ingNomi != null) {
                    // Ordine di visualizzazione (inizia da 1)
                    int ordineIng = 1;

                    for (int i = 0; i < ingNomi.length; i++) {
                        // Salta ingredienti con nome vuoto
                        if (ingNomi[i] == null || ingNomi[i].trim().isEmpty()) {
                            continue; // Passa al prossimo elemento
                        }

                        // Recupera quantità e unità per questo ingrediente
                        String qta   = (ingQuantita != null && i < ingQuantita.length) ? ingQuantita[i] : "";
                        String unita = (ingUnita    != null && i < ingUnita.length)    ? ingUnita[i]    : "";

                        // Prima cerca se l'ingrediente esiste già nella tabella Ingrediente
                        String nomeIng = ingNomi[i].trim();
                        int idIngrediente = 0;

                        PreparedStatement psCercaIng = conn.prepareStatement(
                            "SELECT id_ingrediente FROM Ingrediente WHERE LOWER(nome) = LOWER(?)"
                        );
                        psCercaIng.setString(1, nomeIng);
                        ResultSet rsCercaIng = psCercaIng.executeQuery();

                        if (rsCercaIng.next()) {
                            // Ingrediente già esistente: recupera il suo ID
                            idIngrediente = rsCercaIng.getInt("id_ingrediente");
                        } else {
                            // Ingrediente nuovo: inserisce nella tabella Ingrediente
                            PreparedStatement psNuovoIng = conn.prepareStatement(
                                "INSERT INTO Ingrediente (nome) VALUES (?)",
                                PreparedStatement.RETURN_GENERATED_KEYS
                            );
                            psNuovoIng.setString(1, nomeIng);
                            psNuovoIng.executeUpdate();
                            ResultSet rsNuovoIng = psNuovoIng.getGeneratedKeys();
                            if (rsNuovoIng.next()) {
                                idIngrediente = rsNuovoIng.getInt(1);
                            }
                            rsNuovoIng.close();
                            psNuovoIng.close();
                        }
                        rsCercaIng.close();
                        psCercaIng.close();

                        // Collega l'ingrediente alla ricetta con quantità e ordine
                        PreparedStatement psCollegaIng = conn.prepareStatement(
                            "INSERT INTO RicettaIngrediente " +
                            "(id_ricetta, id_ingrediente, quantita, unita_misura, ordine_visualizzazione) " +
                            "VALUES (?, ?, ?, ?, ?)"
                        );
                        psCollegaIng.setInt(1, idRicettaFinale);
                        psCollegaIng.setInt(2, idIngrediente);
                        psCollegaIng.setString(3, qta != null   ? qta.trim()   : "");
                        psCollegaIng.setString(4, unita != null ? unita.trim() : "");
                        psCollegaIng.setInt(5, ordineIng);
                        psCollegaIng.executeUpdate();
                        psCollegaIng.close();

                        ordineIng++; // Incrementa l'ordine per il prossimo ingrediente
                    }
                }

                // ---- Inserisce i passaggi ----
                if (passaggi != null) {
                    int ordinePass = 1; // Numero del passaggio (1, 2, 3...)

                    for (int i = 0; i < passaggi.length; i++) {
                        // Salta passaggi vuoti
                        if (passaggi[i] == null || passaggi[i].trim().isEmpty()) {
                            continue;
                        }

                        PreparedStatement psPass = conn.prepareStatement(
                            "INSERT INTO RicettaPassaggio (id_ricetta, numero_passaggio, descrizione) " +
                            "VALUES (?, ?, ?)"
                        );
                        psPass.setInt(1, idRicettaFinale);
                        psPass.setInt(2, ordinePass);
                        psPass.setString(3, passaggi[i].trim());
                        psPass.executeUpdate();
                        psPass.close();

                        ordinePass++;
                    }
                }

                // Tutto eseguito senza errori: conferma la transazione
                conn.commit();
                conn.close();
                conn = null;

                // Reindirizza al dettaglio della ricetta appena salvata
                response.sendRedirect("dettaglio_ricetta.jsp?id=" + idRicettaFinale);
                return;

            } catch (Exception e) {
                // Qualcosa è andato storto: annulla tutto (rollback)
                if (conn != null) {
                    try { conn.rollback(); } catch (Exception ignore) {}
                }
                errorMsg = "Errore durante il salvataggio. Riprova.";
            } finally {
                if (conn != null) {
                    try { conn.close(); } catch (Exception ignore) {}
                }
            }
        }

        // Se c'è stato un errore, ricarica i valori inviati nel form
        fTitolo      = request.getParameter("titolo")      != null ? request.getParameter("titolo")      : "";
        fDescrizione = request.getParameter("descrizione") != null ? request.getParameter("descrizione") : "";
        fCategoria   = request.getParameter("categoria")   != null ? request.getParameter("categoria")   : "";
        fDifficolta  = request.getParameter("difficolta")  != null ? request.getParameter("difficolta")  : "facile";
        fImmagineUrl = request.getParameter("immagine_url") != null ? request.getParameter("immagine_url") : "";
        try { fTempoPrep    = Integer.parseInt(request.getParameter("tempo_preparazione")); } catch (Exception e) {}
        try { fTempoCottura = Integer.parseInt(request.getParameter("tempo_cottura"));      } catch (Exception e) {}
        try { fPorzioni     = Integer.parseInt(request.getParameter("porzioni"));           } catch (Exception e) {}
        fIngNomi     = request.getParameterValues("ingrediente_nome")     != null ? request.getParameterValues("ingrediente_nome")     : new String[0];
        fIngQuantita = request.getParameterValues("ingrediente_quantita") != null ? request.getParameterValues("ingrediente_quantita") : new String[0];
        fIngUnita    = request.getParameterValues("ingrediente_unita")    != null ? request.getParameterValues("ingrediente_unita")    : new String[0];
        fPassaggi    = request.getParameterValues("passaggio_descrizione") != null ? request.getParameterValues("passaggio_descrizione") : new String[0];

    } else if (isModifica) {
        // --------------------------------------------------------
        // GET con ?modifica=N: precompila il form con i dati
        // della ricetta esistente
        // --------------------------------------------------------
        Connection conn = null;
        try {
            conn = Db.getConnection();

            // Carica i dati base della ricetta
            PreparedStatement ps = conn.prepareStatement(
                "SELECT id_utente, titolo, descrizione, categoria, difficolta, " +
                "tempo_preparazione_min, tempo_cottura_min, porzioni, immagine_url, pubblicata " +
                "FROM Ricetta WHERE id_ricetta = ?"
            );
            ps.setInt(1, idRicettaModifica);
            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                // Verifica che l'utente loggato sia il proprietario
                if (rs.getInt("id_utente") != idUtenteLoggato) {
                    rs.close(); ps.close(); conn.close();
                    response.sendRedirect("home.jsp"); // Non autorizzato
                    return;
                }
                fTitolo      = rs.getString("titolo");
                fDescrizione = rs.getString("descrizione");
                fCategoria   = rs.getString("categoria");
                fDifficolta  = rs.getString("difficolta");
                fTempoPrep   = rs.getInt("tempo_preparazione_min");
                fTempoCottura= rs.getInt("tempo_cottura_min");
                fPorzioni    = rs.getInt("porzioni");
                fImmagineUrl = rs.getString("immagine_url");
                fPubblicata  = rs.getBoolean("pubblicata");
            } else {
                rs.close(); ps.close(); conn.close();
                response.sendRedirect("home.jsp"); // Ricetta non trovata
                return;
            }
            rs.close();
            ps.close();

            // Carica gli ingredienti esistenti
            PreparedStatement psIng = conn.prepareStatement(
                "SELECT i.nome, ri.quantita, ri.unita_misura " +
                "FROM RicettaIngrediente ri " +
                "JOIN Ingrediente i ON ri.id_ingrediente = i.id_ingrediente " +
                "WHERE ri.id_ricetta = ? ORDER BY ri.ordine_visualizzazione"
            );
            psIng.setInt(1, idRicettaModifica);
            ResultSet rsIng = psIng.executeQuery();

            // Prima conta quanti ingredienti ci sono
            int cntIng = 0;
            while (rsIng.next()) { cntIng++; }
            rsIng.close();
            psIng.close();

            // Crea array della dimensione giusta e li riempie
            fIngNomi     = new String[cntIng];
            fIngQuantita = new String[cntIng];
            fIngUnita    = new String[cntIng];

            PreparedStatement psIng2 = conn.prepareStatement(
                "SELECT i.nome, ri.quantita, ri.unita_misura " +
                "FROM RicettaIngrediente ri " +
                "JOIN Ingrediente i ON ri.id_ingrediente = i.id_ingrediente " +
                "WHERE ri.id_ricetta = ? ORDER BY ri.ordine_visualizzazione"
            );
            psIng2.setInt(1, idRicettaModifica);
            ResultSet rsIng2 = psIng2.executeQuery();
            int ii = 0;
            while (rsIng2.next()) {
                fIngNomi[ii]     = rsIng2.getString("nome");
                fIngQuantita[ii] = rsIng2.getString("quantita");
                fIngUnita[ii]    = rsIng2.getString("unita_misura");
                ii++;
            }
            rsIng2.close();
            psIng2.close();

            // Carica i passaggi esistenti
            PreparedStatement psPass = conn.prepareStatement(
                "SELECT descrizione FROM RicettaPassaggio " +
                "WHERE id_ricetta = ? ORDER BY numero_passaggio"
            );
            psPass.setInt(1, idRicettaModifica);
            ResultSet rsPass = psPass.executeQuery();

            // Prima conta
            int cntPass = 0;
            while (rsPass.next()) { cntPass++; }
            rsPass.close();
            psPass.close();

            fPassaggi = new String[cntPass];

            PreparedStatement psPass2 = conn.prepareStatement(
                "SELECT descrizione FROM RicettaPassaggio " +
                "WHERE id_ricetta = ? ORDER BY numero_passaggio"
            );
            psPass2.setInt(1, idRicettaModifica);
            ResultSet rsPass2 = psPass2.executeQuery();
            int ip = 0;
            while (rsPass2.next()) {
                fPassaggi[ip] = rsPass2.getString("descrizione");
                ip++;
            }
            rsPass2.close();
            psPass2.close();

        } catch (Exception e) {
            errorMsg = "Errore nel caricamento della ricetta.";
        } finally {
            if (conn != null) {
                try { conn.close(); } catch (Exception ignore) {}
            }
        }
    }

    // Assicura che gli array abbiano almeno 1 elemento da mostrare
    if (fIngNomi.length == 0) {
        fIngNomi     = new String[]{ "" };
        fIngQuantita = new String[]{ "" };
        fIngUnita    = new String[]{ "" };
    }
    if (fPassaggi.length == 0) {
        fPassaggi = new String[]{ "" };
    }

    // Valori nulli diventano stringhe vuote per evitare errori nel HTML
    if (fTitolo      == null) { fTitolo      = ""; }
    if (fDescrizione == null) { fDescrizione = ""; }
    if (fCategoria   == null) { fCategoria   = ""; }
    if (fImmagineUrl == null) { fImmagineUrl = ""; }
%>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= isModifica ? "Modifica ricetta" : "Crea ricetta" %> - BakingBread</title>
    <link rel="stylesheet" href="<%= ctx %>/css/global.css">
    <link rel="stylesheet" href="<%= ctx %>/css/recipe.css">
    <link rel="icon" href="<%= ctx %>/media/favicon.svg">
</head>
<body>
    <jsp:include page="navbar.jsp" />

    <main class="container page-narrow" style="padding:28px 0 56px;">

        <div class="section-head" style="margin-bottom:24px;">
            <div>
                <p class="eyebrow"><%= isModifica ? "Modifica" : "Nuova ricetta" %></p>
                <h1 style="margin:0;"><%= isModifica ? "Aggiorna la ricetta" : "Crea una ricetta" %></h1>
            </div>
        </div>

        <% if (!errorMsg.isEmpty()) { %>
            <div class="alert alert-error" style="margin-bottom:20px;">⚠ <%= errorMsg %></div>
        <% } %>

        <%-- Form multipart per supportare l'upload dell'immagine --%>
        <form method="POST"
              action="crea_ricetta.jsp<%= isModifica ? "?modifica=" + idRicettaModifica : "" %>"
              enctype="multipart/form-data"
              id="ricettaForm">

            <%-- ===== SEZIONE: INFO BASE ===== --%>
            <div class="card" style="margin-bottom:24px; padding:28px;">
                <h2 style="margin:0 0 20px;">Informazioni base</h2>

                <div class="form-group">
                    <label for="titolo">Titolo ricetta *</label>
                    <input type="text" id="titolo" name="titolo" required maxlength="150"
                           value="<%= fTitolo %>">
                </div>

                <div class="form-group">
                    <label for="descrizione">Descrizione</label>
                    <textarea id="descrizione" name="descrizione" rows="3"
                              maxlength="1000"><%= fDescrizione %></textarea>
                </div>

                <div class="form-grid-3">
                    <div class="form-group">
                        <label for="categoria">Categoria</label>
                        <select id="categoria" name="categoria">
                            <option value="">-- Scegli --</option>
                            <% String[] categorie = {"antipasto","primo","secondo","contorno","dolce","pane","pizza","bevanda","altro"}; %>
                            <% for (int i = 0; i < categorie.length; i++) { %>
                                <option value="<%= categorie[i] %>"
                                    <%= fCategoria.equals(categorie[i]) ? "selected" : "" %>>
                                    <%= categorie[i].substring(0,1).toUpperCase() + categorie[i].substring(1) %>
                                </option>
                            <% } %>
                        </select>
                    </div>
                    <div class="form-group">
                        <label for="difficolta">Difficoltà</label>
                        <select id="difficolta" name="difficolta">
                            <option value="facile"   <%= "facile".equals(fDifficolta)   ? "selected" : "" %>>Facile</option>
                            <option value="media"    <%= "media".equals(fDifficolta)    ? "selected" : "" %>>Media</option>
                            <option value="difficile"<%= "difficile".equals(fDifficolta)? "selected" : "" %>>Difficile</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label for="porzioni">Porzioni</label>
                        <input type="number" id="porzioni" name="porzioni" min="1" max="50"
                               value="<%= fPorzioni %>">
                    </div>
                </div>

                <div class="form-grid-2">
                    <div class="form-group">
                        <label for="tempo_preparazione">Tempo preparazione (min)</label>
                        <input type="number" id="tempo_preparazione" name="tempo_preparazione"
                               min="0" max="999" value="<%= fTempoPrep %>">
                    </div>
                    <div class="form-group">
                        <label for="tempo_cottura">Tempo cottura (min)</label>
                        <input type="number" id="tempo_cottura" name="tempo_cottura"
                               min="0" max="999" value="<%= fTempoCottura %>">
                    </div>
                </div>
            </div>

            <%-- ===== SEZIONE: IMMAGINE ===== --%>
            <div class="card" style="margin-bottom:24px; padding:28px;">
                <h2 style="margin:0 0 20px;">Immagine di copertina</h2>
                <div class="form-group">
                    <label for="immagine_file">Carica un'immagine</label>
                    <input type="file" id="immagine_file" name="immagine_file" accept="image/*">
                </div>
                <div class="form-group">
                    <label for="immagine_url">Oppure incolla un URL immagine</label>
                    <input type="url" id="immagine_url" name="immagine_url"
                           placeholder="https://..." value="<%= fImmagineUrl %>">
                </div>
                <div class="form-check">
                    <input type="checkbox" id="pubblicata" name="pubblicata"
                           <%= fPubblicata ? "checked" : "" %>>
                    <label for="pubblicata">Pubblica la ricetta (visibile a tutti)</label>
                </div>
            </div>

            <%-- ===== SEZIONE: INGREDIENTI ===== --%>
            <div class="card" style="margin-bottom:24px; padding:28px;">
                <div class="section-head" style="margin-bottom:20px;">
                    <h2 style="margin:0;">Ingredienti</h2>
                    <button type="button" class="btn-secondary btn-sm" onclick="aggiungiIngrediente()">
                        + Aggiungi
                    </button>
                </div>

                <%-- Lista ingredienti generata dal server (precompilata in modifica) --%>
                <div id="listaIngredienti">
                    <% for (int i = 0; i < fIngNomi.length; i++) { %>
                        <div class="ingredient-row" id="ing_<%= i %>">
                            <input type="text"   name="ingrediente_nome"
                                   placeholder="Es. Farina 00"
                                   value="<%= fIngNomi[i] != null ? fIngNomi[i] : "" %>">
                            <input type="text"   name="ingrediente_quantita"
                                   placeholder="Quantità"
                                   value="<%= fIngQuantita[i] != null ? fIngQuantita[i] : "" %>">
                            <input type="text"   name="ingrediente_unita"
                                   placeholder="Unità (g, ml...)"
                                   value="<%= fIngUnita[i] != null ? fIngUnita[i] : "" %>">
                            <button type="button" class="btn-danger btn-sm"
                                    onclick="rimuoviRiga(this)">✕</button>
                        </div>
                    <% } %>
                </div>
            </div>

            <%-- ===== SEZIONE: PASSAGGI ===== --%>
            <div class="card" style="margin-bottom:24px; padding:28px;">
                <div class="section-head" style="margin-bottom:20px;">
                    <h2 style="margin:0;">Passaggi di preparazione</h2>
                    <button type="button" class="btn-secondary btn-sm" onclick="aggiungiPassaggio()">
                        + Aggiungi
                    </button>
                </div>

                <div id="listaPassaggi">
                    <% for (int i = 0; i < fPassaggi.length; i++) { %>
                        <div class="step-row" id="pass_<%= i %>">
                            <%-- Numero del passaggio (visivo, non inviato al server) --%>
                            <span class="step-number"><%= i + 1 %></span>
                            <textarea name="passaggio_descrizione"
                                      rows="3"
                                      placeholder="Descrivi questo passaggio..."><%= fPassaggi[i] != null ? fPassaggi[i] : "" %></textarea>
                            <button type="button" class="btn-danger btn-sm"
                                    onclick="rimuoviRiga(this)">✕</button>
                        </div>
                    <% } %>
                </div>
            </div>

            <%-- Pulsanti finali --%>
            <div class="form-actions">
                <a href="<%= isModifica ? "dettaglio_ricetta.jsp?id=" + idRicettaModifica : "home.jsp" %>"
                   class="btn-secondary">Annulla</a>
                <button type="submit" class="btn-primary">
                    <%= isModifica ? "Salva modifiche" : "Pubblica ricetta" %>
                </button>
            </div>

        </form>
    </main>

    <script src="<%= ctx %>/js/recipe.js"></script>
</body>
</html>
