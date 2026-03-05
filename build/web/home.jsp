<%@ page import="java.sql.*" %>
<%@ page contentType="text/html;charset=UTF-8" %>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Home - BakingBread</title>
    
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/global.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/home.css">
</head>
<body>

    <jsp:include page="navbar.jsp" />

    <main class="feed-container">
        
        <%
            // Connessione al DB e recupero delle ultime ricette pubblicate
            String USER = "root";
            String PASSWORD = "";
            String DSN = "jdbc:mysql://localhost:3306/bakingbread?useSSL=false&serverTimezone=UTC";

            try (Connection conn = DriverManager.getConnection(DSN, USER, PASSWORD)) {
                Class.forName("com.mysql.cj.jdbc.Driver");
                
                // Query: Prendo le ricette unendo i dati dell'autore
                String sql = "SELECT r.titolo, r.descrizione, r.categoria, r.tempo_preparazione_min, " +
                             "u.nome_visualizzato, u.username, r.creato_il " +
                             "FROM ricette r " +
                             "JOIN utenti u ON r.id_utente = u.id_utente " +
                             "WHERE r.pubblicata = 1 " +
                             "ORDER BY r.creato_il DESC LIMIT 20";
                             
                PreparedStatement ps = conn.prepareStatement(sql);
                ResultSet rs = ps.executeQuery();
                
                boolean hasRecipes = false;

                while (rs.next()) {
                    hasRecipes = true;
                    String autore = rs.getString("nome_visualizzato") != null ? rs.getString("nome_visualizzato") : rs.getString("username");
        %>
            <article class="post-card">
                <div class="post-header">
                    <div class="post-avatar"></div> <div>
                        <h3 class="post-author-name"><%= autore %></h3>
                        <p class="post-date">Pubblicato il <%= rs.getDate("creato_il") %></p>
                    </div>
                </div>
                
                <div class="post-body">
                    <h2 class="post-title"><%= rs.getString("titolo") %></h2>
                    <p class="post-desc"><%= rs.getString("descrizione") %></p>
                    
                    <div class="post-tags">
                        <span class="tag">Minuti: <%= rs.getInt("tempo_preparazione_min") %></span>
                        <span class="tag">Categoria: <%= rs.getString("categoria") %></span>
                    </div>
                </div>
                
                <div class="post-footer">
                    <button class="action-btn btn-like">Mi Piace</button>
                    <button class="action-btn">Commenta</button>
                    <button class="action-btn">Salva</button>
                </div>
            </article>
            <%
                }
                
                if (!hasRecipes) {
                    out.println("<div class='post-card' style='padding: 30px; text-align: center;'><p style='color: var(--text-muted);'>Nessuna ricetta presente. Sii il primo a pubblicare!</p></div>");
                }
                
            } catch(Exception e) {
                out.println("<p style='color: red; text-align: center;'>Errore di caricamento: " + e.getMessage() + "</p>");
            }
        %>

    </main>

    <script src="${pageContext.request.contextPath}/js/home.js"></script>
</body>
</html>