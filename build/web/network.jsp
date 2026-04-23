<%@ page import="java.sql.*" %>
<%@ page contentType="text/html;charset=UTF-8" %>
<% 
    if (session.getAttribute("id_utente") == null) { 
        response.sendRedirect("login.jsp"); 
        return; 
    } 
    int currentUserId = (Integer) session.getAttribute("id_utente");
    String type = request.getParameter("type");
    
    if(type == null || (!type.equals("followers") && !type.equals("following"))) {
        type = "followers";
    }
%>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= type.equals("followers") ? "I miei Follower" : "Utenti che seguo" %> - BakingBread</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/global.css">
    <style>
        .network-container { max-width: 600px; margin: 40px auto; padding: 0 20px; }
        .network-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; border-bottom: 2px solid var(--border-color, #eee); padding-bottom: 10px; }
        .user-row { display: flex; align-items: center; padding: 15px; background: var(--card-bg, #fff); border-radius: 8px; margin-bottom: 10px; box-shadow: 0 2px 4px rgba(0,0,0,0.05); border: 1px solid var(--border-color, #eee); }
        .user-avatar { width: 50px; height: 50px; border-radius: 50%; background: #ccc; margin-right: 15px; object-fit: cover; }
        .user-info h4 { margin: 0 0 5px 0; font-size: 16px; color: var(--text-main, #333); }
        .user-info p { margin: 0; color: var(--text-muted, #777); font-size: 14px; }
        .back-btn { text-decoration: none; color: var(--primary-color, #333); font-weight: bold; }
        .back-btn:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <jsp:include page="navbar.jsp" />

    <main class="network-container">
        <div class="network-header">
            <h2><%= type.equals("followers") ? "I tuoi Follower" : "Utenti che segui" %></h2>
            <a href="profile.jsp" class="back-btn">← Torna al Profilo</a>
        </div>

        <div class="users-list">
            <%
                try (Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/bakingbread?useSSL=false", "root", "")) {
                    Class.forName("com.mysql.cj.jdbc.Driver");
                    
                    String sql = "";
                    if (type.equals("followers")) {
                        // Utenti che mi seguono (sono follower_id, io sono followed_id)
                        sql = "SELECT u.id_utente, u.username, u.nome_visualizzato, u.avatar_base64 FROM utenti u JOIN seguiti s ON u.id_utente = s.follower_id WHERE s.followed_id = ?";
                    } else {
                        // Utenti che seguo (sono followed_id, io sono follower_id)
                        sql = "SELECT u.id_utente, u.username, u.nome_visualizzato, u.avatar_base64 FROM utenti u JOIN seguiti s ON u.id_utente = s.followed_id WHERE s.follower_id = ?";
                    }
                    
                    PreparedStatement ps = conn.prepareStatement(sql);
                    ps.setInt(1, currentUserId);
                    ResultSet rs = ps.executeQuery();
                    
                    boolean hasUsers = false;
                    while(rs.next()) {
                        hasUsers = true;
                        String avatarBase64 = rs.getString("avatar_base64");
            %>
                        <div class="user-row">
                            <% if(avatarBase64 != null && !avatarBase64.isEmpty()) { %>
                                <img src="<%= avatarBase64 %>" class="user-avatar" alt="Avatar">
                            <% } else { %>
                                <div class="user-avatar" style="background: linear-gradient(135deg, #f3f4f6, #e5e7eb);"></div>
                            <% } %>
                            
                            <div class="user-info">
                                <h4><%= rs.getString("nome_visualizzato") != null ? rs.getString("nome_visualizzato") : rs.getString("username") %></h4>
                                <p>@<%= rs.getString("username") %></p>
                            </div>
                        </div>
            <%
                    }
                    if(!hasUsers) {
                        out.println("<p style='text-align:center; color:#777;'>Nessun utente trovato.</p>");
                    }
                } catch(Exception e) {
                    out.println("<p style='color:red;'>Errore db: " + e.getMessage() + "</p>");
                }
            %>
        </div>
    </main>
</body>
</html>