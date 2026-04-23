<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%
    response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    Integer idUtenteLoggato = (Integer) session.getAttribute("id_utente");
    String dbUrl = "jdbc:mysql://localhost:3306/bakingbread?useSSL=false";
    
    int idProfilo = 0;
    try { idProfilo = Integer.parseInt(request.getParameter("id")); } catch (Exception e) {}
    
    if (idProfilo == 0 && idUtenteLoggato != null) {
        idProfilo = idUtenteLoggato;
    }
    
    if (idProfilo == 0) {
        response.sendRedirect("home.jsp");
        return;
    }
    
    String username = "", nomeVisualizzato = "", bio = "", avatarUrl = "";
    Timestamp creatoIl = null;
    int numRicette = 0, numFollower = 0, numSeguiti = 0;
    boolean isSeguito = false;
    boolean isProprioProfilo = idUtenteLoggato != null && idProfilo == idUtenteLoggato;
    
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection(dbUrl, "root", "");
        
        String sql = "SELECT username, nome_visualizzato, bio, avatar_url, creato_il, " +
            "(SELECT COUNT(*) FROM Ricetta WHERE id_utente = ? AND pubblicata = TRUE) AS num_ricette, " +
            "(SELECT COUNT(*) FROM Seguito WHERE followed_id = ?) AS num_follower, " +
            "(SELECT COUNT(*) FROM Seguito WHERE follower_id = ?) AS num_seguiti " +
            "FROM Utente WHERE id_utente = ?";
        
        if (idUtenteLoggato != null) {
            sql = "SELECT username, nome_visualizzato, bio, avatar_url, creato_il, " +
                "(SELECT COUNT(*) FROM Ricetta WHERE id_utente = ? AND pubblicata = TRUE) AS num_ricette, " +
                "(SELECT COUNT(*) FROM Seguito WHERE followed_id = ?) AS num_follower, " +
                "(SELECT COUNT(*) FROM Seguito WHERE follower_id = ?) AS num_seguiti, " +
                "(SELECT COUNT(*) FROM Seguito WHERE follower_id = ? AND followed_id = ?) AS is_seguito " +
                "FROM Utente WHERE id_utente = ?";
        }
        
        PreparedStatement ps = conn.prepareStatement(sql);
        int p = 1;
        ps.setInt(p++, idProfilo);
        ps.setInt(p++, idProfilo);
        ps.setInt(p++, idProfilo);
        if (idUtenteLoggato != null) {
            ps.setInt(p++, idUtenteLoggato);
            ps.setInt(p++, idProfilo);
        }
        ps.setInt(p++, idProfilo);
        
        ResultSet rs = ps.executeQuery();
        if (rs.next()) {
            username = rs.getString("username");
            nomeVisualizzato = rs.getString("nome_visualizzato");
            bio = rs.getString("bio");
            avatarUrl = rs.getString("avatar_url");
            creatoIl = rs.getTimestamp("creato_il");
            numRicette = rs.getInt("num_ricette");
            numFollower = rs.getInt("num_follower");
            numSeguiti = rs.getInt("num_seguiti");
            if (idUtenteLoggato != null) {
                isSeguito = rs.getInt("is_seguito") > 0;
            }
        }
        rs.close();
        ps.close();
        conn.close();
    } catch (Exception e) {}
    
    if (username.isEmpty()) {
        response.sendRedirect("home.jsp");
        return;
    }
    
    String azione = request.getParameter("azione");
    if (idUtenteLoggato != null && azione != null && idProfilo != idUtenteLoggato) {
        try {
            Connection conn = DriverManager.getConnection(dbUrl, "root", "");
            if ("segui".equals(azione) && !isSeguito) {
                PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO Seguito (follower_id, followed_id) VALUES (?, ?)");
                ps.setInt(1, idUtenteLoggato);
                ps.setInt(2, idProfilo);
                ps.executeUpdate();
                ps.close();
            } else if ("non_seguire".equals(azione) && isSeguito) {
                PreparedStatement ps = conn.prepareStatement(
                    "DELETE FROM Seguito WHERE follower_id = ? AND followed_id = ?");
                ps.setInt(1, idUtenteLoggato);
                ps.setInt(2, idProfilo);
                ps.executeUpdate();
                ps.close();
            }
            conn.close();
            response.sendRedirect("profile.jsp?id=" + idProfilo);
            return;
        } catch (Exception e) {}
    }
%>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= nomeVisualizzato %> - BakingBread</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/global.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/profile.css">
    <link rel="icon" href="${pageContext.request.contextPath}/media/favicon.svg">
</head>
<body>
    <jsp:include page="navbar.jsp" />
    
    <main class="container mt-4">
        <div class="post-card animate-entrance">
            <div class="profile-header">
                <div class="profile-avatar">
                    <% if (avatarUrl != null && !avatarUrl.isEmpty()) { %>
                        <img src="<%= avatarUrl %>" alt="<%= nomeVisualizzato %>" class="avatar avatar-lg">
                    <% } else { %>
                        <div class="avatar avatar-lg" style="background:var(--primary-gradient);display:flex;align-items:center;justify-content:center;color:#fff;font-size:72px;">
                            <%= nomeVisualizzato.substring(0,1).toUpperCase() %>
                        </div>
                    <% } %>
                </div>
                
                <div class="profile-info">
                    <div class="d-flex align-items-center gap-3" style="flex-wrap:wrap;">
                        <h2><%= nomeVisualizzato %></h2>
                        <% if (!isProprioProfilo && idUtenteLoggato != null) { %>
                            <% if (isSeguito) { %>
                                <form method="POST" action="profile.jsp?id=<%= idProfilo %>">
                                    <input type="hidden" name="azione" value="non_seguire">
                                    <button type="submit" class="btn-secondary">
                                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:6px;">
                                            <path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="8.5" cy="7" r="4"/><line x1="20" y1="8" x2="20" y2="14"/><line x1="23" y1="11" x2="17" y2="11"/>
                                        </svg>
                                        Non seguire piu'
                                    </button>
                                </form>
                            <% } else { %>
                                <form method="POST" action="profile.jsp?id=<%= idProfilo %>">
                                    <input type="hidden" name="azione" value="segui">
                                    <button type="submit" class="btn-primary">
                                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:6px;">
                                            <path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="8.5" cy="7" r="4"/><line x1="20" y1="8" x2="20" y2="14"/><line x1="23" y1="11" x2="17" y2="11"/>
                                        </svg>
                                        Segui
                                    </button>
                                </form>
                            <% } %>
                        <% } %>
                        <% if (isProprioProfilo) { %>
                            <a href="impostazioni.jsp" class="btn-outline">
                                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:6px;">
                                    <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                                </svg>
                                Modifica Profilo
                            </a>
                        <% } %>
                    </div>
                    
                    <p class="text-muted">@<%= username %></p>
                    
                    <% if (bio != null && !bio.isEmpty()) { %>
                        <p class="mt-2"><%= bio %></p>
                    <% } %>
                    
                    <div class="profile-stats mt-3">
                        <div class="stat-item">
                            <strong><%= numRicette %></strong>
                            <span>Ricette</span>
                        </div>
                        <div class="stat-item">
                            <strong><%= numFollower %></strong>
                            <span>Follower</span>
                        </div>
                        <div class="stat-item">
                            <strong><%= numSeguiti %></strong>
                            <span>Seguiti</span>
                        </div>
                    </div>
                    
                    <% if (creatoIl != null) { %>
                        <small class="text-muted mt-2" style="display:block;">Membro dal <%= creatoIl.toString().substring(0, 10) %></small>
                    <% } %>
                </div>
            </div>
        </div>
        
        <div class="mt-4">
            <h3>Ricette di <%= nomeVisualizzato %></h3>
            
            <div class="recipe-grid mt-3">
                <% 
                    try {
                        Connection conn = DriverManager.getConnection(dbUrl, "root", "");
                        PreparedStatement ps = conn.prepareStatement(
                            "SELECT id_ricetta, titolo, immagine_url, creato_il " +
                            "FROM Ricetta WHERE id_utente = ? AND pubblicata = TRUE " +
                            "ORDER BY creato_il DESC LIMIT 20");
                        ps.setInt(1, idProfilo);
                        ResultSet rs = ps.executeQuery();
                        while (rs.next()) {
                            int idR = rs.getInt("id_ricetta");
                            String titoloR = rs.getString("titolo");
                            String imgUrl = rs.getString(" immagine_url");
                            String displayImg = imgUrl != null && !imgUrl.isEmpty() ? "url(" + imgUrl + ")" : "linear-gradient(135deg, #f3f4f6 0%, #e5e7eb 100%)";
                %>
                    <a href="dettaglio_ricetta.jsp?id=<%= idR %>" class="recipe-card" style="background:<%= displayImg %>;background-size:cover;background-position:center;">
                        <div class="recipe-card-overlay">
                            <h4><%= titoloR %></h4>
                        </div>
                    </a>
                <% 
                        }
                        rs.close();
                        ps.close();
                        conn.close();
                    } catch (Exception e) {}
                %>
            </div>
        </div>
    </main>
    
    <script src="${pageContext.request.contextPath}/js/main.js"></script>
</body>
</html>