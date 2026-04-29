<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, java.net.*" %>
<%
    response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    Integer idUtenteLoggato = (Integer) session.getAttribute("id_utente");
    String azione = request.getParameter("azione");
    String tipo = request.getParameter("tipo");
    int idTarget = 0;
    try { idTarget = Integer.parseInt(request.getParameter("id")); } catch (Exception e) {}
    
    if (idUtenteLoggato != null && azione != null && idTarget > 0) {
        try {
            Connection conn = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/bakingbread?useSSL=false", "root", "");
            
            if ("mi piace".equals(azione)) {
                if ("aggiungi".equals(tipo)) {
                    PreparedStatement ps = conn.prepareStatement(
                        "INSERT IGNORE INTO MiPiace (id_ricetta, id_utente) VALUES (?, ?)");
                    ps.setInt(1, idTarget);
                    ps.setInt(2, idUtenteLoggato);
                    ps.executeUpdate();
                    ps.close();
                } else if ("rimuovi".equals(tipo)) {
                    PreparedStatement ps = conn.prepareStatement(
                        "DELETE FROM MiPiace WHERE id_ricetta = ? AND id_utente = ?");
                    ps.setInt(1, idTarget);
                    ps.setInt(2, idUtenteLoggato);
                    ps.executeUpdate();
                    ps.close();
                }
            } else if ("salva".equals(azione)) {
                if ("aggiungi".equals(tipo)) {
                    PreparedStatement ps = conn.prepareStatement(
                        "INSERT IGNORE INTO RicettaSalvata (id_utente, id_ricetta) VALUES (?, ?)");
                    ps.setInt(1, idUtenteLoggato);
                    ps.setInt(2, idTarget);
                    ps.executeUpdate();
                    ps.close();
                } else if ("rimuovi".equals(tipo)) {
                    PreparedStatement ps = conn.prepareStatement(
                        "DELETE FROM RicettaSalvata WHERE id_utente = ? AND id_ricetta = ?");
                    ps.setInt(1, idUtenteLoggato);
                    ps.setInt(2, idTarget);
                    ps.executeUpdate();
                    ps.close();
                }
            }
            conn.close();
            response.sendRedirect("home.jsp");
            return;
        } catch (Exception e) {
            // ignora errori
        }
    }
    
    String dbUrl = "jdbc:mysql://localhost:3306/bakingbread?useSSL=false";
    String searchQuery = request.getParameter("q");
%>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Home - BakingBread</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/global.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/home.css">
    <link rel="icon" href="${pageContext.request.contextPath}/media/favicon.svg">
</head>
<body>
    <jsp:include page="navbar.jsp" />
    
    <main class="container mt-4">
        <div class="feed-container">
            <% 
                try {
                    Class.forName("com.mysql.cj.jdbc.Driver");
                    Connection conn = DriverManager.getConnection(dbUrl, "root", "");
                    
                    StringBuilder sql = new StringBuilder(
                        "SELECT r.id_ricetta, r.titolo, r.descrizione, r.categoria, " +
                        "r.tempo_preparazione_min, r.immagine_url, r.creato_il, " +
                        "u.id_utente, u.username, u.nome_visualizzato, u.avatar_url, " +
                        "(SELECT COUNT(*) FROM MiPiace WHERE id_ricetta = r.id_ricetta) AS num_like, " +
                        "(SELECT COUNT(*) FROM Commento WHERE id_ricetta = r.id_ricetta) AS num_commenti ");
                    
                    if (idUtenteLoggato != null) {
                        sql.append(", (SELECT COUNT(*) FROM MiPiace WHERE id_ricetta = r.id_ricetta AND id_utente = ").append(idUtenteLoggato).append(") AS gia_like");
                        sql.append(", (SELECT COUNT(*) FROM RicettaSalvata WHERE id_ricetta = r.id_ricetta AND id_utente = ").append(idUtenteLoggato).append(") AS gia_salvata");
                    }
                    
                    sql.append(" FROM Ricetta r ");
                    sql.append("JOIN Utente u ON r.id_utente = u.id_utente ");
                    sql.append("WHERE r.pubblicata = TRUE ");
                    
                    if (searchQuery != null && !searchQuery.trim().isEmpty()) {
                        sql.append("AND (r.titolo LIKE ? OR r.descrizione LIKE ?) ");
                    }
                    
                    sql.append("ORDER BY r.creato_il DESC LIMIT 50");
                    
                    PreparedStatement ps = conn.prepareStatement(sql.toString());
                    
                    if (searchQuery != null && !searchQuery.trim().isEmpty()) {
                        String q = "%" + searchQuery.trim() + "%";
                        ps.setString(1, q);
                        ps.setString(2, q);
                    }
                    
                    ResultSet rs = ps.executeQuery();
                    
                    int count = 0;
                    while (rs.next()) {
                        count++;
                        int idRicetta = rs.getInt("id_ricetta");
                        String titolo = rs.getString("titolo");
                        String descrizione = rs.getString("descrizione");
                        String categoria = rs.getString("categoria");
                        int tempo = rs.getInt("tempo_preparazione_min");
String immagineUrl = rs.getString("immagine_url");
                         Timestamp creatoTs = rs.getTimestamp("creato_il");
                         java.util.Date creato = creatoTs != null ? new java.util.Date(creatoTs.getTime()) : null;
                         int idAutore = rs.getInt("id_utente");
                         String username = rs.getString("username");
                         String nomeVisualizzato = rs.getString("nome_visualizzato");
                         String avatarUrl = rs.getString("avatar_url");
                         int numLike = rs.getInt("num_like");
                         int numCommenti = rs.getInt("num_commenti");
                         
                         boolean giaLike = false;
                         boolean giaSalvata = false;
                         if (idUtenteLoggato != null) {
                             giaLike = rs.getInt("gia_like") > 0;
                             giaSalvata = rs.getInt("gia_salvata") > 0;
                         }
                         
                         String displayImmagine = "linear-gradient(135deg, #f3f4f6 0%, #e5e7eb 100%)";
                         if (immagineUrl != null && !immagineUrl.isEmpty()) {
                             displayImmagine = "url(" + immagineUrl + ")";
                         }
            %>
            <article class="recipe-card animate-entrance">
                <div class="recipe-card-header">
                    <a href="profile.jsp?id=<%= idAutore %>" class="recipe-card-avatar">
                        <% if (avatarUrl != null && !avatarUrl.isEmpty()) { %>
                            <img src="<%= avatarUrl %>" alt="<%= nomeVisualizzato %>">
                        <% } else { %>
                            <%= nomeVisualizzato.substring(0,1).toUpperCase() %>
                        <% } %>
                    </a>
                    <div class="recipe-card-author">
                        <a href="profile.jsp?id=<%= idAutore %>"><%= nomeVisualizzato %></a>
                        <small><%= username %></small>
                    </div>
                    <% if (categoria != null) { %>
                        <span class="badge badge-secondary"><%= categoria %></span>
                    <% } %>
                </div>
                
                <a href="dettaglio_ricetta.jsp?id=<%= idRicetta %>">
                    <div class="recipe-card-image" style="background:<%= displayImmagine %>;background-size:cover;background-position:center;"></div>
                </a>
                
                <div class="recipe-card-body">
                    <a href="dettaglio_ricetta.jsp?id=<%= idRicetta %>" class="recipe-card-title"><%= titolo %></a>
                    <% if (tempo > 0) { %>
                        <div class="recipe-card-meta">
                            <span>
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>
                                </svg>
                                <%= tempo %> min
                            </span>
                        </div>
                    <% } %>
                    <p class="recipe-card-desc"><%= descrizione != null && descrizione.length() > 120 ? descrizione.substring(0, 120) + "..." : (descrizione != null ? descrizione : "") %></p>
                </div>
                
                <div class="recipe-card-footer">
                    <% 
                        String likeAction = giaLike ? "rimuovi" : "aggiungi";
                    %>
                    <% if (idUtenteLoggato != null) { %>
                        <form method="POST" action="home.jsp" style="display:inline;">
                            <input type="hidden" name="azione" value="mi piace">
                            <input type="hidden" name="tipo" value="<%= likeAction %>">
                            <input type="hidden" name="id" value="<%= idRicetta %>">
                            <button type="submit" class="action-btn <%= giaLike ? "active" : "" %>">
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="<%= giaLike ? "currentColor" : "none" %>" stroke="currentColor" stroke-width="2">
                                    <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
                                </svg>
                                <%= numLike %>
                            </button>
                        </form>
                        <form method="POST" action="home.jsp" style="display:inline;">
                            <input type="hidden" name="azione" value="salva">
                            <input type="hidden" name="tipo" value="<%= giaSalvata ? "rimuovi" : "aggiungi" %>">
                            <input type="hidden" name="id" value="<%= idRicetta %>">
                            <button type="submit" class="action-btn <%= giaSalvata ? "active" : "" %>">
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="<%= giaSalvata ? "currentColor" : "none" %>" stroke="currentColor" stroke-width="2">
                                    <path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z"/>
                                </svg>
                            </button>
                        </form>
                    <% } else { %>
                        <a href="login.jsp" class="action-btn">
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
                            </svg>
                            <%= numLike %>
                        </a>
                    <% } %>
                    <a href="dettaglio_ricetta.jsp?id=<%= idRicetta %>" class="action-btn">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
                        </svg>
                        <%= numCommenti %>
                    </a>
                    <% if (idUtenteLoggato != null && idAutore == idUtenteLoggato) { %>
                        <a href="modifica_ricetta.jsp?id=<%= idRicetta %>" class="action-btn">
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                            </svg>
                        </a>
                    <% } %>
                </div>
            </article>
            <% 
                    }
                    rs.close();
                    ps.close();
                    conn.close();
                    
                    if (count == 0) {
            %>
            <div class="empty-state">
                <svg width="80" height="80" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                    <path d="M12 6.253v13m-9-13v13m9-13v13m9-13v13"/>
                    <path d="M5.5 9.5h3m-3 4h3m9-4h3m-3-4h3m-3-4h3"/>
                </svg>
                <h3>Nessuna ricetta trovata</h3>
                <p>Inizia a seguire altri utenti o crea la tua prima ricetta!</p>
                <% if (idUtenteLoggato != null) { %>
                    <a href="crea_ricetta.jsp" class="btn-primary mt-3" style="display:inline-block;width:auto;">Crea Ricetta</a>
                <% } else { %>
                    <a href="register.jsp" class="btn-primary mt-3" style="display:inline-block;width:auto;">Registrati</a>
                <% } %>
            </div>
            <% 
                    }
                } catch (Exception e) {
            %>
            <div class="alert alert-error">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:8px;">
                    <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>
                </svg>
                Errore nel caricamento delle ricette: <%= e.getMessage() %>
            </div>
            <% } %>
        </div>
    </main>
    
    <script src="${pageContext.request.contextPath}/js/main.js"></script>
</body>
</html>