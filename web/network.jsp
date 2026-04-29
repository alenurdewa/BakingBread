<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, com.bakingbread.util.UrlUtils" %>
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
            String redirectUrl = "network.jsp?tab=" + tab;
            if ("messaggi".equals(tab) && idTarget > 0) {
                redirectUrl += "&conv=" + idTarget;
            }
            response.sendRedirect(redirectUrl);
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
    
    <main class="container network-page mt-4 animate-entrance">
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
                                String avatarU = UrlUtils.resolve(request.getContextPath(), rs.getString("avatar_url"));
                    %>
                        <div class="network-item">
                            <a href="profile.jsp?id=<%= idU %>" class="post-avatar">
                                <% if (avatarU != null && !avatarU.isEmpty()) { %>
                                    <img src="<%= avatarU %>" alt="<%= nomeU %>" class="avatar-cover avatar-cover-md">
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
                                String avatarU = UrlUtils.resolve(request.getContextPath(), rs.getString("avatar_url"));
                    %>
                        <div class="network-item">
                            <a href="profile.jsp?id=<%= idU %>" class="post-avatar">
                                <% if (avatarU != null && !avatarU.isEmpty()) { %>
                                    <img src="<%= avatarU %>" alt="<%= nomeU %>" class="avatar-cover avatar-cover-md">
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
                    <%
                        int convUserId = 0;
                        try { convUserId = Integer.parseInt(request.getParameter("conv")); } catch (Exception ignore) {}
                    %>
                    <div style="display:flex;gap:0;min-height:60vh;border:1px solid var(--border-color);border-radius:var(--radius-lg);overflow:hidden;">
                        <%-- Lista conversazioni --%>
                        <div style="width:300px;border-right:1px solid var(--border-color);overflow-y:auto;">
                            <h3 style="padding:16px 16px 8px;margin:0;">Messaggi</h3>
                            <%
                                try {
                                    Connection connConv = DriverManager.getConnection(dbUrl, "root", "");
                                    PreparedStatement psConv = connConv.prepareStatement(
                                        "SELECT u.id_utente, u.username, u.nome_visualizzato, u.avatar_url, " +
                                        "MAX(m.creato_il) AS ultimo_msg, " +
                                        "SUM(CASE WHEN m.destinatario_id = ? AND m.letto = FALSE THEN 1 ELSE 0 END) AS non_letti " +
                                        "FROM ( " +
                                        "  SELECT mittente_id AS altro_id, creato_il, letto, destinatario_id FROM Messaggio WHERE destinatario_id = ? " +
                                        "  UNION ALL " +
                                        "  SELECT destinatario_id AS altro_id, creato_il, TRUE AS letto, destinatario_id FROM Messaggio WHERE mittente_id = ? " +
                                        ") AS m " +
                                        "JOIN Utente u ON u.id_utente = m.altro_id " +
                                        "GROUP BY u.id_utente, u.username, u.nome_visualizzato, u.avatar_url " +
                                        "ORDER BY ultimo_msg DESC LIMIT 50");
                                    psConv.setInt(1, idUtenteLoggato);
                                    psConv.setInt(2, idUtenteLoggato);
                                    psConv.setInt(3, idUtenteLoggato);
                                    ResultSet rsConv = psConv.executeQuery();
                                    boolean hasConv = false;
                                    while (rsConv.next()) {
                                        hasConv = true;
                                        int idU = rsConv.getInt("id_utente");
                                        String nomeU = rsConv.getString("nome_visualizzato");
                                        String userU = rsConv.getString("username");
                                        String avatarU = UrlUtils.resolve(request.getContextPath(), rsConv.getString("avatar_url"));
                                        int nonLetti = rsConv.getInt("non_letti");
                                        boolean isActive = (idU == convUserId);
                                    %>
                                        <a href="network.jsp?tab=messaggi&conv=<%= idU %>" style="display:flex;align-items:center;gap:10px;padding:12px 16px;text-decoration:none;color:var(--text-primary);background:<%= isActive ? "var(--bg-secondary)" : "transparent" %>;border-bottom:1px solid var(--border-color);">
                                            <div class="post-avatar" style="width:40px;height:40px;flex-shrink:0;">
                                                <% if (avatarU != null && !avatarU.isEmpty()) { %>
                                                    <img src="<%= avatarU %>" alt="<%= nomeU %>" style="width:40px;height:40px;border-radius:50%;object-fit:cover;">
                                                <% } else { %>
                                                    <div style="width:40px;height:40px;border-radius:50%;background:var(--primary);color:#fff;display:flex;align-items:center;justify-content:center;font-weight:600;"><%= nomeU.substring(0,1).toUpperCase() %></div>
                                                <% } %>
                                            </div>
                                            <div style="flex:1;min-width:0;">
                                                <div class="d-flex align-items-center gap-2">
                                                    <strong style="white-space:nowrap;overflow:hidden;text-overflow:ellipsis;"><%= nomeU %></strong>
                                                    <% if (nonLetti > 0) { %>
                                                        <span class="badge badge-primary" style="flex-shrink:0;"><%= nonLetti > 9 ? "9+" : nonLetti %></span>
                                                    <% } %>
                                                </div>
                                                <small class="text-muted" style="display:block;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">@<%= userU %></small>
                                            </div>
                                        </a>
                                    <% }
                                        rsConv.close();
                                        psConv.close();
                                        connConv.close();
                                        if (!hasConv) {
                                    %>
                                        <div class="empty-state" style="padding:24px;">
                                            <p>Nessun messaggio.</p>
                                            <a href="home.jsp" class="btn-primary mt-2" style="display:inline-block;width:auto;">Esplora</a>
                                        </div>
                                    <% }
                                } catch (Exception e) {}
                            %>
                        </div>
                        <%-- Cronologia conversazione --%>
                        <div style="flex:1;display:flex;flex-direction:column;">
                            <% if (convUserId > 0) { %>
                                <%
                                    String convNome = "", convUsername = "", convAvatar = "";
                                    try {
                                        Connection connInfo = DriverManager.getConnection(dbUrl, "root", "");
                                        PreparedStatement psInfo = connInfo.prepareStatement(
                                            "SELECT nome_visualizzato, username, avatar_url FROM Utente WHERE id_utente = ?");
                                        psInfo.setInt(1, convUserId);
                                        ResultSet rsInfo = psInfo.executeQuery();
                                        if (rsInfo.next()) {
                                            convNome = rsInfo.getString("nome_visualizzato");
                                            convUsername = rsInfo.getString("username");
                                            convAvatar = UrlUtils.resolve(request.getContextPath(), rsInfo.getString("avatar_url"));
                                        }
                                        rsInfo.close(); psInfo.close();

                                        PreparedStatement psRead = connInfo.prepareStatement(
                                            "UPDATE Messaggio SET letto = TRUE WHERE mittente_id = ? AND destinatario_id = ? AND letto = FALSE");
                                        psRead.setInt(1, convUserId);
                                        psRead.setInt(2, idUtenteLoggato);
                                        psRead.executeUpdate();
                                        psRead.close();

                                        PreparedStatement psMsg = connInfo.prepareStatement(
                                            "SELECT m.id_messaggio, m.testo, m.creato_il, m.letto, m.mittente_id " +
                                            "FROM Messaggio m " +
                                            "WHERE (m.mittente_id = ? AND m.destinatario_id = ?) OR (m.mittente_id = ? AND m.destinatario_id = ?) " +
                                            "ORDER BY m.creato_il ASC LIMIT 100");
                                        psMsg.setInt(1, idUtenteLoggato);
                                        psMsg.setInt(2, convUserId);
                                        psMsg.setInt(3, convUserId);
                                        psMsg.setInt(4, idUtenteLoggato);
                                        ResultSet rsMsg = psMsg.executeQuery();
                                %>
                                    <div style="padding:12px 16px;border-bottom:1px solid var(--border-color);display:flex;align-items:center;gap:10px;">
                                        <a href="profile.jsp?id=<%= convUserId %>" class="post-avatar" style="width:36px;height:36px;">
                                            <% if (convAvatar != null && !convAvatar.isEmpty()) { %>
                                                <img src="<%= convAvatar %>" alt="<%= convNome %>" style="width:36px;height:36px;border-radius:50%;object-fit:cover;">
                                            <% } else { %>
                                                <div style="width:36px;height:36px;border-radius:50%;background:var(--primary);color:#fff;display:flex;align-items:center;justify-content:center;font-weight:600;font-size:14px;"><%= convNome.substring(0,1).toUpperCase() %></div>
                                            <% } %>
                                        </a>
                                        <div>
                                            <a href="profile.jsp?id=<%= convUserId %>" class="text-primary" style="font-weight:600;text-decoration:none;"><%= convNome %></a>
                                            <small class="text-muted" style="display:block;">@<%= convUsername %></small>
                                        </div>
                                    </div>
                                    <div style="flex:1;overflow-y:auto;padding:16px;display:flex;flex-direction:column;gap:8px;">
                                        <% boolean hasMsg = false;
                                           while (rsMsg.next()) {
                                               hasMsg = true;
                                               int idM = rsMsg.getInt("id_messaggio");
                                               String testo = rsMsg.getString("testo");
                                               java.sql.Timestamp creato = rsMsg.getTimestamp("creato_il");
                                               boolean isMio = rsMsg.getInt("mittente_id") == idUtenteLoggato;
                                        %>
                                            <div style="display:flex;justify-content:<%= isMio ? "flex-end" : "flex-start" %>;">
                                                <div style="max-width:70%;padding:10px 14px;border-radius:18px;<%= isMio ? "background:var(--primary);color:#fff;border-bottom-right-radius:4px;" : "background:var(--bg-secondary);border-bottom-left-radius:4px;" %>;">
                                                    <p style="margin:0;word-break:break-word;"><%= testo %></p>
                                                    <small style="display:block;text-align:right;opacity:0.7;font-size:11px;margin-top:4px;"><%= creato.toString().substring(11, 16) %></small>
                                                </div>
                                            </div>
                                        <% }
                                           if (!hasMsg) { %>
                                            <div class="empty-state"><p>Non ci sono messaggi. Invia il primo!</p></div>
                                        <% }
                                           rsMsg.close(); psMsg.close(); connInfo.close();
                                        %>
                                    </div>
                                    <div style="padding:12px 16px;border-top:1px solid var(--border-color);">
                                        <form method="POST" action="network.jsp?tab=messaggi&conv=<%= convUserId %>">
                                            <input type="hidden" name="azione" value="invia_messaggio">
                                            <input type="hidden" name="tipo" value="messaggi">
                                            <input type="hidden" name="id" value="<%= convUserId %>">
                                            <div class="d-flex gap-2">
                                                <input type="text" name="testo" class="form-input" placeholder="Scrivi un messaggio..." style="flex:1;" required>
                                                <button type="submit" class="btn-primary">Invia</button>
                                            </div>
                                        </form>
                                    </div>
                                <% } catch (Exception e) {} %>
                            <% } else { %>
                                <div style="flex:1;display:flex;align-items:center;justify-content:center;">
                                    <div class="empty-state">
                                        <p>Seleziona una conversazione per vedere i messaggi</p>
                                    </div>
                                </div>
                            <% } %>
                        </div>
                    </div>
                <% } %>
            </div>
        </div>
    </main>
    
    <script src="${pageContext.request.contextPath}/js/main.js"></script>
</body>
</html>