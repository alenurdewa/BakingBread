<%@ page import="java.sql.*" %>
<%@ page contentType="text/html;charset=UTF-8" %>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <title>Home - BakingBread</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/global.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/home.css">
</head>
<body>
    <jsp:include page="navbar.jsp" />

    <main class="feed-container">
        <%
            try (Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/bakingbread?useSSL=false", "root", "")) {
                Class.forName("com.mysql.cj.jdbc.Driver");
                String sql = "SELECT r.id_ricetta, r.titolo, r.descrizione, r.tempo_preparazione_min, r.immagine_base64, u.nome_visualizzato " +
                             "FROM ricette r JOIN utenti u ON r.id_utente = u.id_utente ORDER BY r.creato_il DESC LIMIT 20";
                
                PreparedStatement ps = conn.prepareStatement(sql);
                ResultSet rs = ps.executeQuery();

                while (rs.next()) {
                    String imgStr = rs.getString("immagine_base64");
                    String bgImage = (imgStr != null && !imgStr.isEmpty()) ? "url(" + imgStr + ")" : "linear-gradient(135deg, #f3f4f6, #e5e7eb)";
        %>
            <article class="post-card">
                <div class="post-header">
                    <div class="post-avatar"></div>
                    <h3 class="post-author-name"><%= rs.getString("nome_visualizzato") %></h3>
                </div>
                
                <a href="dettaglio_ricetta.jsp?id=<%= rs.getInt("id_ricetta") %>">
                    <div style="width: 100%; height: 300px; background-image: <%= bgImage %>; background-size: cover; background-position: center; transition: opacity 0.3s;" onmouseover="this.style.opacity=0.9" onmouseout="this.style.opacity=1"></div>
                </a>

                <div class="post-body" style="padding-top: 20px;">
                    <a href="dettaglio_ricetta.jsp?id=<%= rs.getInt("id_ricetta") %>">
                        <h2 class="post-title"><%= rs.getString("titolo") %></h2>
                    </a>
                    <p class="post-desc"><%= rs.getString("descrizione").length() > 100 ? rs.getString("descrizione").substring(0, 100) + "..." : rs.getString("descrizione") %></p>
                </div>
                
                <div class="post-footer">
                    <button class="action-btn" onclick="toggleLike(this)">Mi Piace</button>
                    <a href="dettaglio_ricetta.jsp?id=<%= rs.getInt("id_ricetta") %>" class="action-btn">Commenta</a>
                </div>
            </article>
        <%
                }
            } catch(Exception e) { out.println("<p>Errore: " + e.getMessage() + "</p>"); }
        %>
    </main>
    <script src="${pageContext.request.contextPath}/js/main.js"></script>
</body>
</html>