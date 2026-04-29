<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, com.bakingbread.util.UrlUtils" %>
<%!
    private String esc(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }
%>
<%
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
        if (rs.next()) { nomeVisualizzato = rs.getString("nome_visualizzato"); username = rs.getString("username"); email = rs.getString("email"); bio = rs.getString("bio"); avatarUrl = UrlUtils.resolve(ctx, rs.getString("avatar_url")); }
        rs.close(); ps.close(); conn.close();
    } catch (Exception ex) { response.sendRedirect("home.jsp"); return; }
    String initial = nomeVisualizzato != null && !nomeVisualizzato.isEmpty() ? nomeVisualizzato.substring(0, 1).toUpperCase() : "U";
%>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Impostazioni - BakingBread</title>
    <link rel="stylesheet" href="<%= ctx %>/css/global.css">
    <link rel="stylesheet" href="<%= ctx %>/css/settings.css">
    <link rel="icon" href="<%= ctx %>/media/favicon.svg">
</head>
<body>
    <jsp:include page="navbar.jsp" />
    <main class="container settings-page animate-entrance">
        <section class="card settings-card">
            <div class="section-head compact"><div><p class="eyebrow">Account</p><h1>Impostazioni profilo</h1></div></div>
            <form action="<%= ctx %>/profile/update" method="post" enctype="multipart/form-data" class="settings-form">
                <input type="hidden" name="current_avatar_url" value="<%= avatarUrl == null ? "" : avatarUrl %>">
                <div class="settings-avatar-row">
                    <% if (avatarUrl != null && !avatarUrl.trim().isEmpty()) { %><img src="<%= esc(avatarUrl) %>" alt="Avatar" id="avatarPreview" class="settings-avatar-preview"><% } else { %><div id="avatarPreview" class="settings-avatar-preview settings-avatar-fallback"><%= esc(initial) %></div><% } %>
                    <div class="settings-avatar-copy">
                        <h3><%= esc(nomeVisualizzato) %></h3>
                        <p>@<%= esc(username) %></p>
                        <label class="btn-outline file-button">Cambia foto<input type="file" id="avatar_file" name="avatar_file" accept="image/*" class="hidden-file-input" onchange="previewProfileAvatar(this)"></label>
                        <input type="url" name="avatar_url" placeholder="URL immagine opzionale" class="url-input" value="<%= avatarUrl == null ? "" : esc(avatarUrl) %>">
                    </div>
                </div>
                <div class="form-grid-2">
                    <div class="form-group"><label>Nome visualizzato</label><input type="text" name="nome_visualizzato" value="<%= esc(nomeVisualizzato) %>" required></div>
                    <div class="form-group"><label>Email</label><input type="email" name="email" value="<%= esc(email) %>" required></div>
                </div>
                <div class="form-group"><label>Bio</label><textarea name="bio" rows="5" placeholder="Scrivi qualcosa di te..."><%= esc(bio) %></textarea></div>
                <div class="form-actions"><a href="profile.jsp?id=<%= idUtente %>" class="btn-secondary">Annulla</a><button type="submit" class="btn-primary">Salva modifiche</button></div>
            </form>
        </section>
    </main>
    <script src="<%= ctx %>/js/profile.js"></script>
</body>
</html>
