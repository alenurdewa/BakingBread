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
%>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Le Mie Collezioni - BakingBread</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/global.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/profile.css">
    <link rel="icon" href="${pageContext.request.contextPath}/media/favicon.svg">
</head>
<body>
    <jsp:include page="navbar.jsp" />
    
    <main class="container mt-4">
        <div class="profile-header animate-entrance">
            <div class="profile-avatar">
                <div class="avatar" style="background:var(--primary-gradient);display:flex;align-items:center;justify-content:center;color:#fff;font-size:48px;">
                    S
                </div>
            </div>
            <div class="profile-info">
                <h2>Le Mie Collezioni</h2>
                <p class="username">@<%= (String) session.getAttribute("username") %></p>
                <p class="bio">Tutte le ricette che hai salvato per dopo.</p>
            </div>
        </div>
        
        <div class="mt-4">
            <h3>Ricette Salvate</h3>
            
            <div class="recipe-grid mt-3">
                <% 
                    try {
                        Class.forName("com.mysql.cj.jdbc.Driver");
                        Connection conn = DriverManager.getConnection(dbUrl, "root", "");
                        
                        String sql = "SELECT r.id_ricetta, r.titolo, r.immagine_url, " +
                                     "r.tempo_preparazione_min, u.nome_visualizzato, u.avatar_url " +
                                     "FROM RicettaSalvata rs " +
                                     "JOIN Ricetta r ON rs.id_ricetta = r.id_ricetta " +
                                     "JOIN Utente u ON r.id_utente = u.id_utente " +
                                     "WHERE rs.id_utente = ? AND r.pubblicata = TRUE " +
                                     "ORDER BY rs.salvata_il DESC";
                        
                        PreparedStatement ps = conn.prepareStatement(sql);
                        ps.setInt(1, idUtenteLoggato);
                        ResultSet rs = ps.executeQuery();
                        
                        boolean hasRicette = false;
                        while (rs.next()) {
                            hasRicette = true;
                            int idRicetta = rs.getInt("id_ricetta");
                            String titolo = rs.getString("titolo");
                            String immagineUrl = rs.getString("immagine_url");
                            int tempo = rs.getInt("tempo_preparazione_min");
                            String nomeAutore = rs.getString("nome_visualizzato");
                            String avatarAutore = rs.getString("avatar_url");
                            
                            String displayImg = immagineUrl != null && !immagineUrl.isEmpty() ? 
                                "url(" + immagineUrl + ")" : 
                                "linear-gradient(135deg, #f3f4f6 0%, #e5e7eb 100%)";
                %>
                    <div class="recipe-card" style="position:relative;">
                        <a href="dettaglio_ricetta.jsp?id=<%= idRicetta %>" style="text-decoration:none;">
                            <div style="height:200px;background:<%= displayImg %>;background-size:cover;background-position:center;border-radius:var(--border-radius-md) var(--border-radius-md) 0 0;"></div>
                            <div style="padding:15px;">
                                <h4 style="margin:0 0 8px 0;font-size:16px;color:var(--text-main);"><%= titolo %></h4>
                                <p style="margin:0 0 10px 0;font-size:13px;color:var(--text-muted);">
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="vertical-align:middle;margin-right:4px;">
                                        <circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>
                                    </svg>
                                    <%= tempo > 0 ? tempo + " min" : "" %>
                                </p>
                                <div style="display:flex;align-items:center;gap:8px;">
                                    <div style="width:24px;height:24px;border-radius:50%;background:var(--primary-gradient);display:flex;align-items:center;justify-content:center;color:#fff;font-size:12px;overflow:hidden;">
                                        <% if (avatarAutore != null && !avatarAutore.isEmpty()) { %>
                                            <img src="<%= avatarAutore %>" alt="<%= nomeAutore %>" style="width:100%;height:100%;object-fit:cover;">
                                        <% } else { %>
                                            <%= nomeAutore.substring(0,1).toUpperCase() %>
                                        <% } %>
                                    </div>
                                    <small style="color:var(--text-muted);font-size:12px;"><%= nomeAutore %></small>
                                </div>
                            </div>
                        </a>
                        <form method="POST" action="dettaglio_ricetta.jsp?id=<%= idRicetta %>" style="position:absolute;top:10px;right:10px;">
                            <input type="hidden" name="azione" value="salva">
                            <input type="hidden" name="tipo" value="rimuovi">
                            <button type="submit" class="btn-icon" title="Rimuovi dai salvati" 
                                    style="background:rgba(255,255,255,0.9);border:none;border-radius:50%;width:36px;height:36px;cursor:pointer;display:flex;align-items:center;justify-content:center;">
                                <svg width="18" height="18" viewBox="0 0 24 24" fill="var(--primary-color)" stroke="var(--primary-color)" stroke-width="2">
                                    <path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z"/>
                                </svg>
                            </button>
                        </form>
                    </div>
                <% 
                        }
                        rs.close();
                        ps.close();
                        conn.close();
                        
                        if (!hasRicette) {
                %>
                    <div style="grid-column:1/-1;text-align:center;padding:60px 20px;color:var(--text-muted);">
                        <svg width="80" height="80" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="margin-bottom:20px;opacity:0.5;">
                            <path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z"/>
                        </svg>
                        <h3>Nessuna ricetta salvata</h3>
                        <p>Esplora la home e salva le ricette che ti interessano!</p>
                        <a href="home.jsp" class="btn-primary mt-3" style="display:inline-block;width:auto;">Vai alla Home</a>
                    </div>
                <% 
                        }
                    } catch (Exception e) {
                %>
                    <div class="alert alert-error">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:8px;">
               
