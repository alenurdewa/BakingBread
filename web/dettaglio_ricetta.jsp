<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, java.util.*, com.bakingbread.util.UrlUtils" %>
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
    if (idUtenteLoggato == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String ctx = request.getContextPath();
    int idRicetta = 0;
    try { idRicetta = Integer.parseInt(request.getParameter("id")); } catch (Exception ignore) {}
    if (idRicetta <= 0) {
        response.sendRedirect("home.jsp");
        return;
    }

    class Ingredient { String nome, quantita, unita; Ingredient(String n, String q, String u) { nome=n; quantita=q; unita=u; } }
    class Step { int ordine; String descrizione; Step(int o, String d) { ordine=o; descrizione=d; } }
    class Comment { int id, parentId, userId; String nome, username, avatar, testo; Timestamp data; Comment(int id, int parentId, int userId, String nome, String username, String avatar, String testo, Timestamp data) { this.id=id; this.parentId=parentId; this.userId=userId; this.nome=nome; this.username=username; this.avatar=avatar; this.testo=testo; this.data=data; } }

    Map<String, Object> ricetta = null;
    List<Ingredient> ingredienti = new ArrayList<Ingredient>();
    List<Step> passi = new ArrayList<Step>();
    List<Comment> topComments = new ArrayList<Comment>();
    Map<Integer, List<Comment>> replies = new HashMap<Integer, List<Comment>>();
    String autoreAvatar = null;
    String autoreNome = null;
    String autoreUsername = null;
    int totaleCommenti = 0;

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/bakingbread?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true", "root", "");

        PreparedStatement ps = conn.prepareStatement("SELECT r.*, u.nome_visualizzato, u.username, u.avatar_url, u.id_utente AS autore_id FROM Ricetta r JOIN Utente u ON r.id_utente = u.id_utente WHERE r.id_ricetta = ?");
        ps.setInt(1, idRicetta);
        ResultSet rs = ps.executeQuery();
        if (rs.next()) {
            ricetta = new HashMap<String, Object>();
            ricetta.put("titolo", rs.getString("titolo"));
            ricetta.put("descrizione", rs.getString("descrizione"));
            ricetta.put("categoria", rs.getString("categoria"));
            ricetta.put("tempo_preparazione_min", rs.getObject("tempo_preparazione_min"));
            ricetta.put("tempo_cottura_min", rs.getObject("tempo_cottura_min"));
            ricetta.put("porzioni", rs.getObject("porzioni"));
            ricetta.put("difficolta", rs.getString("difficolta"));
            ricetta.put("dieta", rs.getString("dieta"));
            ricetta.put("immagine_url", rs.getString("immagine_url"));
            ricetta.put("autore_id", rs.getInt("autore_id"));
            ricetta.put("autore_nome", rs.getString("nome_visualizzato"));
            ricetta.put("autore_username", rs.getString("username"));
            ricetta.put("autore_avatar", UrlUtils.resolve(ctx, rs.getString("avatar_url")));
            autoreAvatar = UrlUtils.resolve(ctx, rs.getString("avatar_url"));
            autoreNome = rs.getString("nome_visualizzato");
            autoreUsername = rs.getString("username");
        }
        rs.close();
        ps.close();

        ps = conn.prepareStatement("SELECT COALESCE(AVG(stelle), 0) AS media_stelle, COUNT(*) AS num_voti FROM Valutazione WHERE id_ricetta = ?");
        ps.setInt(1, idRicetta);
        rs = ps.executeQuery();
        if (rs.next()) {
            ricetta.put("media_stelle", rs.getDouble("media_stelle"));
            ricetta.put("num_voti", rs.getInt("num_voti"));
        }
        rs.close();
        ps.close();

        if (ricetta == null) { conn.close(); response.sendRedirect("home.jsp"); return; }

        ps = conn.prepareStatement("SELECT i.nome, ri.quantita, ri.unita_misura FROM RicettaIngrediente ri JOIN Ingrediente i ON ri.id_ingrediente = i.id_ingrediente WHERE ri.id_ricetta = ? ORDER BY ri.ordine_visualizzazione");
        ps.setInt(1, idRicetta);
        rs = ps.executeQuery();
        while (rs.next()) ingredienti.add(new Ingredient(rs.getString("nome"), rs.getString("quantita"), rs.getString("unita_misura")));
        rs.close(); ps.close();

        ps = conn.prepareStatement("SELECT ordine, descrizione FROM Passaggio WHERE id_ricetta = ? ORDER BY ordine");
        ps.setInt(1, idRicetta);
        rs = ps.executeQuery();
        while (rs.next()) passi.add(new Step(rs.getInt("ordine"), rs.getString("descrizione")));
        rs.close(); ps.close();

        ps = conn.prepareStatement("SELECT c.id_commento, c.parent_commento, c.id_utente, c.testo, c.creato_il, u.nome_visualizzato, u.username, u.avatar_url FROM Commento c JOIN Utente u ON c.id_utente = u.id_utente WHERE c.id_ricetta = ? ORDER BY c.creato_il ASC");
        ps.setInt(1, idRicetta);
        rs = ps.executeQuery();
        while (rs.next()) {
            Comment c = new Comment(rs.getInt("id_commento"), rs.getInt("parent_commento"), rs.getInt("id_utente"), rs.getString("nome_visualizzato"), rs.getString("username"), UrlUtils.resolve(ctx, rs.getString("avatar_url")), rs.getString("testo"), rs.getTimestamp("creato_il"));
            totaleCommenti++;
            if (c.parentId > 0) {
                List<Comment> list = replies.get(c.parentId);
                if (list == null) { list = new ArrayList<Comment>(); replies.put(c.parentId, list); }
                list.add(c);
            } else {
                topComments.add(c);
            }
        }
        rs.close(); ps.close();
        conn.close();
    } catch (Exception ex) {
        response.sendRedirect("home.jsp");
        return;
    }

    double media = ricetta.get("media_stelle") != null ? ((Number) ricetta.get("media_stelle")).doubleValue() : 0;
    int voti = ricetta.get("num_voti") != null ? ((Number) ricetta.get("num_voti")).intValue() : 0;
    boolean isAutore = idUtenteLoggato != null && idUtenteLoggato.intValue() == ((Number) ricetta.get("autore_id")).intValue();
    String immagineUrl = UrlUtils.resolve(ctx, ricetta.get("immagine_url") != null ? (String) ricetta.get("immagine_url") : "");
%>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= esc((String) ricetta.get("titolo")) %> - BakingBread</title>
    <link rel="stylesheet" href="<%= ctx %>/css/global.css">
    <link rel="stylesheet" href="<%= ctx %>/css/recipe.css">
    <link rel="stylesheet" href="<%= ctx %>/css/messages.css">
    <link rel="icon" href="<%= ctx %>/media/favicon.svg">
</head>
<body>
    <jsp:include page="navbar.jsp" />
    <main class="container recipe-detail-page animate-entrance">
        <section class="recipe-hero card">
            <div class="recipe-hero-media"><img src="<%= esc(immagineUrl == null || immagineUrl.trim().isEmpty() ? ctx + "/media/favicon.svg" : immagineUrl) %>" alt="<%= esc((String) ricetta.get("titolo")) %>" class="recipe-hero-img"></div>
            <div class="recipe-hero-content">
                <p class="eyebrow"><%= esc((String) ricetta.get("categoria")) %></p>
                <h1><%= esc((String) ricetta.get("titolo")) %></h1>
                <p class="recipe-description"><%= esc((String) ricetta.get("descrizione")) %></p>
                <div class="author-line">
                    <a href="profile.jsp?id=<%= ricetta.get("autore_id") %>" class="author-link">
                        <% if (autoreAvatar != null && !autoreAvatar.trim().isEmpty()) { %><img src="<%= esc(autoreAvatar) %>" alt="Autore" class="author-avatar"><% } else { %><span class="author-avatar author-avatar-fallback"><%= esc(autoreNome != null && !autoreNome.isEmpty() ? autoreNome.substring(0,1) : "U") %></span><% } %>
                        <span><strong><%= esc(autoreNome) %></strong><small>@<%= esc(autoreUsername) %></small></span>
                    </a>
                    <% if (isAutore) { %><a href="crea_ricetta.jsp?modifica=<%= idRicetta %>" class="btn-outline">Modifica</a><% } %>
                </div>
                <div class="recipe-meta-grid">
                    <div class="meta-chip">Prep: <strong><%= ricetta.get("tempo_preparazione_min") != null ? ricetta.get("tempo_preparazione_min") : "-" %> min</strong></div>
                    <div class="meta-chip">Cottura: <strong><%= ricetta.get("tempo_cottura_min") != null ? ricetta.get("tempo_cottura_min") : "-" %> min</strong></div>
                    <div class="meta-chip">Porzioni: <strong><%= ricetta.get("porzioni") != null ? ricetta.get("porzioni") : "-" %></strong></div>
                    <div class="meta-chip">Difficoltà: <strong><%= esc((String) ricetta.get("difficolta")) %></strong></div>
                    <div class="meta-chip">Rating: <strong><%= String.format(java.util.Locale.US, "%.1f", media) %></strong> (<%= voti %>)</div>
                </div>
            </div>
        </section>
        <section class="recipe-content-grid">
            <article class="card recipe-section">
                <div class="section-head compact"><div><p class="eyebrow">Ingredienti</p><h2>Lista ingredienti</h2></div></div>
                <div class="ingredient-list">
                    <% for (Ingredient ing : ingredienti) { %><div class="ingredient-item"><span><%= esc(ing.nome) %></span><span><%= esc(ing.quantita) %> <%= esc(ing.unita) %></span></div><% } %>
                    <% if (ingredienti.isEmpty()) { %><p class="empty-state">Nessun ingrediente inserito.</p><% } %>
                </div>
            </article>
            <article class="card recipe-section">
                <div class="section-head compact"><div><p class="eyebrow">Procedimento</p><h2>Passaggi</h2></div></div>
                <div class="step-list">
                    <% for (Step step : passi) { %><div class="step-item"><span class="step-number"><%= step.ordine %></span><p><%= esc(step.descrizione) %></p></div><% } %>
                    <% if (passi.isEmpty()) { %><p class="empty-state">Nessun passaggio inserito.</p><% } %>
                </div>
            </article>
        </section>
        <section class="card comments-section" id="commenti">
            <div class="section-head compact"><div><p class="eyebrow">Commenti</p><h2><%= totaleCommenti %> commenti</h2></div></div>
            <form action="<%= ctx %>/recipe/comment" method="post" class="comment-form">
                <input type="hidden" name="id_ricetta" value="<%= idRicetta %>">
                <textarea name="testo" rows="3" placeholder="Scrivi un commento..." required></textarea>
                <button type="submit" class="btn-primary">Pubblica commento</button>
            </form>
            <div class="comment-list">
                <% if (topComments.isEmpty()) { %><p class="empty-state">Ancora nessun commento. Scrivi il primo.</p><% } %>
                <% for (Comment c : topComments) { %>
                    <div class="comment-card">
                        <div class="comment-top">
                            <% if (c.avatar != null && !c.avatar.trim().isEmpty()) { %><img src="<%= esc(c.avatar) %>" alt="Avatar" class="comment-avatar"><% } else { %><span class="comment-avatar comment-avatar-fallback"><%= esc(c.nome != null && !c.nome.isEmpty() ? c.nome.substring(0,1) : "U") %></span><% } %>
                            <div><strong><%= esc(c.nome) %></strong><small>@<%= esc(c.username) %> · <%= c.data != null ? c.data.toString().substring(0, 16) : "" %></small></div>
                        </div>
                        <p><%= esc(c.testo) %></p>
                        <% List<Comment> child = replies.get(c.id); if (child != null && !child.isEmpty()) { %>
                            <div class="comment-replies">
                                <% for (Comment r : child) { %>
                                    <div class="comment-reply">
                                        <div class="comment-top comment-top-small">
                                            <% if (r.avatar != null && !r.avatar.trim().isEmpty()) { %><img src="<%= esc(r.avatar) %>" alt="Avatar" class="comment-avatar comment-avatar-small"><% } else { %><span class="comment-avatar comment-avatar-small comment-avatar-fallback"><%= esc(r.nome != null && !r.nome.isEmpty() ? r.nome.substring(0,1) : "U") %></span><% } %>
                                            <div><strong><%= esc(r.nome) %></strong><small>@<%= esc(r.username) %> · <%= r.data != null ? r.data.toString().substring(0, 16) : "" %></small></div>
                                        </div>
                                        <p><%= esc(r.testo) %></p>
                                    </div>
                                <% } %>
                            </div>
                        <% } %>
                    </div>
                <% } %>
            </div>
        </section>
    </main>
    <script src="<%= ctx %>/js/main.js"></script>
</body>
</html>
