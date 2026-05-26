<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.bakingbread.util.*" %>
<%@ page import="com.bakingbread.model.*" %>
<%--
    ============================================================
    FILE: dettaglio_ricetta.jsp
    SCOPO: Mostra tutti i dettagli di una singola ricetta.
    Parametri GET: ?id=N  (ID della ricetta da visualizzare)
    - Mostra titolo, immagine, autore, ingredienti, passaggi
    - Mostra i commenti (principali + risposte)
    - POST → inserisce un nuovo commento o risposta
    ============================================================
--%>
<%
    response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    String ctx = request.getContextPath();
    Integer idUtenteLoggato = (Integer) session.getAttribute("id_utente");
    if (idUtenteLoggato == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    // Legge l'ID della ricetta dall'URL (?id=N)
    int idRicetta = 0;
    try {
        idRicetta = Integer.parseInt(request.getParameter("id"));
    } catch (Exception e) {
        response.sendRedirect("home.jsp"); // ID mancante o non valido
        return;
    }

    String errorMsg   = "";

    // --------------------------------------------------------
    // GESTIONE POST: inserimento di un commento
    // --------------------------------------------------------
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String testo    = request.getParameter("testo");
        int    idParent = 0;
        try {
            idParent = Integer.parseInt(request.getParameter("id_parent")); // 0 = commento principale
        } catch (Exception e) {
            idParent = 0;
        }

        if (testo != null && !testo.trim().isEmpty()) {
            Connection connPost = null;
            try {
                connPost = Db.getConnection();
                PreparedStatement ps = connPost.prepareStatement(
                    "INSERT INTO Commento (id_ricetta, id_utente, id_parent, testo) VALUES (?,?,?,?)"
                );
                ps.setInt(1, idRicetta);
                ps.setInt(2, idUtenteLoggato);
                // Se idParent è 0, salva NULL nel DB (nessun commento padre)
                if (idParent > 0) {
                    ps.setInt(3, idParent);
                } else {
                    ps.setNull(3, java.sql.Types.INTEGER);
                }
                ps.setString(4, testo.trim());
                ps.executeUpdate();
                ps.close();
            } catch (Exception e) {
                errorMsg = "Errore nell'inserimento del commento.";
            } finally {
                if (connPost != null) { try { connPost.close(); } catch (Exception ignore) {} }
            }
        }
        // Reindirizza alla pagina con ancora #commenti in vista
        response.sendRedirect("dettaglio_ricetta.jsp?id=" + idRicetta + "#commenti");
        return;
    }

    // --------------------------------------------------------
    // CARICAMENTO DATI RICETTA
    // --------------------------------------------------------

    // Dati base della ricetta
    String  rTitolo        = "";
    String  rDescrizione   = "";
    String  rCategoria     = "";
    String  rDifficolta    = "";
    int     rTempoPrep     = 0;
    int     rTempoCottura  = 0;
    int     rPorzioni      = 0;
    String  rImmagineUrl   = "";
    boolean rPubblicata    = true;
    int     rIdAutore      = 0;
    String  rNomeAutore    = "";
    String  rUsernameAutore= "";
    String  rAvatarAutore  = "";
    int     rNumLike       = 0;
    boolean rLikedDaMe     = false;
    boolean rSalvataDaMe   = false;

    // Array per ingredienti, passaggi, commenti
    Ingrediente[]  ingredienti = new Ingrediente[0];
    Passaggio[]    passaggi    = new Passaggio[0];
    Commento[]     commenti    = new Commento[0];

    Connection conn = null;
    try {
        conn = Db.getConnection();

        // ---- Dati base della ricetta ----
        PreparedStatement psR = conn.prepareStatement(
            "SELECT r.titolo, r.descrizione, r.categoria, r.difficolta, " +
            "       r.tempo_preparazione_min, r.tempo_cottura_min, r.porzioni, " +
            "       r.immagine_url, r.pubblicata, " +
            "       u.id_utente AS id_autore, u.nome_visualizzato, u.username, u.avatar_url, " +
            "       COUNT(DISTINCT mp.id_like) AS num_like, " +
            "       SUM(CASE WHEN mp.id_utente = ? THEN 1 ELSE 0 END) AS liked, " +
            "       SUM(CASE WHEN rs.id_utente  = ? THEN 1 ELSE 0 END) AS salvata " +
            "FROM Ricetta r " +
            "JOIN Utente u ON r.id_utente = u.id_utente " +
            "LEFT JOIN MiPiace mp ON r.id_ricetta = mp.id_ricetta " +
            "LEFT JOIN RicettaSalvata rs ON r.id_ricetta = rs.id_ricetta " +
            "WHERE r.id_ricetta = ? " +
            "GROUP BY r.id_ricetta, u.id_utente"
        );
        psR.setInt(1, idUtenteLoggato);
        psR.setInt(2, idUtenteLoggato);
        psR.setInt(3, idRicetta);
        ResultSet rsR = psR.executeQuery();

        if (!rsR.next()) {
            rsR.close(); psR.close(); conn.close();
            response.sendRedirect("home.jsp"); // Ricetta non trovata
            return;
        }

        rTitolo         = rsR.getString("titolo");
        rDescrizione    = rsR.getString("descrizione");
        rCategoria      = rsR.getString("categoria");
        rDifficolta     = rsR.getString("difficolta");
        rTempoPrep      = rsR.getInt("tempo_preparazione_min");
        rTempoCottura   = rsR.getInt("tempo_cottura_min");
        rPorzioni       = rsR.getInt("porzioni");
        rImmagineUrl    = UrlUtils.risolvi(ctx, rsR.getString("immagine_url"));
        rPubblicata     = rsR.getBoolean("pubblicata");
        rIdAutore       = rsR.getInt("id_autore");
        rNomeAutore     = rsR.getString("nome_visualizzato");
        rUsernameAutore = rsR.getString("username");
        rAvatarAutore   = UrlUtils.risolvi(ctx, rsR.getString("avatar_url"));
        rNumLike        = rsR.getInt("num_like");
        rLikedDaMe      = rsR.getInt("liked")   > 0;
        rSalvataDaMe    = rsR.getInt("salvata")  > 0;
        rsR.close(); psR.close();

        // ---- Carica ingredienti: prima conta, poi riempie l'array ----
        PreparedStatement psIC = conn.prepareStatement(
            "SELECT COUNT(*) FROM RicettaIngrediente WHERE id_ricetta = ?"
        );
        psIC.setInt(1, idRicetta);
        ResultSet rsIC = psIC.executeQuery();
        int numIng = 0;
        if (rsIC.next()) { numIng = rsIC.getInt(1); }
        rsIC.close(); psIC.close();

        ingredienti = new Ingrediente[numIng];
        PreparedStatement psIng = conn.prepareStatement(
            "SELECT i.nome, ri.quantita, ri.unita_misura " +
            "FROM RicettaIngrediente ri " +
            "JOIN Ingrediente i ON ri.id_ingrediente = i.id_ingrediente " +
            "WHERE ri.id_ricetta = ? ORDER BY ri.ordine_visualizzazione"
        );
        psIng.setInt(1, idRicetta);
        ResultSet rsIng = psIng.executeQuery();
        int ii = 0;
        while (rsIng.next() && ii < ingredienti.length) {
            Ingrediente ing = new Ingrediente();
            ing.setNome(rsIng.getString("nome"));
            ing.setQuantita(rsIng.getString("quantita"));
            ing.setUnitaMisura(rsIng.getString("unita_misura"));
            ingredienti[ii] = ing;
            ii++;
        }
        rsIng.close(); psIng.close();

        // ---- Carica passaggi ----
        PreparedStatement psPC = conn.prepareStatement(
            "SELECT COUNT(*) FROM RicettaPassaggio WHERE id_ricetta = ?"
        );
        psPC.setInt(1, idRicetta);
        ResultSet rsPC = psPC.executeQuery();
        int numPass = 0;
        if (rsPC.next()) { numPass = rsPC.getInt(1); }
        rsPC.close(); psPC.close();

        passaggi = new Passaggio[numPass];
        PreparedStatement psPass = conn.prepareStatement(
            "SELECT numero_passaggio, descrizione FROM RicettaPassaggio " +
            "WHERE id_ricetta = ? ORDER BY numero_passaggio"
        );
        psPass.setInt(1, idRicetta);
        ResultSet rsPass = psPass.executeQuery();
        int ip = 0;
        while (rsPass.next() && ip < passaggi.length) {
            Passaggio p = new Passaggio();
            p.setOrdine(rsPass.getInt("numero_passaggio"));
            p.setDescrizione(rsPass.getString("descrizione"));
            passaggi[ip] = p;
            ip++;
        }
        rsPass.close(); psPass.close();

        // ---- Carica commenti (tutti: principali + risposte) ----
        PreparedStatement psCC = conn.prepareStatement(
            "SELECT COUNT(*) FROM Commento WHERE id_ricetta = ?"
        );
        psCC.setInt(1, idRicetta);
        ResultSet rsCC = psCC.executeQuery();
        int numCom = 0;
        if (rsCC.next()) { numCom = rsCC.getInt(1); }
        rsCC.close(); psCC.close();

        commenti = new Commento[numCom];
        PreparedStatement psCom = conn.prepareStatement(
            "SELECT c.id_commento, COALESCE(c.id_parent, 0) AS id_parent, " +
            "       c.id_utente, c.testo, c.creato_il, " +
            "       u.nome_visualizzato, u.username, u.avatar_url " +
            "FROM Commento c " +
            "JOIN Utente u ON c.id_utente = u.id_utente " +
            "WHERE c.id_ricetta = ? " +
            "ORDER BY c.creato_il ASC"
        );
        psCom.setInt(1, idRicetta);
        ResultSet rsCom = psCom.executeQuery();
        int ic = 0;
        while (rsCom.next() && ic < commenti.length) {
            Commento c = new Commento();
            c.setIdCommento(rsCom.getInt("id_commento"));
            c.setIdParent(rsCom.getInt("id_parent")); // 0 se è principale
            c.setIdUtente(rsCom.getInt("id_utente"));
            c.setNomeUtente(rsCom.getString("nome_visualizzato"));
            c.setUsername(rsCom.getString("username"));
            c.setAvatarUrl(UrlUtils.risolvi(ctx, rsCom.getString("avatar_url")));
            c.setTesto(rsCom.getString("testo"));
            c.setData(rsCom.getTimestamp("creato_il"));
            commenti[ic] = c;
            ic++;
        }
        rsCom.close(); psCom.close();

    } catch (Exception e) {
        errorMsg = "Errore nel caricamento della ricetta.";
    } finally {
        if (conn != null) { try { conn.close(); } catch (Exception ignore) {} }
    }

    // True se l'utente loggato è l'autore della ricetta
    boolean isMioAutore = (rIdAutore == idUtenteLoggato);
%>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= rTitolo %> - BakingBread</title>
    <link rel="stylesheet" href="<%= ctx %>/css/global.css">
    <link rel="stylesheet" href="<%= ctx %>/css/recipe.css">
    <link rel="icon" href="<%= ctx %>/media/favicon.svg">
</head>
<body>
    <jsp:include page="navbar.jsp" />

    <main class="container page-narrow" style="padding:28px 0 56px;">

        <% if (!errorMsg.isEmpty()) { %>
            <div class="alert alert-error"><%= errorMsg %></div>
        <% } %>

        <%-- ===== INTESTAZIONE RICETTA ===== --%>
        <div class="recipe-detail-header">

            <% if (rImmagineUrl != null && !rImmagineUrl.isEmpty()) { %>
                <div class="recipe-detail-image">
                    <img src="<%= rImmagineUrl %>" alt="<%= rTitolo %>">
                </div>
            <% } %>

            <div class="recipe-detail-meta">
                <% if (rCategoria != null && !rCategoria.isEmpty()) { %>
                    <span class="badge badge-secondary"><%= rCategoria %></span>
                <% } %>
                <h1><%= rTitolo %></h1>
                <% if (rDescrizione != null && !rDescrizione.isEmpty()) { %>
                    <p class="text-muted"><%= rDescrizione %></p>
                <% } %>

                <%-- Autore --%>
                <div class="recipe-detail-author">
                    <a href="profile.jsp?id=<%= rIdAutore %>" class="author-link">
                        <% if (rAvatarAutore != null && !rAvatarAutore.isEmpty()) { %>
                            <img src="<%= rAvatarAutore %>" alt="Avatar" class="avatar-xs">
                        <% } %>
                        <div>
                            <strong><%= rNomeAutore %></strong>
                            <br><small class="text-muted">@<%= rUsernameAutore %></small>
                        </div>
                    </a>
                    <% if (isMioAutore) { %>
                        <a href="crea_ricetta.jsp?modifica=<%= idRicetta %>"
                           class="btn-secondary btn-sm">✏ Modifica</a>
                    <% } %>
                </div>

                <%-- Info rapide: tempo, difficoltà, porzioni --%>
                <div class="recipe-quick-stats">
                    <% if (rTempoPrep > 0) { %>
                        <div class="stat-item"><strong><%= rTempoPrep %>'</strong><span>Prep.</span></div>
                    <% } %>
                    <% if (rTempoCottura > 0) { %>
                        <div class="stat-item"><strong><%= rTempoCottura %>'</strong><span>Cottura</span></div>
                    <% } %>
                    <% if (rPorzioni > 0) { %>
                        <div class="stat-item"><strong><%= rPorzioni %></strong><span>Porzioni</span></div>
                    <% } %>
                    <% if (rDifficolta != null && !rDifficolta.isEmpty()) { %>
                        <div class="stat-item">
                            <strong><%= rDifficolta.substring(0,1).toUpperCase() + rDifficolta.substring(1) %></strong>
                            <span>Difficoltà</span>
                        </div>
                    <% } %>
                </div>

                <%-- Azioni: like e salva --%>
                <div class="recipe-actions">
                    <% if (rLikedDaMe) { %>
                        <a href="home.jsp?azione=mi piace&tipo=rimuovi&id=<%= idRicetta %>" class="action-btn active">
                            ❤ <%= rNumLike %> Mi piace
                        </a>
                    <% } else { %>
                        <a href="home.jsp?azione=mi piace&tipo=aggiungi&id=<%= idRicetta %>" class="action-btn">
                            🤍 <%= rNumLike %> Mi piace
                        </a>
                    <% } %>

                    <% if (rSalvataDaMe) { %>
                        <a href="home.jsp?azione=salva&tipo=rimuovi&id=<%= idRicetta %>" class="action-btn active">
                            🔖 Salvata
                        </a>
                    <% } else { %>
                        <a href="home.jsp?azione=salva&tipo=aggiungi&id=<%= idRicetta %>" class="action-btn">
                            📌 Salva
                        </a>
                    <% } %>
                </div>
            </div>
        </div>

        <%-- ===== INGREDIENTI ===== --%>
        <% if (ingredienti.length > 0) { %>
            <div class="card" style="padding:28px; margin-bottom:24px;">
                <h2>Ingredienti</h2>
                <ul class="ingredients-list">
                    <% for (int i = 0; i < ingredienti.length; i++) { %>
                        <li>
                            <% if (ingredienti[i].getQuantita() != null && !ingredienti[i].getQuantita().isEmpty()) { %>
                                <span class="ingredient-qty">
                                    <%= ingredienti[i].getQuantita() %>
                                    <% if (ingredienti[i].getUnitaMisura() != null && !ingredienti[i].getUnitaMisura().isEmpty()) { %>
                                        <%= ingredienti[i].getUnitaMisura() %>
                                    <% } %>
                                </span>
                            <% } %>
                            <span class="ingredient-name"><%= ingredienti[i].getNome() %></span>
                        </li>
                    <% } %>
                </ul>
            </div>
        <% } %>

        <%-- ===== PASSAGGI ===== --%>
        <% if (passaggi.length > 0) { %>
            <div class="card" style="padding:28px; margin-bottom:24px;">
                <h2>Preparazione</h2>
                <ol class="steps-list">
                    <% for (int i = 0; i < passaggi.length; i++) { %>
                        <li>
                            <div class="step-number-badge"><%= passaggi[i].getOrdine() %></div>
                            <p><%= passaggi[i].getDescrizione() %></p>
                        </li>
                    <% } %>
                </ol>
            </div>
        <% } %>

        <%-- ===== COMMENTI ===== --%>
        <div class="card" id="commenti" style="padding:28px;">
            <h2>Commenti (<%= commenti.length %>)</h2>

            <%-- Form per scrivere un nuovo commento principale --%>
            <form method="POST" action="dettaglio_ricetta.jsp?id=<%= idRicetta %>"
                  class="comment-form" style="margin-bottom:28px;">
                <input type="hidden" name="id_parent" value="0">
                <textarea name="testo" rows="3"
                          placeholder="Scrivi un commento..."
                          required maxlength="2000"></textarea>
                <button type="submit" class="btn-primary btn-sm">Invia commento</button>
            </form>

            <%--
                Ciclo dei commenti:
                Prima mostra i commenti principali (idParent == 0),
                poi per ognuno cerca le risposte nel STESSO array.
                Questo evita di usare ArrayList annidati.
            --%>
            <% for (int i = 0; i < commenti.length; i++) { %>
                <% if (commenti[i].getIdParent() == 0) { %> <%-- Commento principale --%>
                    <div class="comment">
                        <%-- Avatar autore commento --%>
                        <a href="profile.jsp?id=<%= commenti[i].getIdUtente() %>">
                            <% if (commenti[i].getAvatarUrl() != null && !commenti[i].getAvatarUrl().isEmpty()) { %>
                                <img src="<%= commenti[i].getAvatarUrl() %>"
                                     alt="Avatar" class="avatar-sm">
                            <% } else { %>
                                <span class="avatar-sm avatar-fallback">
                                    <%= commenti[i].getNomeUtente().substring(0,1).toUpperCase() %>
                                </span>
                            <% } %>
                        </a>

                        <div class="comment-body">
                            <div class="comment-header">
                                <a href="profile.jsp?id=<%= commenti[i].getIdUtente() %>">
                                    <strong><%= commenti[i].getNomeUtente() %></strong>
                                </a>
                                <% if (commenti[i].getData() != null) { %>
                                    <small class="text-muted">
                                        <%= commenti[i].getData().toString().substring(0, 16) %>
                                    </small>
                                <% } %>
                            </div>
                            <p><%= commenti[i].getTesto() %></p>

                            <%-- Pulsante "Rispondi": mostra/nasconde il form risposta --%>
                            <button type="button"
                                    class="action-btn"
                                    onclick="toggleRispostaForm('reply_<%= commenti[i].getIdCommento() %>')">
                                💬 Rispondi
                            </button>

                            <%-- Form di risposta (nascosto, si mostra al click) --%>
                            <div id="reply_<%= commenti[i].getIdCommento() %>"
                                 style="display:none; margin-top:12px;">
                                <form method="POST"
                                      action="dettaglio_ricetta.jsp?id=<%= idRicetta %>">
                                    <input type="hidden" name="id_parent"
                                           value="<%= commenti[i].getIdCommento() %>">
                                    <textarea name="testo" rows="2"
                                              placeholder="Scrivi una risposta..."
                                              required maxlength="2000"></textarea>
                                    <button type="submit" class="btn-primary btn-sm">
                                        Invia risposta
                                    </button>
                                </form>
                            </div>

                            <%--
                                Cerca le risposte a questo commento scorrendo
                                tutto l'array dei commenti: O(n²) ma funziona
                                senza strutture dati complesse.
                            --%>
                            <% for (int j = 0; j < commenti.length; j++) { %>
                                <% if (commenti[j].getIdParent() == commenti[i].getIdCommento()) { %>
                                    <div class="comment comment-reply">
                                        <a href="profile.jsp?id=<%= commenti[j].getIdUtente() %>">
                                            <% if (commenti[j].getAvatarUrl() != null && !commenti[j].getAvatarUrl().isEmpty()) { %>
                                                <img src="<%= commenti[j].getAvatarUrl() %>"
                                                     alt="Avatar" class="avatar-xs">
                                            <% } else { %>
                                                <span class="avatar-xs avatar-fallback">
                                                    <%= commenti[j].getNomeUtente().substring(0,1).toUpperCase() %>
                                                </span>
                                            <% } %>
                                        </a>
                                        <div class="comment-body">
                                            <div class="comment-header">
                                                <a href="profile.jsp?id=<%= commenti[j].getIdUtente() %>">
                                                    <strong><%= commenti[j].getNomeUtente() %></strong>
                                                </a>
                                                <% if (commenti[j].getData() != null) { %>
                                                    <small class="text-muted">
                                                        <%= commenti[j].getData().toString().substring(0, 16) %>
                                                    </small>
                                                <% } %>
                                            </div>
                                            <p><%= commenti[j].getTesto() %></p>
                                        </div>
                                    </div>
                                <% } %> <%-- fine if risposta --%>
                            <% } %> <%-- fine ciclo risposte --%>

                        </div>
                    </div>
                <% } %> <%-- fine if commento principale --%>
            <% } %> <%-- fine ciclo commenti --%>

            <% if (commenti.length == 0) { %>
                <p class="text-muted" style="text-align:center; padding:20px 0;">
                    Nessun commento ancora. Sii il primo!
                </p>
            <% } %>
        </div>

    </main>

    <script>
        // Mostra o nasconde il form di risposta ad un commento
        function toggleRispostaForm(id) {
            var div = document.getElementById(id); // Trova il div per ID
            if (div.style.display === "none") {
                div.style.display = "block"; // Mostra il form
            } else {
                div.style.display = "none"; // Nasconde il form
            }
        }
    </script>
</body>
</html>
