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
    int chatConId = 0;
    try { chatConId = Integer.parseInt(request.getParameter("chat")); } catch (Exception e) {}

    String azione = request.getParameter("azione");
    if ("invia_messaggio".equals(azione) && chatConId > 0) {
        String testo = request.getParameter("testo");
        if (testo != null && !testo.trim().isEmpty()) {
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                Connection conn = DriverManager.getConnection(dbUrl, "root", "");
                PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO Messaggio (mittente_id, destinatario_id, testo) VALUES (?, ?, ?)");
                ps.setInt(1, idUtenteLoggato);
                ps.setInt(2, chatConId);
                ps.setString(3, testo.trim());
                ps.executeUpdate();
                ps.close();
                conn.close();
            } catch (Exception e) {}
        }
        response.sendRedirect("messaggi.jsp?chat=" + chatConId);
        return;
    }

    if ("nuova_chat".equals(azione)) {
        int idDestinatario = 0;
        try { idDestinatario = Integer.parseInt(request.getParameter("destinatario")); } catch (Exception e) {}
        String testo = request.getParameter("testo");
        if (idDestinatario > 0 && testo != null && !testo.trim().isEmpty()) {
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                Connection conn = DriverManager.getConnection(dbUrl, "root", "");
                PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO Messaggio (mittente_id, destinatario_id, testo) VALUES (?, ?, ?)");
                ps.setInt(1, idUtenteLoggato);
                ps.setInt(2, idDestinatario);
                ps.setString(3, testo.trim());
                ps.executeUpdate();
                ps.close();
                conn.close();
            } catch (Exception e) {}
        }
        response.sendRedirect("messaggi.jsp?chat=" + idDestinatario);
        return;
    }
%>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Messaggi - BakingBread</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/global.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/messages.css">
    <link rel="icon" href="${pageContext.request.contextPath}/media/favicon.svg">
</head>
<body>
    <jsp:include page="navbar.jsp" />

    <main class="container messages-page mt-4 animate-entrance">
        <div class="messages-container animate-entrance">
            <div class="messages-sidebar">
                <div class="messages-sidebar-header">
                    <h3 style="margin:0;">Messaggi</h3>
                    <button class="btn-primary btn-sm" onclick="toggleNuovaChat()">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
                        </svg>
                    </button>
                </div>

                <div id="nuovaChatForm" style="display:none;padding:15px;border-bottom:1px solid var(--border-color);">
                    <form method="POST" action="messaggi.jsp">
                        <input type="hidden" name="azione" value="nuova_chat">
                        <div class="form-group" style="margin-bottom:10px;">
                            <label style="font-size:13px;">Scegli un amico</label>
                            <select name="destinatario" required style="width:100%;padding:8px;border:2px solid var(--border-color);border-radius:var(--border-radius-sm);font-size:14px;">
                                <option value="">-- Seleziona --</option>
                                <%
                                    try {
                                        Class.forName("com.mysql.cj.jdbc.Driver");
                                        Connection conn = DriverManager.getConnection(dbUrl, "root", "");
                                        PreparedStatement ps = conn.prepareStatement(
                                            "SELECT u.id_utente, u.username, u.nome_visualizzato " +
                                            "FROM Utente u " +
                                            "WHERE u.id_utente IN " +
                                            "  (SELECT s1.followed_id FROM Seguito s1 " +
                                            "   WHERE s1.follower_id = ? AND s1.followed_id IN " +
                                            "   (SELECT s2.follower_id FROM Seguito s2 WHERE s2.followed_id = ?)) " +
                                            "ORDER BY u.nome_visualizzato");
                                        ps.setInt(1, idUtenteLoggato);
                                        ps.setInt(2, idUtenteLoggato);
                                        ResultSet rs = ps.executeQuery();
                                        while (rs.next()) {
                                            int idOpt = rs.getInt("id_utente");
                                %>
                                            <option value="<%= idOpt %>"><%= rs.getString("nome_visualizzato") %> (@<%= rs.getString("username") %>)</option>
                                <%
                                        }
                                        rs.close();
                                        ps.close();
                                        conn.close();
                                    } catch (Exception e) {}
                                %>
                            </select>
                        </div>
                        <div class="form-group" style="margin-bottom:10px;">
                            <textarea name="testo" rows="2" placeholder="Scrivi un messaggio..." required
                                      style="width:100%;padding:8px;border:2px solid var(--border-color);border-radius:var(--border-radius-sm);font-size:14px;resize:vertical;"></textarea>
                        </div>
                        <button type="submit" class="btn-primary btn-sm" style="width:100%;">Avvia Chat</button>
                    </form>
                </div>

                <div class="conversations-list">
                    <%
                        try {
                            Class.forName("com.mysql.cj.jdbc.Driver");
                            Connection conn = DriverManager.getConnection(dbUrl, "root", "");
                            PreparedStatement ps = conn.prepareStatement(
                                "SELECT u.id_utente, u.username, u.nome_visualizzato, u.avatar_url, " +
                                "  (SELECT testo FROM Messaggio m2 WHERE (m2.mittente_id = ? AND m2.destinatario_id = u.id_utente) " +
                                "   OR (m2.mittente_id = u.id_utente AND m2.destinatario_id = ?) " +
                                "   ORDER BY m2.creato_il DESC LIMIT 1) AS ultimo_msg, " +
                                "  (SELECT creato_il FROM Messaggio m2 WHERE (m2.mittente_id = ? AND m2.destinatario_id = u.id_utente) " +
                                "   OR (m2.mittente_id = u.id_utente AND m2.destinatario_id = ?) " +
                                "   ORDER BY m2.creato_il DESC LIMIT 1) AS ultimo_data, " +
                                "  (SELECT COUNT(*) FROM Messaggio m3 WHERE m3.mittente_id = u.id_utente " +
                                "   AND m3.destinatario_id = ? AND m3.letto = FALSE) AS non_letti " +
                                "FROM Utente u " +
                                "WHERE u.id_utente IN (" +
                                "  SELECT DISTINCT CASE WHEN m.mittente_id = ? THEN m.destinatario_id ELSE m.mittente_id END " +
                                "  FROM Messaggio m WHERE m.mittente_id = ? OR m.destinatario_id = ?) " +
                                "ORDER BY ultimo_data DESC");
                            for (int i = 1; i <= 7; i++) ps.setInt(i, idUtenteLoggato);
                            ResultSet rs = ps.executeQuery();
                            boolean hasConv = false;
                            while (rs.next()) {
                                hasConv = true;
                                int idU = rs.getInt("id_utente");
                                String nomeU = rs.getString("nome_visualizzato");
                                String userU = rs.getString("username");
                                String avatarU = UrlUtils.resolve(request.getContextPath(), rs.getString("avatar_url"));
                                String ultimoMsg = rs.getString("ultimo_msg");
                                Timestamp ultimoData = rs.getTimestamp("ultimo_data");
                                int nonLetti = rs.getInt("non_letti");
                                boolean isActive = (idU == chatConId);
                    %>
                        <a href="messaggi.jsp?chat=<%= idU %>" class="conversation-item <%= isActive ? "active" : "" %>">
                            <div class="post-avatar avatar-sm" style="width:44px;height:44px;font-size:16px;flex-shrink:0;">
                                <% if (avatarU != null && !avatarU.isEmpty()) { %>
                                    <img src="<%= avatarU %>" alt="<%= nomeU %>" class="avatar-cover avatar-cover-md">
                                <% } else { %>
                                    <%= nomeU.substring(0,1).toUpperCase() %>
                                <% } %>
                            </div>
                            <div class="conversation-info" style="flex:1;min-width:0;">
                                <div class="d-flex justify-content-between align-items-center">
                                    <strong style="font-size:14px;"><%= nomeU %></strong>
                                    <% if (ultimoData != null) { %>
                                        <small class="text-muted" style="font-size:11px;"><%= ultimoData.toString().substring(5, 16) %></small>
                                    <% } %>
                                </div>
                                <div class="d-flex justify-content-between align-items-center">
                                    <small class="text-muted" style="font-size:12px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">
                                        @<%= userU %> - <%= ultimoMsg != null ? (ultimoMsg.length() > 30 ? ultimoMsg.substring(0, 30) + "..." : ultimoMsg) : "" %>
                                    </small>
                                    <% if (nonLetti > 0) { %>
                                        <span class="badge badge-primary" style="font-size:11px;"><%= nonLetti %></span>
                                    <% } %>
                                </div>
                            </div>
                        </a>
                    <%
                            }
                            rs.close();
                            ps.close();
                            conn.close();
                            if (!hasConv) {
                    %>
                        <div class="empty-state" style="padding:30px 15px;">
                            <p style="font-size:14px;">Nessuna conversazione.<br>Avvia una chat con un amico!</p>
                        </div>
                    <%
                            }
                        } catch (Exception e) {}
                    %>
                </div>
            </div>

            <div class="messages-content">
                <% if (chatConId > 0) {
                    String nomeChat = "", userChat = "", avatarChat = "";
                    try {
                        Class.forName("com.mysql.cj.jdbc.Driver");
                        Connection conn = DriverManager.getConnection(dbUrl, "root", "");
                        PreparedStatement psU = conn.prepareStatement(
                            "SELECT nome_visualizzato, username, avatar_url FROM Utente WHERE id_utente = ?");
                        psU.setInt(1, chatConId);
                        ResultSet rsU = psU.executeQuery();
                        if (rsU.next()) {
                            nomeChat = rsU.getString("nome_visualizzato");
                            userChat = rsU.getString("username");
                            avatarChat = UrlUtils.resolve(request.getContextPath(), rsU.getString("avatar_url"));
                        }
                        rsU.close();
                        psU.close();

                        PreparedStatement psRead = conn.prepareStatement(
                            "UPDATE Messaggio SET letto = TRUE WHERE mittente_id = ? AND destinatario_id = ? AND letto = FALSE");
                        psRead.setInt(1, chatConId);
                        psRead.setInt(2, idUtenteLoggato);
                        psRead.executeUpdate();
                        psRead.close();
                %>
                    <div class="messages-header">
                        <div class="d-flex align-items-center gap-2">
                            <div class="post-avatar avatar-sm" style="width:40px;height:40px;font-size:16px;">
                                <% if (avatarChat != null && !avatarChat.isEmpty()) { %>
                                    <img src="<%= avatarChat %>" alt="<%= nomeChat %>" class="avatar-cover avatar-cover-sm">
                                <% } else { %>
                                    <%= nomeChat.substring(0,1).toUpperCase() %>
                                <% } %>
                            </div>
                            <div>
                                <strong><%= nomeChat %></strong>
                                <small class="text-muted" style="display:block;font-size:12px;">@<%= userChat %></small>
                            </div>
                        </div>
                    </div>

                    <div class="messages-body" id="messagesBody">
                        <%
                            PreparedStatement psMsg = conn.prepareStatement(
                                "SELECT m.id_messaggio, m.testo, m.creato_il, m.mittente_id " +
                                "FROM Messaggio m " +
                                "WHERE (m.mittente_id = ? AND m.destinatario_id = ?) " +
                                "   OR (m.mittente_id = ? AND m.destinatario_id = ?) " +
                                "ORDER BY m.creato_il ASC LIMIT 100");
                            psMsg.setInt(1, idUtenteLoggato);
                            psMsg.setInt(2, chatConId);
                            psMsg.setInt(3, chatConId);
                            psMsg.setInt(4, idUtenteLoggato);
                            ResultSet rsMsg = psMsg.executeQuery();
                            while (rsMsg.next()) {
                                int idM = rsMsg.getInt("id_messaggio");
                                String testoM = rsMsg.getString("testo");
                                Timestamp dataM = rsMsg.getTimestamp("creato_il");
                                boolean isMio = rsMsg.getInt("mittente_id") == idUtenteLoggato;
                        %>
                            <div class="message-bubble <%= isMio ? "message-mine" : "message-theirs" %>">
                                <div class="message-text"><%= testoM %></div>
                                <small class="message-time"><%= dataM.toString().substring(11, 16) %></small>
                            </div>
                        <%
                            }
                            rsMsg.close();
                            psMsg.close();
                            conn.close();
                        %>
                    </div>

                    <div class="messages-footer">
                        <form method="POST" action="messaggi.jsp?chat=<%= chatConId %>" style="display:flex;gap:10px;width:100%;">
                            <input type="hidden" name="azione" value="invia_messaggio">
                            <input type="text" name="testo" placeholder="Scrivi un messaggio..." required
                                   style="flex:1;padding:12px 16px;border:2px solid var(--border-color);border-radius:var(--border-radius-sm);font-size:15px;">
                            <button type="submit" class="btn-primary" style="width:auto;padding:12px 20px;">
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/>
                                </svg>
                            </button>
                        </form>
                    </div>
                <%
                    } catch (Exception e) {}
                } else {
                %>
                    <div class="messages-empty">
                        <svg width="80" height="80" viewBox="0 0 24 24" fill="none" stroke="var(--text-muted)" stroke-width="1.5">
                            <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
                        </svg>
                        <h3 style="margin-top:20px;color:var(--text-muted);">Seleziona una chat</h3>
                        <p class="text-muted">Scegli una conversazione dalla lista o avvia una nuova chat.</p>
                    </div>
                <% } %>
            </div>
        </div>
    </main>

    <script>
    function toggleNuovaChat() {
        var form = document.getElementById('nuovaChatForm');
        form.style.display = form.style.display === 'none' ? 'block' : 'none';
    }

    var messagesBody = document.getElementById('messagesBody');
    if (messagesBody) {
        messagesBody.scrollTop = messagesBody.scrollHeight;
    }
    </script>
    <script src="${pageContext.request.contextPath}/js/main.js"></script>
</body>
</html>
