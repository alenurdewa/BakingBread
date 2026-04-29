<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, com.bakingbread.util.UrlUtils" %>
<%@ page import="java.util.*" %>
<%!
    private String esc(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }
%>
<%
    response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    Integer idUtenteLoggato = (Integer) session.getAttribute("id_utente");
    String ctx = request.getContextPath();
    int idProfilo = 0;
    try { idProfilo = Integer.parseInt(request.getParameter("id")); } catch (Exception ignore) {}
    if (idProfilo == 0 && idUtenteLoggato != null) idProfilo = idUtenteLoggato;
    if (idProfilo == 0) { response.sendRedirect("home.jsp"); return; }

    String username = "", nomeVisualizzato = "", bio = "", avatarUrl = "";
    Timestamp creatoIl = null;
    int numRicette = 0, numFollower = 0, numSeguiti = 0;
    boolean isSeguito = false;
    boolean isProprioProfilo = idUtenteLoggato != null && idUtenteLoggato.intValue() == idProfilo;

    class RecipeCard { int id; String titolo, immagine; RecipeCard(int id, String titolo, String immagine) { this.id=id; this.titolo=titolo; this.immagine=immagine; } }
    List<RecipeCard> recipes = new ArrayList<RecipeCard>();

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/bakingbread?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true", "root", "");
        PreparedStatement ps = conn.prepareStatement("SELECT username, nome_visualizzato, bio, avatar_url, creato_il FROM Utente WHERE id_utente = ?");
        ps.setInt(1, idProfilo);
        ResultSet rs = ps.executeQuery();
        if (rs.next()) { username = rs.getString("username"); nomeVisualizzato = rs.getString("nome_visualizzato"); bio = rs.getString("bio"); avatarUrl = UrlUtils.resolve(ctx, rs.getString("avatar_url")); creatoIl = rs.getTimestamp("creato_il"); }
        rs.close(); ps.close();
        if (nomeVisualizzato.isEmpty()) { conn.close(); response.sendRedirect("home.jsp"); return; }

        ps = conn.prepareStatement("SELECT COUNT(*) FROM Ricetta WHERE id_utente = ? AND pubblicata = TRUE");
        ps.setInt(1, idProfilo); rs = ps.executeQuery(); if (rs.next()) numRicette = rs.getInt(1); rs.close(); ps.close();
        ps = conn.prepareStatement("SELECT COUNT(*) FROM Seguito WHERE followed_id = ?");
        ps.setInt(1, idProfilo); rs = ps.executeQuery(); if (rs.next()) numFollower = rs.getInt(1); rs.close(); ps.close();
        ps = conn.prepareStatement("SELECT COUNT(*) FROM Seguito WHERE follower_id = ?");
        ps.setInt(1, idProfilo); rs = ps.executeQuery(); if (rs.next()) numSeguiti = rs.getInt(1); rs.close(); ps.close();

        if (!isProprioProfilo && idUtenteLoggato != null) {
            ps = conn.prepareStatement("SELECT 1 FROM Seguito WHERE follower_id = ? AND followed_id = ?");
            ps.setInt(1, idUtenteLoggato); ps.setInt(2, idProfilo); rs = ps.executeQuery(); isSeguito = rs.next(); rs.close(); ps.close();
        }

        ps = conn.prepareStatement("SELECT id_ricetta, titolo, immagine_url FROM Ricetta WHERE id_utente = ? AND pubblicata = TRUE ORDER BY creato_il DESC LIMIT 24");
        ps.setInt(1, idProfilo); rs = ps.executeQuery();
        while (rs.next()) recipes.add(new RecipeCard(rs.getInt("id_ricetta"), rs.getString("titolo"), rs.getString("immagine_url")));
        rs.close(); ps.close(); conn.close();
    } catch (Exception ex) { response.sendRedirect("home.jsp"); return; }

    String initial = nomeVisualizzato != null && !nomeVisualizzato.isEmpty() ? nomeVisualizzato.substring(0, 1).toUpperCase() : "U";
%>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= esc(nomeVisualizzato) %> - BakingBread</title>
    <link rel="stylesheet" href="<%= ctx %>/css/global.css">
    <link rel="stylesheet" href="<%= ctx %>/css/profile.css">
    <link rel="icon" href="<%= ctx %>/media/favicon.svg">
</head>
<body>
    <jsp:include page="navbar.jsp" />
    <main class="container profile-page animate-entrance">
        <section class="profile-header card">
            <div class="profile-avatar-wrap">
                <% if (avatarUrl != null && !avatarUrl.trim().isEmpty()) { %><img src="<%= esc(avatarUrl) %>" alt="<%= esc(nomeVisualizzato) %>" class="profile-avatar-big"><% } else { %><div class="profile-avatar-big profile-avatar-fallback"><%= esc(initial) %></div><% } %>
            </div>
            <div class="profile-info-block">
                <div class="profile-title-row">
                    <div><p class="eyebrow">Profilo</p><h1><%= esc(nomeVisualizzato) %></h1><p class="username">@<%= esc(username) %></p></div>
                    <% if (isProprioProfilo) { %><a href="<%= ctx %>/impostazioni.jsp" class="btn-outline">Modifica profilo</a><% } %>
                    <% if (!isProprioProfilo && idUtenteLoggato != null) { %>
                    <form method="POST" action="<%= ctx %>/profile/follow" style="display:inline;">
                        <input type="hidden" name="id" value="<%= idProfilo %>">
                        <% if (isSeguito) { %>
                        <input type="hidden" name="action" value="unfollow">
                        <button type="submit" class="btn-outline">Non seguire</button>
                        <% } else { %>
                        <button type="submit" class="btn-primary">Segui</button>
                        <% } %>
                    </form>
                    <% } %>
                </div>
                <% if (bio != null && !bio.trim().isEmpty()) { %><p class="bio"><%= esc(bio) %></p><% } %>
                <div class="profile-stats"><div class="stat-item"><strong><%= numRicette %></strong><span>Ricette</span></div><div class="stat-item"><strong><%= numFollower %></strong><span>Follower</span></div><div class="stat-item"><strong><%= numSeguiti %></strong><span>Seguiti</span></div></div>
                <% if (creatoIl != null) { %><p class="profile-meta">Membro dal <%= creatoIl.toString().substring(0, 10) %></p><% } %>
            </div>
        </section>
        <section class="profile-recipes">
            <div class="section-head compact"><div><p class="eyebrow">Ricette</p><h2>Ricette pubblicate</h2></div></div>
            <div class="recipe-grid profile-recipe-grid">
                <% for (RecipeCard r : recipes) { %>
                    <a class="recipe-card" href="<%= ctx %>/dettaglio_ricetta.jsp?id=<%= r.id %>">
                        <% if (r.immagine != null && !r.immagine.trim().isEmpty()) { %><img src="<%= esc(UrlUtils.resolve(ctx, r.immagine)) %>" alt="<%= esc(r.titolo) %>"><% } else { %><div class="recipe-card-placeholder"></div><% } %>
                        <div class="recipe-card-overlay"><h3><%= esc(r.titolo) %></h3></div>
                    </a>
                <% } %>
                <% if (recipes.isEmpty()) { %><p class="empty-state">Nessuna ricetta pubblicata.</p><% } %>
            </div>
        </section>
    </main>
    <script src="<%= ctx %>/js/main.js"></script>
</body>
</html>
