<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.bakingbread.util.*" %>
<%@ page import="com.bakingbread.model.*" %>
<%--
    ============================================================
    FILE: network.jsp
    SCOPO: Mostra e gestisce i follower e i seguiti.
    GET ?id=N      → mostra il network dell'utente N (o del loggato)
    GET ?tab=X     → "follower" o "seguiti" (tab attiva)
    GET ?segui=N   → segui l'utente N
    GET ?smetti=N  → smetti di seguire l'utente N
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

    // Utente di cui visualizzare il network (default: se stesso)
    int idProfilo = idUtenteLoggato;
    String idParam = request.getParameter("id");
    if (idParam != null && !idParam.trim().isEmpty()) {
        try { idProfilo = Integer.parseInt(idParam.trim()); } catch (Exception e) {}
    }

    // Tab attiva: "follower" oppure "seguiti"
    String tab = "seguiti"; // Default: mostra i seguiti
    String tabParam = request.getParameter("tab");
    if ("follower".equals(tabParam)) {
        tab = "follower";
    }

    // --------------------------------------------------------
    // GESTIONE FOLLOW/UNFOLLOW VIA GET
    // --------------------------------------------------------
    int segui  = 0;
    int smetti = 0;
    try { segui  = Integer.parseInt(request.getParameter("segui"));  } catch (Exception e) {}
    try { smetti = Integer.parseInt(request.getParameter("smetti")); } catch (Exception e) {}

    if (segui > 0 && segui != idUtenteLoggato) {
        // Segui un utente
        Connection connF = null;
        try {
            connF = Db.getConnection();
            PreparedStatement ps = connF.prepareStatement(
                "INSERT IGNORE INTO Seguito (follower_id, followed_id) VALUES (?, ?)"
            );
            ps.setInt(1, idUtenteLoggato); // Chi segue
            ps.setInt(2, segui);           // Chi viene seguito
            ps.executeUpdate(); ps.close();
        } catch (Exception e) {
        } finally {
            if (connF != null) { try { connF.close(); } catch (Exception ignore) {} }
        }
        response.sendRedirect("network.jsp?id=" + idProfilo + "&tab=" + tab);
        return;
    }

    if (smetti > 0 && smetti != idUtenteLoggato) {
        // Smetti di seguire
        Connection connF = null;
        try {
            connF = Db.getConnection();
            PreparedStatement ps = connF.prepareStatement(
                "DELETE FROM Seguito WHERE follower_id = ? AND followed_id = ?"
            );
            ps.setInt(1, idUtenteLoggato);
            ps.setInt(2, smetti);
            ps.executeUpdate(); ps.close();
        } catch (Exception e) {
        } finally {
            if (connF != null) { try { connF.close(); } catch (Exception ignore) {} }
        }
        response.sendRedirect("network.jsp?id=" + idProfilo + "&tab=" + tab);
        return;
    }

    // --------------------------------------------------------
    // CARICAMENTO UTENTI
    // --------------------------------------------------------

    UtenteCard[] utenti = new UtenteCard[0]; // Array che conterrà la lista
    String nomeProfilo  = ""; // Nome del profilo visualizzato

    Connection conn = null;
    try {
        conn = Db.getConnection();

        // Recupera il nome del profilo visualizzato
        PreparedStatement psNome = conn.prepareStatement(
            "SELECT nome_visualizzato FROM Utente WHERE id_utente = ?"
        );
        psNome.setInt(1, idProfilo);
        ResultSet rsNome = psNome.executeQuery();
        if (rsNome.next()) { nomeProfilo = rsNome.getString("nome_visualizzato"); }
        rsNome.close(); psNome.close();

        // Query diversa in base alla tab selezionata
        String query;
        if ("follower".equals(tab)) {
            // Chi SEGUE questo profilo
            query = "SELECT u.id_utente, u.username, u.nome_visualizzato, u.avatar_url, " +
                    "  (SELECT COUNT(*) FROM Seguito WHERE follower_id = ? AND followed_id = u.id_utente) AS seguo " +
                    "FROM Seguito s " +
                    "JOIN Utente u ON s.follower_id = u.id_utente " +
                    "WHERE s.followed_id = ? " +
                    "ORDER BY u.nome_visualizzato";
        } else {
            // Chi questo profilo SEGUE
            query = "SELECT u.id_utente, u.username, u.nome_visualizzato, u.avatar_url, " +
                    "  (SELECT COUNT(*) FROM Seguito WHERE follower_id = ? AND followed_id = u.id_utente) AS seguo " +
                    "FROM Seguito s " +
                    "JOIN Utente u ON s.followed_id = u.id_utente " +
                    "WHERE s.follower_id = ? " +
                    "ORDER BY u.nome_visualizzato";
        }

        // ---- Conta prima per dimensionare l'array ----
        PreparedStatement psCount = conn.prepareStatement(
            "SELECT COUNT(*) FROM (" + query + ") AS sub"
        );
        psCount.setInt(1, idUtenteLoggato); // Per il controllo "seguo"
        psCount.setInt(2, idProfilo);       // Per la condizione WHERE
        ResultSet rsCount = psCount.executeQuery();
        int numUtenti = 0;
        if (rsCount.next()) { numUtenti = rsCount.getInt(1); }
        rsCount.close(); psCount.close();

        utenti = new UtenteCard[numUtenti];

        // ---- Carica la lista ----
        PreparedStatement ps = conn.prepareStatement(query);
        ps.setInt(1, idUtenteLoggato);
        ps.setInt(2, idProfilo);
        ResultSet rs = ps.executeQuery();
        int i = 0;
        while (rs.next() && i < utenti.length) {
            UtenteCard uc = new UtenteCard();
            uc.setIdUtente(rs.getInt("id_utente"));
            uc.setUsername(rs.getString("username"));
            uc.setNomeVisualizzato(rs.getString("nome_visualizzato"));
            uc.setAvatarUrl(UrlUtils.risolvi(ctx, rs.getString("avatar_url")));
            uc.setFollowDaMe(rs.getInt("seguo") > 0); // True se lo seguo già
            utenti[i] = uc;
            i++;
        }
        rs.close(); ps.close();

    } catch (Exception e) {
        // In caso di errore l'array rimane vuoto
    } finally {
        if (conn != null) { try { conn.close(); } catch (Exception ignore) {} }
    }
%>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Network - BakingBread</title>
    <link rel="stylesheet" href="<%= ctx %>/css/global.css">
    <link rel="stylesheet" href="<%= ctx %>/css/profile.css">
    <link rel="icon" href="<%= ctx %>/media/favicon.svg">
</head>
<body>
    <jsp:include page="navbar.jsp" />

    <main class="container page-narrow" style="padding:28px 0 56px;">

        <div class="section-head" style="margin-bottom:24px;">
            <div>
                <p class="eyebrow">
                    <a href="profile.jsp?id=<%= idProfilo %>"><%= nomeProfilo %></a>
                </p>
                <h1 style="margin:0;">Network</h1>
            </div>
        </div>

        <%-- Tabs di navigazione: Seguiti / Follower --%>
        <div class="tab-row" style="margin-bottom:24px;">
            <a href="network.jsp?id=<%= idProfilo %>&tab=seguiti"
               class="tab-btn <%= "seguiti".equals(tab) ? "active" : "" %>">
                Seguiti
            </a>
            <a href="network.jsp?id=<%= idProfilo %>&tab=follower"
               class="tab-btn <%= "follower".equals(tab) ? "active" : "" %>">
                Follower
            </a>
        </div>

        <%-- Lista utenti --%>
        <% if (utenti.length == 0) { %>
            <div class="card" style="padding:40px; text-align:center;">
                <% if ("follower".equals(tab)) { %>
                    <p class="text-muted">Nessun follower ancora.</p>
                <% } else { %>
                    <p class="text-muted">Non segue ancora nessuno.</p>
                    <% if (idProfilo == idUtenteLoggato) { %>
                        <p class="text-muted">Trova persone interessanti nella home!</p>
                        <a href="home.jsp" class="btn-primary btn-sm mt-3">Esplora</a>
                    <% } %>
                <% } %>
            </div>
        <% } else { %>
            <div class="user-list">
                <% for (int i = 0; i < utenti.length; i++) { %>
                    <% UtenteCard u = utenti[i]; %>
                    <div class="user-list-item card">
                        <%-- Avatar --%>
                        <a href="profile.jsp?id=<%= u.getIdUtente() %>" class="user-avatar-link">
                            <% if (u.getAvatarUrl() != null && !u.getAvatarUrl().isEmpty()) { %>
                                <img src="<%= u.getAvatarUrl() %>" alt="Avatar" class="avatar-md">
                            <% } else { %>
                                <span class="avatar-md avatar-fallback">
                                    <%= u.getNomeVisualizzato() != null
                                        ? u.getNomeVisualizzato().substring(0,1).toUpperCase() : "U" %>
                                </span>
                            <% } %>
                        </a>

                        <%-- Nome e username --%>
                        <div style="flex:1; min-width:0;">
                            <a href="profile.jsp?id=<%= u.getIdUtente() %>"
                               style="font-weight:700; color:inherit; text-decoration:none;">
                                <%= u.getNomeVisualizzato() %>
                            </a>
                            <br>
                            <small class="text-muted">@<%= u.getUsername() %></small>
                        </div>

                        <%-- Pulsante segui/smetti (non mostrato per se stessi) --%>
                        <% if (u.getIdUtente() != idUtenteLoggato) { %>
                            <% if (u.isFollowDaMe()) { %>
                                <a href="network.jsp?id=<%= idProfilo %>&tab=<%= tab %>&smetti=<%= u.getIdUtente() %>"
                                   class="btn-secondary btn-sm">✓ Segui</a>
                            <% } else { %>
                                <a href="network.jsp?id=<%= idProfilo %>&tab=<%= tab %>&segui=<%= u.getIdUtente() %>"
                                   class="btn-primary btn-sm">+ Segui</a>
                            <% } %>
                        <% } %>
                    </div>
                <% } %>
            </div>
        <% } %>

    </main>
</body>
</html>
