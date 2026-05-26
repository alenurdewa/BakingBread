<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.bakingbread.util.*" %>
<%@ page import="com.bakingbread.model.*" %>
<%--
    ============================================================
    FILE: home.jsp
    SCOPO: Mostra il feed principale con le ricette pubblicate.
    - Controlla che l'utente sia loggato
    - Gestisce le azioni "mi piace" e "salva" via parametri GET
    - Carica le ricette dal DB in un array RicettaCard[]
    - Supporta ricerca per titolo tramite parametro "cerca"
    ============================================================
--%>
<%
    // Impedisce la cache del browser
    response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    // Recupera il contextPath per costruire URL corretti
    String ctx = request.getContextPath();

    // Legge l'ID dell'utente dalla sessione
    Integer idUtenteLoggato = (Integer) session.getAttribute("id_utente");

    // Se non loggato, reindirizza al login
    if (idUtenteLoggato == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    // --------------------------------------------------------
    // GESTIONE AZIONI (like e salva tramite link GET)
    // L'utente clicca un pulsante che aggiunge ?azione=...&tipo=...&id=...
    // Elaboriamo l'azione, poi reindirizziamo per evitare ricaricamenti
    // --------------------------------------------------------
    String azione = request.getParameter("azione"); // "mi piace" o "salva"
    String tipo   = request.getParameter("tipo");   // "aggiungi" o "rimuovi"
    int    idTarget = 0;
    try {
        idTarget = Integer.parseInt(request.getParameter("id")); // ID ricetta
    } catch (Exception e) {
        idTarget = 0; // Se il parametro manca o non è un numero, ignoriamo
    }

    // Esegue l'azione solo se tutti i parametri sono validi
    if (azione != null && idTarget > 0) {
        Connection connAzione = null;
        try {
            connAzione = Db.getConnection();

            if ("mi piace".equals(azione)) {
                // Gestione del "Mi piace"
                if ("aggiungi".equals(tipo)) {
                    // INSERT IGNORE: se il like esiste già, non fa nulla
                    PreparedStatement ps = connAzione.prepareStatement(
                        "INSERT IGNORE INTO MiPiace (id_ricetta, id_utente) VALUES (?, ?)"
                    );
                    ps.setInt(1, idTarget);
                    ps.setInt(2, idUtenteLoggato);
                    ps.executeUpdate();
                    ps.close();

                } else if ("rimuovi".equals(tipo)) {
                    PreparedStatement ps = connAzione.prepareStatement(
                        "DELETE FROM MiPiace WHERE id_ricetta = ? AND id_utente = ?"
                    );
                    ps.setInt(1, idTarget);
                    ps.setInt(2, idUtenteLoggato);
                    ps.executeUpdate();
                    ps.close();
                }

            } else if ("salva".equals(azione)) {
                // Gestione del "Salva ricetta"
                if ("aggiungi".equals(tipo)) {
                    PreparedStatement ps = connAzione.prepareStatement(
                        "INSERT IGNORE INTO RicettaSalvata (id_utente, id_ricetta) VALUES (?, ?)"
                    );
                    ps.setInt(1, idUtenteLoggato);
                    ps.setInt(2, idTarget);
                    ps.executeUpdate();
                    ps.close();

                } else if ("rimuovi".equals(tipo)) {
                    PreparedStatement ps = connAzione.prepareStatement(
                        "DELETE FROM RicettaSalvata WHERE id_utente = ? AND id_ricetta = ?"
                    );
                    ps.setInt(1, idUtenteLoggato);
                    ps.setInt(2, idTarget);
                    ps.executeUpdate();
                    ps.close();
                }
            }

        } catch (Exception e) {
            // In caso di errore ignoriamo e continuiamo a caricare la pagina
        } finally {
            if (connAzione != null) {
                try { connAzione.close(); } catch (Exception ignore) {}
            }
        }

        // Reindirizza per pulire i parametri dall'URL (pattern POST-REDIRECT-GET)
        String cerca = request.getParameter("cerca");
        if (cerca != null && !cerca.isEmpty()) {
            response.sendRedirect("home.jsp?cerca=" + java.net.URLEncoder.encode(cerca, "UTF-8"));
        } else {
            response.sendRedirect("home.jsp");
        }
        return;
    }

    // --------------------------------------------------------
    // CARICAMENTO RICETTE DAL DATABASE
    // --------------------------------------------------------

    // Legge il termine di ricerca (se l'utente ha cercato qualcosa)
    String cerca = request.getParameter("cerca");
    if (cerca == null) {
        cerca = ""; // Se non c'è nessun parametro, cerca tutto
    }
    cerca = cerca.trim();

    // Array che conterrà le ricette da mostrare
    RicettaCard[] ricette = new RicettaCard[0]; // Array vuoto come valore di default

    Connection conn = null;
    try {
        conn = Db.getConnection();

        // ---- CONTA QUANTE RICETTE CI SONO ----
        // Serve per creare l'array della dimensione giusta
        int numRicette = 0;
        PreparedStatement psCount;

        if (cerca.isEmpty()) {
            // Senza ricerca: conta tutte le ricette pubblicate
            psCount = conn.prepareStatement(
                "SELECT COUNT(*) FROM Ricetta WHERE pubblicata = TRUE"
            );
        } else {
            // Con ricerca: conta solo quelle che contengono il testo cercato
            psCount = conn.prepareStatement(
                "SELECT COUNT(*) FROM Ricetta WHERE pubblicata = TRUE " +
                "AND (titolo LIKE ? OR descrizione LIKE ?)"
            );
            String pattern = "%" + cerca + "%"; // % è il wildcard SQL per "qualsiasi testo"
            psCount.setString(1, pattern);
            psCount.setString(2, pattern);
        }

        ResultSet rsCount = psCount.executeQuery();
        if (rsCount.next()) {
            numRicette = rsCount.getInt(1); // Legge il numero totale
        }
        rsCount.close();
        psCount.close();

        // Limita a massimo 50 ricette per non sovraccaricare la pagina
        if (numRicette > 50) {
            numRicette = 50;
        }

        // Crea l'array della dimensione esatta
        ricette = new RicettaCard[numRicette];

        // ---- CARICA LE RICETTE CON TUTTI I DETTAGLI ----
        PreparedStatement ps;

        if (cerca.isEmpty()) {
            // Query senza filtro di ricerca
            // Usa GROUP BY per aggregare i conteggi (like, salvataggi)
            ps = conn.prepareStatement(
                "SELECT r.id_ricetta, r.titolo, r.descrizione, r.immagine_url, " +
                "       r.categoria, r.tempo_preparazione_min, r.tempo_cottura_min, " +
                "       r.difficolta, r.porzioni, " +
                "       u.id_utente AS id_autore, u.nome_visualizzato AS nome_autore, " +
                "       u.username AS username_autore, u.avatar_url AS avatar_autore, " +
                "       COUNT(DISTINCT mp.id_like) AS num_like, " +
                "       SUM(CASE WHEN mp.id_utente = ? THEN 1 ELSE 0 END) AS liked, " +
                "       SUM(CASE WHEN rs.id_utente  = ? THEN 1 ELSE 0 END) AS salvata " +
                "FROM Ricetta r " +
                "JOIN Utente u ON r.id_utente = u.id_utente " +
                "LEFT JOIN MiPiace mp ON r.id_ricetta = mp.id_ricetta " +
                "LEFT JOIN RicettaSalvata rs ON r.id_ricetta = rs.id_ricetta " +
                "WHERE r.pubblicata = TRUE " +
                "GROUP BY r.id_ricetta, u.id_utente " +
                "ORDER BY r.creato_il DESC " +
                "LIMIT 50"
            );
            ps.setInt(1, idUtenteLoggato); // Per capire se l'utente ha già messo like
            ps.setInt(2, idUtenteLoggato); // Per capire se l'utente ha già salvato

        } else {
            // Query con filtro di ricerca nel titolo o descrizione
            ps = conn.prepareStatement(
                "SELECT r.id_ricetta, r.titolo, r.descrizione, r.immagine_url, " +
                "       r.categoria, r.tempo_preparazione_min, r.tempo_cottura_min, " +
                "       r.difficolta, r.porzioni, " +
                "       u.id_utente AS id_autore, u.nome_visualizzato AS nome_autore, " +
                "       u.username AS username_autore, u.avatar_url AS avatar_autore, " +
                "       COUNT(DISTINCT mp.id_like) AS num_like, " +
                "       SUM(CASE WHEN mp.id_utente = ? THEN 1 ELSE 0 END) AS liked, " +
                "       SUM(CASE WHEN rs.id_utente  = ? THEN 1 ELSE 0 END) AS salvata " +
                "FROM Ricetta r " +
                "JOIN Utente u ON r.id_utente = u.id_utente " +
                "LEFT JOIN MiPiace mp ON r.id_ricetta = mp.id_ricetta " +
                "LEFT JOIN RicettaSalvata rs ON r.id_ricetta = rs.id_ricetta " +
                "WHERE r.pubblicata = TRUE " +
                "AND (r.titolo LIKE ? OR r.descrizione LIKE ?) " +
                "GROUP BY r.id_ricetta, u.id_utente " +
                "ORDER BY r.creato_il DESC " +
                "LIMIT 50"
            );
            ps.setInt(1, idUtenteLoggato);
            ps.setInt(2, idUtenteLoggato);
            String pattern = "%" + cerca + "%";
            ps.setString(3, pattern);
            ps.setString(4, pattern);
        }

        ResultSet rs = ps.executeQuery();
        int i = 0; // Indice per riempire l'array

        while (rs.next() && i < ricette.length) {
            // Per ogni riga del risultato, crea un oggetto RicettaCard
            RicettaCard card = new RicettaCard();

            card.setIdRicetta(rs.getInt("id_ricetta"));
            card.setTitolo(rs.getString("titolo"));
            card.setDescrizione(rs.getString("descrizione"));
            // Risolve l'URL dell'immagine (aggiunge contextPath se necessario)
            card.setImmagineUrl(UrlUtils.risolvi(ctx, rs.getString("immagine_url")));
            card.setCategoria(rs.getString("categoria"));
            card.setTempoPrep(rs.getInt("tempo_preparazione_min"));
            card.setTempoCottura(rs.getInt("tempo_cottura_min"));
            card.setDifficolta(rs.getString("difficolta"));
            card.setPorzioni(rs.getInt("porzioni"));

            // Dati dell'autore
            card.setIdAutore(rs.getInt("id_autore"));
            card.setNomeAutore(rs.getString("nome_autore"));
            card.setUsernameAutore(rs.getString("username_autore"));
            card.setAvatarAutore(UrlUtils.risolvi(ctx, rs.getString("avatar_autore")));

            // Dati sociali
            card.setNumLike(rs.getInt("num_like"));
            card.setLikedDaMe(rs.getInt("liked") > 0);    // > 0 = l'utente ha messo like
            card.setSalvataDaMe(rs.getInt("salvata") > 0); // > 0 = l'utente ha salvato

            ricette[i] = card; // Salva la card nell'array
            i++;               // Passa alla posizione successiva
        }

        rs.close();
        ps.close();

    } catch (Exception e) {
        // Se c'è un errore, rimane l'array vuoto
    } finally {
        if (conn != null) {
            try { conn.close(); } catch (Exception ignore) {}
        }
    }
%>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Home - BakingBread</title>
    <link rel="stylesheet" href="<%= ctx %>/css/global.css">
    <link rel="stylesheet" href="<%= ctx %>/css/home.css">
    <link rel="icon" href="<%= ctx %>/media/favicon.svg">
</head>
<body>

    <%-- Includi la barra di navigazione --%>
    <jsp:include page="navbar.jsp" />

    <main>
        <div class="feed-container">

            <%-- Intestazione della sezione --%>
            <div class="section-head">
                <div>
                    <p class="eyebrow">Feed</p>
                    <h1>
                        <% if (!cerca.isEmpty()) { %>
                            Risultati per "<%= cerca %>"
                        <% } else { %>
                            Ultime ricette
                        <% } %>
                    </h1>
                </div>
            </div>

            <%-- Ciclo che mostra tutte le ricette nell'array --%>
            <% if (ricette.length == 0) { %>
                <%-- Stato vuoto: nessuna ricetta trovata --%>
                <div class="recipe-empty animate-entrance">
                    <p style="font-size:48px; margin:0;">🍞</p>
                    <h2>Nessuna ricetta trovata</h2>
                    <% if (!cerca.isEmpty()) { %>
                        <p class="text-muted">Nessun risultato per "<%= cerca %>"</p>
                        <a href="home.jsp" class="btn-secondary mt-3">Vedi tutte le ricette</a>
                    <% } else { %>
                        <p class="text-muted">Sii il primo a pubblicare una ricetta!</p>
                        <a href="crea_ricetta.jsp" class="btn-primary mt-3">Crea una ricetta</a>
                    <% } %>
                </div>

            <% } else { %>
                <%-- Ciclo sull'array: mostra ogni ricetta come card --%>
                <% for (int i = 0; i < ricette.length; i++) { %>
                    <%-- Variabile locale per leggere più facilmente la ricetta corrente --%>
                    <% RicettaCard r = ricette[i]; %>

                    <article class="recipe-card animate-entrance">

                        <%-- Intestazione card: avatar e nome autore --%>
                        <div class="recipe-card-header">
                            <a href="<%= ctx %>/profile.jsp?id=<%= r.getIdAutore() %>"
                               class="recipe-card-avatar">
                                <% if (r.getAvatarAutore() != null && !r.getAvatarAutore().isEmpty()) { %>
                                    <img src="<%= r.getAvatarAutore() %>" alt="Avatar">
                                <% } else { %>
                                    <%= r.getNomeAutore() != null && !r.getNomeAutore().isEmpty()
                                        ? r.getNomeAutore().substring(0, 1).toUpperCase() : "U" %>
                                <% } %>
                            </a>
                            <div class="recipe-card-author">
                                <a href="<%= ctx %>/profile.jsp?id=<%= r.getIdAutore() %>">
                                    <%= r.getNomeAutore() %>
                                </a>
                                <small>@<%= r.getUsernameAutore() %></small>
                            </div>
                            <% if (r.getCategoria() != null && !r.getCategoria().isEmpty()) { %>
                                <span class="badge badge-secondary"><%= r.getCategoria() %></span>
                            <% } %>
                        </div>

                        <%-- Immagine della ricetta (se presente) --%>
                        <% if (r.getImmagineUrl() != null && !r.getImmagineUrl().isEmpty()) { %>
                            <a href="<%= ctx %>/dettaglio_ricetta.jsp?id=<%= r.getIdRicetta() %>"
                               class="recipe-card-image">
                                <img src="<%= r.getImmagineUrl() %>"
                                     alt="<%= r.getTitolo() %>"
                                     style="width:100%; height:100%; object-fit:cover;">
                            </a>
                        <% } %>

                        <%-- Corpo della card: titolo, descrizione, meta-info --%>
                        <div class="recipe-card-body">
                            <a href="<%= ctx %>/dettaglio_ricetta.jsp?id=<%= r.getIdRicetta() %>"
                               class="recipe-card-title">
                                <%= r.getTitolo() %>
                            </a>
                            <% if (r.getDescrizione() != null && !r.getDescrizione().isEmpty()) { %>
                                <p class="recipe-card-desc"><%= r.getDescrizione() %></p>
                            <% } %>

                            <%-- Informazioni rapide: tempo, difficoltà, porzioni --%>
                            <div class="recipe-card-meta">
                                <% if (r.getTempoPrep() > 0 || r.getTempoCottura() > 0) { %>
                                    <span>⏱ <%= r.getTempoPrep() + r.getTempoCottura() %> min</span>
                                <% } %>
                                <% if (r.getDifficolta() != null && !r.getDifficolta().isEmpty()) { %>
                                    <span>📊 <%= r.getDifficolta() %></span>
                                <% } %>
                                <% if (r.getPorzioni() > 0) { %>
                                    <span>🍽 <%= r.getPorzioni() %> porzioni</span>
                                <% } %>
                            </div>
                        </div>

                        <%-- Footer della card: pulsanti like, salva, commenta --%>
                        <div class="recipe-card-footer">

                            <%-- Pulsante Mi Piace --%>
                            <% if (r.isLikedDaMe()) { %>
                                <%-- L'utente ha già messo like: cliccando lo rimuove --%>
                                <a href="home.jsp?azione=mi piace&tipo=rimuovi&id=<%= r.getIdRicetta() %><%= !cerca.isEmpty() ? "&cerca=" + java.net.URLEncoder.encode(cerca, "UTF-8") : "" %>"
                                   class="action-btn active">
                                    ❤ <%= r.getNumLike() %> Mi piace
                                </a>
                            <% } else { %>
                                <%-- L'utente non ha ancora messo like --%>
                                <a href="home.jsp?azione=mi piace&tipo=aggiungi&id=<%= r.getIdRicetta() %><%= !cerca.isEmpty() ? "&cerca=" + java.net.URLEncoder.encode(cerca, "UTF-8") : "" %>"
                                   class="action-btn">
                                    🤍 <%= r.getNumLike() %> Mi piace
                                </a>
                            <% } %>

                            <%-- Pulsante Salva --%>
                            <% if (r.isSalvataDaMe()) { %>
                                <a href="home.jsp?azione=salva&tipo=rimuovi&id=<%= r.getIdRicetta() %><%= !cerca.isEmpty() ? "&cerca=" + java.net.URLEncoder.encode(cerca, "UTF-8") : "" %>"
                                   class="action-btn active">
                                    🔖 Salvata
                                </a>
                            <% } else { %>
                                <a href="home.jsp?azione=salva&tipo=aggiungi&id=<%= r.getIdRicetta() %><%= !cerca.isEmpty() ? "&cerca=" + java.net.URLEncoder.encode(cerca, "UTF-8") : "" %>"
                                   class="action-btn">
                                    📌 Salva
                                </a>
                            <% } %>

                            <%-- Pulsante Commenta --%>
                            <a href="<%= ctx %>/dettaglio_ricetta.jsp?id=<%= r.getIdRicetta() %>#commenti"
                               class="action-btn">
                                💬 Commenta
                            </a>
                        </div>

                    </article>
                <% } %> <%-- fine for --%>
            <% } %> <%-- fine if ricette.length --%>

        </div>
    </main>

    <script src="<%= ctx %>/js/home.js"></script>
</body>
</html>
