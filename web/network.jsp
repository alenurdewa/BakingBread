<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%
    response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    Integer idUtenteLoggato = (Integer) session.getAttribute("id_utente");
    if (idUtenteLoggato == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    
    String dbUrl = "jdbc:mysql://localhost:3306/bakingbread?useSSL=false";
    String tab = request.getParameter("tab");
    if (tab == null) tab = "follower";
    
    String azione = request.getParameter("azione");
    String tipo = request.getParameter("tipo");
    int idTarget = 0;
    try { idTarget = Integer.parseInt(request.getParameter("id")); } catch (Exception e) {}
    
    if (azione != null && idTarget > 0) {
        try {
            Connection conn = DriverManager.getConnection(dbUrl, "root", "");
            
            if ("segui".equals(azione)) {
                PreparedStatement ps = conn.prepareStatement(
                    "INSERT IGNORE INTO Seguito (follower_id, followed_id) VALUES (?, ?)");
                ps.setInt(1, idUtenteLoggato);
                ps.setInt(2, idTarget);
                ps.executeUpdate();
                ps.close();
            } else if ("non_seguire".equals(azione)) {
                PreparedStatement ps = conn.prepareStatement(
                    "DELETE FROM Seguito WHERE follower_id = ? AND followed_id = ?");
                ps.setInt(1, idUtenteLoggato);
                ps.setInt(2, idTarget);
                ps.executeUpdate();
                ps.close();
            } else if ("invia_messaggio".equals(azione)) {
                String testo = request.getParameter("testo");
                if (testo != null && !testo.trim().isEmpty()) {
                    PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO Messaggio (mittente_id, destinatario_id, testo) VALUES (?, ?, ?)");
                    ps.setInt(1, idUtenteLoggato);
                    ps.setInt(2, idTarget);
                    ps.setString(3, testo.trim());
                    ps.executeUpdate();
                    ps.close();
                }
            } else if ("elimina_messaggio".equals(azione)) {
                PreparedStatement ps = conn.prepareStatement(
                    "DELETE FROM Messaggio WHERE id_messaggio = ? AND mittente_id = ?");
                ps.setInt(1, idTarget);
                ps.setInt(2, idUtenteLoggato);
                ps.executeUpdate();
                ps.close();
            }
            
            conn.close();
            response.sendRedirect("network.jsp?tab=" + tab);
            return;
        } catch (Exception e) {}
    }
%>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rete - BakingBread</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/global.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/profile.css">
    <link rel="icon" href="${pageContext.request.contextPath}/media/favicon.svg">
</head>
<body>
    <jsp:include page="navbar.jsp" />
    
    <main class="container mt-4">
        <div class="post-card animate-entrance">
            <div class="network-tabs">
                <a href="network.jsp?tab=follower" class="network-tab <%= "follower".equals(tab) ? "active" : "" %>">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>
                    </svg>
                    Follower
                </a>
                <a href="network.jsp?tab=seguiti" class="network-tab <%= "seguiti".equals(tab) ? "active" : "" %>">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="8.5" cy="7" r="4"/>
                    </svg>
                    Seguiti
                </a>
                <a href="network.jsp?tab=messaggi" class="network-tab <%= "messaggi".equals(tab) ? "active" : "" %>">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
                    </svg>
                    Messaggi
                </a>
            </div>
            
            <div class="network-content">
                <% if ("follower".equals(tab)) { %>
                    <h3>I tuoi Follower</h3>
                    <% 
                        try {
                            Connection conn = DriverManager.getConnection(dbUrl, "root", "");
                            PreparedStatement ps = conn.prepareStatement(
                                "SELECT u.id_utente, u.username, u.nome_visualizzato, u.avatar_url, s.creato_il " +
                                "FROM Seguito s JOIN Utente u ON s.follower_id = u.id_utente " +
                                "WHERE s.followed_id = ? ORDER BY s.creato_il DESC LIMIT 50");
                            ps.setInt(1, idUtenteLoggato);
                            ResultSet rs = ps.executeQuery();
                            boolean has = false;
                            while (rs.next()) {
                                has = true;
                                int idU = rs.getInt("id_utente");
                                String nomeU = rs.getString("nome_visualizzato");
                                String userU = rs.getString("username");
                                String avatarU = rs.getString("avatar_url");
                    %>
                        <div class="network-item">
                            <a href="profile.jsp?id=<%= idU %>" class="post-avatar">
                                <% if (avatarU != null && !avatarU.isEmpty()) { %>
                                    <img src="<%= avatarU %>" alt="<%= nomeU %>" style="width:44px;height:44px;border-radius:50%;object-fit:cover;">
                                <% } else { %>
                                    <%= nomeU.substring(0,1).toUpperCase() %>
                                <% } %>
                            </a>
                            <div style="flex:1;">
                                <a href="profile.jsp?id=<%= idU %>" class="text-primary" style="font-weight:600;"><%= nomeU %></a>
                                <small class="text-muted" style="display:block;">@<%= userU %></small>
                            </div>
                            <form method="POST" action="network.jsp?tab=follower">
                                <input type="hidden" name="azione" value="invia_messaggio">
                                <input type="hidden" name="tipo" value="follower">
                                <input type="hidden" name="id" value="<%= idU %>">
                                <button type="submit" class="btn-secondary btn-sm">
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
                                    </svg>
                                    Messaggio
                                </button>
                            </form>
                        </div>
                    <%     }
                            rs.close();
                            ps.close();
                            conn.close();
                            if (!has) {
                    %>
                        <div class="empty-state">
                            <p>Nessun follower ancora. Condividi le tue ricette!</p>
                        </div>
                    <%     }
                        } catch (Exception e) {}
                    %>
                
                <% } else if ("seguiti".equals(tab)) { %>
                    <h3>Persone che segui</h3>
                    <% 
                        try {
                            Connection conn = DriverManager.getConnection(dbUrl, "root", "");
                            PreparedStatement ps = conn.prepareStatement(
                                "SELECT u.id_utente, u.username, u.nome_visualizzato, u.avatar_url, s.creato_il " +
                                "FROM Seguito s JOIN Utente u ON s.followed_id = u.id_utente " +
                                "WHERE s.follower_id = ? ORDER BY s.creato_il DESC LIMIT 50");
                            ps.setInt(1, idUtenteLoggato);
                            ResultSet rs = ps.executeQuery();
                            boolean has = false;
                            while (rs.next()) {
                                has = true;
                                int idU = rs.getInt("id_utente");
                                String nomeU = rs.getString("nome_visualizzato");
                                String userU = rs.getString("username");
                                String avatarU = rs.getString("avatar_url");
                    %>
                        <div class="network-item">
                            <a href="profile.jsp?id=<%= idU %>" class="post-avatar">
                                <% if (avatarU != null && !avatarU.isEmpty()) { %>
                                    <img src="<%= avatarU %>" alt="<%= nomeU %>" style="width:44px;height:44px;border-radius:50%;object-fit:cover;">
                                <% } else { %>
                                    <%= nomeU.substring(0,1).toUpperCase() %>
                                <% } %>
                            </a>
                            <div style="flex:1;">
                                <a href="profile.jsp?id=<%= idU %>" class="text-primary" style="font-weight:600;"><%= nomeU %></a>
                                <small class="text-muted" style="display:block;">@<%= userU %></small>
                            </div>
                            <form method="POST" action="network.jsp?tab=seguiti">
                                <input type="hidden" name="azione" value="non_seguire">
                                <input type="hidden" name="id" value="<%= idU %>">
                                <button type="submit" class="btn-outline btn-sm">Non seguire</button>
                            </form>
                        </div>
                    <%     }
                            rs.close();
                            ps.close();
                            conn.close();
                            if (!has) {
                    %>
                        <div class="empty-state">
                            <p>Non segui nessuno. Esplora le ricette!</p>
                            <a href="home.jsp" class="btn-primary mt-3" style="display:inline-block;width:auto;">Esplora</a>
                        </div>
                    <%     }
                        } catch (Exception e) {}
                    %>
                
                <% } else if ("messaggi".equals(tab)) { %>
                    <h3>I tuoi Messaggi</h3>
                    <% 
                        try {
                            Connection conn = DriverManager.getConnection(dbUrl, "root", "");
                            PreparedStatement ps = conn.prepareStatement(
                                "SELECT m.id_messaggio, m.testo, m.creato_il, m.letto, m.letto, " +
                                "u.id_utente, u.username, u.nome_visualizzato, u.avatar_url, " +
                                "CASE WHEN m.mittente_id = ? THEN 'inviato' ELSE 'ricevuto' END AS tipo " +
                                "FROM Messaggio m " +
                                "JOIN Utente u ON (CASE WHEN m.mittente_id = ? THEN m.destinatario_id ELSE m.mittente_id END) = u.id_utente " +
                                "WHERE m.mittente_id = ? OR m.destinatario_id = ? " +
                                "ORDER BY m.creato_il DESC LIMIT 50");
                            ps.setInt(1, idUtenteLoggato);
                            ps.setInt(2, idUtenteLoggato);
                            ps.setInt(3, idUtenteLoggato);
                            ps.setInt(4, idUtenteLoggato);
                            ResultSet rs = ps.executeQuery();
                            boolean has = false;
                            while (rs.next()) {
                                has = true;
                                int idM = rs.getInt("id_messaggio");
                                String testo = rs.getString("testo");
                                java.sql.Timestamp creato = rs.getTimestamp("creato_il");
                                boolean letto = rs.getBoolean("letto");
                                String tipoMsg = rs.getString("tipo");
                                int idU = rs.getInt("id_utente");
                                String nomeU = rs.getString("nome_visualizzato");
                                String userU = rs.getString("username");
                                String avatarU = rs.getString("avatar_url");
                    %>
                        <div class="messaggio-item" style="padding:12px;border-bottom:1px solid var(--border-color);">
                            <div class="d-flex align-items-start gap-2">
                                <a href="profile.jsp?id=<%= idU %>" class="post-avatar">
                                    <% if (avatarU != null && !avatarU.isEmpty()) { %>
                                        <img src="<%= avatarU %>" alt="<%= nomeU %>" style="width:40px;height:40px;border-radius:50%;object-fit:cover;">
                                    <% } else { %>
                                        <%= nomeU.substring(0,1).toUpperCase() %>
                                    <% } %>
                                </a>
                                <div style="flex:1;">
                                    <div class="d-flex align-items-center gap-2">
                                        <a href="profile.jsp?id=<%= idU %>" class="text-primary" style="font-weight:600;"><%= nomeU %></a>
                                        <small class="text-muted"><%= creato.toString().substring(0, 16) %></small>
                                        <% if (!letto && "ricevuto".equals(tipoMsg)) { %>
                                            <span class="badge badge-primary">Nuovo</span>
                                        <% } %>
                                    </div>
                                    <p class="mt-1" style="<%= !letto && "ricevuto".equals(tipoMsg) ? "font-weight:600;" : "" %>"><%= testo.length() > 100 ? testo.substring(0, 100) + "..." : testo %></p>
                                </div>
                                <% if (!rs.getBoolean("letto") && "ricevuto".equals(tipoMsg)) {
                                    PreparedStatement upS = conn.prepareStatement(
                                        "UPDATE Messaggio SET letto = TRUE WHERE id_messaggio = ?");
                                    upS.setInt(1, idM);
                                    upS.executeUpdate();
                                    upS.close();
                                } %>
                            </div>
                        </div>
                    <%     }
                            rs.close();
                            ps.close();
                            conn.close();
                            if (!has) {
                    %>
                        <div class="empty-state">
                            <p>Nessun messaggio. Connettiti con altri utenti!</p>
                            <a href="home.jsp" class="btn-primary mt-3" style="display:inline-block;width:auto;">Esplora</a>
                        </div>
                    <%     }
                        } catch (Exception e) {}
                    %>
                <% } %>
            </div>
        </div>
    </main>
    
    <script src="${pageContext.request.contextPath}/js/main.js"></script>
</body>
</html>