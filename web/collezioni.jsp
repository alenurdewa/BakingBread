<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.bakingbread.util.*" %>
<%@ page import="com.bakingbread.model.*" %>
<%--
    ============================================================
    FILE: collezioni.jsp
    SCOPO: Mostra le ricette salvate dall'utente loggato.
    GET → carica e mostra le ricette nella collezione
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

    // Array delle ricette salvate dall'utente
    RicettaCard[] ricetteSalvate = new RicettaCard[0];

    Connection conn = null;
    try {
        conn = Db.getConnection();

        // ---- Conta quante ricette ha salvato l'utente ----
        PreparedStatement psCount = conn.prepareStatement(
            "SELECT COUNT(*) FROM RicettaSalvata WHERE id_utente = ?"
        );
        psCount.setInt(1, idUtenteLoggato);
        ResultSet rsCount = psCount.executeQuery();
        int numSalvate = 0;
        if (rsCount.next()) { numSalvate = rsCount.getInt(1); }
        rsCount.close(); psCount.close();

        // Limita a 50 elementi
        if (numSalvate > 50) { numSalvate = 50; }

        ricetteSalvate = new RicettaCard[numSalvate];

        // ---- Carica le ricette salvate con tutti i dettagli ----
        PreparedStatement ps = conn.prepareStatement(
            "SELECT r.id_ricetta, r.titolo, r.descrizione, r.immagine_url, " +
            "       r.categoria, r.difficolta, r.tempo_preparazione_min, r.tempo_cottura_min, " +
            "       u.id_utente AS id_autore, u.nome_visualizzato, u.username, u.avatar_url, " +
            "       COUNT(DISTINCT mp.id_like) AS num_like " +
            "FROM RicettaSalvata rs " +
            "JOIN Ricetta r ON rs.id_ricetta = r.id_ricetta " +
            "JOIN Utente u ON r.id_utente = u.id_utente " +
            "LEFT JOIN MiPiace mp ON r.id_ricetta = mp.id_ricetta " +
            "WHERE rs.id_utente = ? AND r.pubblicata = TRUE " +
            "GROUP BY r.id_ricetta, u.id_utente " +
            "ORDER BY rs.salvato_il DESC " +
            "LIMIT 50"
        );
        ps.setInt(1, idUtenteLoggato);
        ResultSet rs = ps.executeQuery();
        int i = 0;
        while (rs.next() && i < ricetteSalvate.length) {
            RicettaCard card = new RicettaCard();
            card.setIdRicetta(rs.getInt("id_ricetta"));
            card.setTitolo(rs.getString("titolo"));
            card.setDescrizione(rs.getString("descrizione"));
            card.setImmagineUrl(UrlUtils.risolvi(ctx, rs.getString("immagine_url")));
            card.setCategoria(rs.getString("categoria"));
            card.setDifficolta(rs.getString("difficolta"));
            card.setTempoPrep(rs.getInt("tempo_preparazione_min"));
            card.setTempoCottura(rs.getInt("tempo_cottura_min"));
            card.setIdAutore(rs.getInt("id_autore"));
            card.setNomeAutore(rs.getString("nome_visualizzato"));
            card.setUsernameAutore(rs.getString("username"));
            card.setAvatarAutore(UrlUtils.risolvi(ctx, rs.getString("avatar_url")));
            card.setNumLike(rs.getInt("num_like"));
            card.setSalvataDaMe(true); // È nella collezione: è sicuramente salvata
            ricetteSalvate[i] = card;
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
    <title>Collezioni - BakingBread</title>
    <link rel="stylesheet" href="<%= ctx %>/css/global.css">
    <link rel="stylesheet" href="<%= ctx %>/css/home.css">
    <link rel="icon" href="<%= ctx %>/media/favicon.svg">
</head>
<body>
    <jsp:include page="navbar.jsp" />

    <main>
        <div class="feed-container">
            <div class="section-head">
                <div>
                    <p class="eyebrow">Libreria</p>
                    <h1>Le mie collezioni</h1>
                </div>
            </div>

            <% if (ricetteSalvate.length == 0) { %>
                <div class="recipe-empty">
                    <p style="font-size:48px; margin:0;">📚</p>
                    <h2>Nessuna ricetta salvata</h2>
                    <p class="text-muted">
                        Salva le ricette che ti piacciono cliccando 📌 nella home.
                    </p>
                    <a href="home.jsp" class="btn-primary mt-3">Esplora ricette</a>
                </div>
            <% } else { %>
                <% for (int i = 0; i < ricetteSalvate.length; i++) { %>
                    <% RicettaCard r = ricetteSalvate[i]; %>
                    <article class="recipe-card animate-entrance">
                        <div class="recipe-card-header">
                            <a href="profile.jsp?id=<%= r.getIdAutore() %>" class="recipe-card-avatar">
                                <% if (r.getAvatarAutore() != null && !r.getAvatarAutore().isEmpty()) { %>
                                    <img src="<%= r.getAvatarAutore() %>" alt="Avatar">
                                <% } else { %>
                                    <%= r.getNomeAutore() != null ? r.getNomeAutore().substring(0,1).toUpperCase() : "U" %>
                                <% } %>
                            </a>
                            <div class="recipe-card-author">
                                <a href="profile.jsp?id=<%= r.getIdAutore() %>">
                                    <%= r.getNomeAutore() %>
                                </a>
                                <small>@<%= r.getUsernameAutore() %></small>
                            </div>
                            <% if (r.getCategoria() != null && !r.getCategoria().isEmpty()) { %>
                                <span class="badge badge-secondary"><%= r.getCategoria() %></span>
                            <% } %>
                        </div>

                        <% if (r.getImmagineUrl() != null && !r.getImmagineUrl().isEmpty()) { %>
                            <a href="dettaglio_ricetta.jsp?id=<%= r.getIdRicetta() %>"
                               class="recipe-card-image">
                                <img src="<%= r.getImmagineUrl() %>" alt="<%= r.getTitolo() %>"
                                     style="width:100%; height:100%; object-fit:cover;">
                            </a>
                        <% } %>

                        <div class="recipe-card-body">
                            <a href="dettaglio_ricetta.jsp?id=<%= r.getIdRicetta() %>"
                               class="recipe-card-title">
                                <%= r.getTitolo() %>
                            </a>
                            <% if (r.getDescrizione() != null && !r.getDescrizione().isEmpty()) { %>
                                <p class="recipe-card-desc"><%= r.getDescrizione() %></p>
                            <% } %>
                            <div class="recipe-card-meta">
                                <% if (r.getTempoPrep() + r.getTempoCottura() > 0) { %>
                                    <span>⏱ <%= r.getTempoPrep() + r.getTempoCottura() %> min</span>
                                <% } %>
                                <% if (r.getDifficolta() != null) { %>
                                    <span>📊 <%= r.getDifficolta() %></span>
                                <% } %>
                            </div>
                        </div>

                        <div class="recipe-card-footer">
                            <span class="action-btn">❤ <%= r.getNumLike() %> Mi piace</span>
                            <%-- Rimuovi dalla collezione --%>
                            <a href="home.jsp?azione=salva&tipo=rimuovi&id=<%= r.getIdRicetta() %>"
                               class="action-btn active">
                                🔖 Rimuovi dai salvati
                            </a>
                        </div>
                    </article>
                <% } %>
            <% } %>
        </div>
    </main>
</body>
</html>
