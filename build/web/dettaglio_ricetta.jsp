<%@ page import="java.sql.*" %>
<%@ page contentType="text/html;charset=UTF-8" %>
<% 
    int idRicetta = Integer.parseInt(request.getParameter("id"));
    Integer currentUserId = (Integer) session.getAttribute("id_utente");
    
    // CONNESSIONE AL DB
    Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/bakingbread?useSSL=false", "root", "");
    
    // GESTIONE AZIONI (Vota, Salva, Segui)
    if ("POST".equalsIgnoreCase(request.getMethod()) && request.getParameter("azione") != null && currentUserId != null) {
        String azione = request.getParameter("azione");
        
        if (azione.equals("vota")) {
            int stelle = Integer.parseInt(request.getParameter("stelle"));
            // Aggiorna o Inserisce il voto
            PreparedStatement psVoto = conn.prepareStatement("INSERT INTO valutazioni (id_ricetta, id_utente, stelle) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE stelle = ?");
            psVoto.setInt(1, idRicetta); psVoto.setInt(2, currentUserId); psVoto.setInt(3, stelle); psVoto.setInt(4, stelle);
            psVoto.executeUpdate();
            
        } else if (azione.equals("salva")) {
            // Controlla se è già salvata e fa il toggle (aggiungi/rimuovi)
            PreparedStatement psCheck = conn.prepareStatement("SELECT * FROM ricette_salvate WHERE id_utente=? AND id_ricetta=?");
            psCheck.setInt(1, currentUserId); psCheck.setInt(2, idRicetta);
            if(psCheck.executeQuery().next()) {
                PreparedStatement psDel = conn.prepareStatement("DELETE FROM ricette_salvate WHERE id_utente=? AND id_ricetta=?");
                psDel.setInt(1, currentUserId); psDel.setInt(2, idRicetta); psDel.executeUpdate();
            } else {
                PreparedStatement psAdd = conn.prepareStatement("INSERT INTO ricette_salvate (id_utente, id_ricetta) VALUES (?, ?)");
                psAdd.setInt(1, currentUserId); psAdd.setInt(2, idRicetta); psAdd.executeUpdate();
            }
            
        } else if (azione.equals("segui")) {
            int idAutore = Integer.parseInt(request.getParameter("id_autore"));
            PreparedStatement psCheck = conn.prepareStatement("SELECT * FROM seguiti WHERE follower_id=? AND followed_id=?");
            psCheck.setInt(1, currentUserId); psCheck.setInt(2, idAutore);
            if(psCheck.executeQuery().next()) {
                conn.prepareStatement("DELETE FROM seguiti WHERE follower_id=" + currentUserId + " AND followed_id=" + idAutore).executeUpdate();
            } else {
                conn.prepareStatement("INSERT INTO seguiti (follower_id, followed_id) VALUES (" + currentUserId + ", " + idAutore + ")").executeUpdate();
            }
        }
        // Ricarica la pagina per mostrare i cambiamenti
        response.sendRedirect("dettaglio_ricetta.jsp?id=" + idRicetta);
        return;
    }
%>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <title>Dettaglio Ricetta</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/global.css">
    <style>
        .hero-img { width: 100%; height: 400px; border-radius: var(--border-radius-lg); margin-bottom: 20px; box-shadow: 0 10px 30px rgba(0,0,0,0.1); }
        .star-container { display: flex; gap: 8px; justify-content: center; margin: 15px 0; }
        .star-btn { font-size: 40px; background: none; border: none; cursor: pointer; transition: all 0.2s; }
        .author-box { display: flex; justify-content: space-between; align-items: center; background: var(--card-bg); padding: 15px; border-radius: var(--border-radius-md); border: 1px solid var(--border-color); }
    </style>
</head>
<body>
    <jsp:include page="navbar.jsp" />
    <main style="max-width: 800px; margin: 40px auto; padding: 0 20px;" class="animated-card">
        <%
            // Estrazione Ricetta
            PreparedStatement ps = conn.prepareStatement("SELECT r.*, u.nome_visualizzato, u.id_utente AS id_autore FROM ricette r JOIN utenti u ON r.id_utente = u.id_utente WHERE r.id_ricetta = ?");
            ps.setInt(1, idRicetta);
            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                int idAutore = rs.getInt("id_autore");
                String bgImage = rs.getString("immagine_base64") != null ? "url(" + rs.getString("immagine_base64") + ")" : "none";
                
                // Statistiche Voti
                PreparedStatement psVoti = conn.prepareStatement("SELECT AVG(stelle) as media, COUNT(*) as tot FROM valutazioni WHERE id_ricetta = ?");
                psVoti.setInt(1, idRicetta); ResultSet rsVoti = psVoti.executeQuery();
                double mediaVoti = 0; int totVoti = 0;
                if(rsVoti.next()) { mediaVoti = rsVoti.getDouble("media"); totVoti = rsVoti.getInt("tot"); }
                
                // Il mio voto
                int mioVoto = 0; boolean isSaved = false; boolean isFollowing = false;
                if (currentUserId != null) {
                    PreparedStatement psMioVoto = conn.prepareStatement("SELECT stelle FROM valutazioni WHERE id_ricetta=? AND id_utente=?");
                    psMioVoto.setInt(1, idRicetta); psMioVoto.setInt(2, currentUserId);
                    ResultSet rsMio = psMioVoto.executeQuery(); if(rsMio.next()) mioVoto = rsMio.getInt("stelle");
                    
                    PreparedStatement psSave = conn.prepareStatement("SELECT * FROM ricette_salvate WHERE id_utente=? AND id_ricetta=?");
                    psSave.setInt(1, currentUserId); psSave.setInt(2, idRicetta); isSaved = psSave.executeQuery().next();
                    
                    PreparedStatement psFollow = conn.prepareStatement("SELECT * FROM seguiti WHERE follower_id=? AND followed_id=?");
                    psFollow.setInt(1, currentUserId); psFollow.setInt(2, idAutore); isFollowing = psFollow.executeQuery().next();
                }
        %>
            
            <div class="hero-img" style="background-image: <%= bgImage %>; background-size: cover; background-position: center;"></div>
            
            <div style="display: flex; justify-content: space-between; align-items: center;">
                <h1 style="font-size: 38px; margin: 0;"><%= rs.getString("titolo") %></h1>
                <% if(currentUserId != null) { %>
                    <form method="POST">
                        <input type="hidden" name="azione" value="salva">
                        <button type="submit" class="btn-primary" style="<%= isSaved ? "background: #10b981;" : "" %>">
                            <%= isSaved ? "★ Salvata" : "☆ Salva Ricetta" %>
                        </button>
                    </form>
                <% } %>
            </div>
            
            <p style="color: #fbbf24; font-size: 20px; font-weight: bold; margin: 10px 0;">
                ★ <%= String.format("%.1f", mediaVoti) %> <span style="color: var(--text-muted); font-size: 14px; font-weight: normal;">(<%= totVoti %> recensioni)</span>
            </p>

            <div class="author-box" style="margin: 20px 0;">
                <div>
                    <span style="color: var(--text-muted);">Pubblicata da </span>
                    <a href="profilo_utente.jsp?id=<%= idAutore %>" style="font-weight: bold; font-size: 18px;"><%= rs.getString("nome_visualizzato") %></a>
                </div>
                <% if(currentUserId != null && currentUserId != idAutore) { %>
                    <form method="POST">
                        <input type="hidden" name="azione" value="segui">
                        <input type="hidden" name="id_autore" value="<%= idAutore %>">
                        <button type="submit" class="action-btn" style="border: 1px solid var(--primary-color);"><%= isFollowing ? "Smetti di seguire" : "+ Segui" %></button>
                    </form>
                <% } %>
            </div>
            
            <div style="font-size: 18px; line-height: 1.8; margin-bottom: 40px;"><%= rs.getString("descrizione") %></div>

            <% if(currentUserId != null) { %>
                <div style="text-align: center; background: var(--card-bg); padding: 30px; border-radius: var(--border-radius-md); box-shadow: var(--shadow-hover);">
                    <h3><%= mioVoto > 0 ? "Hai votato questa ricetta!" : "Vota questa ricetta" %></h3>
                    <div class="star-container" onmouseleave="hoverStars(<%= mioVoto %>)">
                        <% for(int i=1; i<=5; i++) { %>
                            <button class="star-btn" style="color: <%= i <= mioVoto ? "#fbbf24" : "#d1d5db" %>" 
                                    onmouseover="hoverStars(<%= i %>)" onclick="setRating(<%= i %>)">
                                <%= i <= mioVoto ? "★" : "☆" %>
                            </button>
                        <% } %>
                    </div>
                    <form id="ratingForm" method="POST">
                        <input type="hidden" name="azione" value="vota">
                        <input type="hidden" name="stelle" id="rating_input">
                    </form>
                </div>
            <% } %>

        <% } conn.close(); %>
    </main>
    <script src="${pageContext.request.contextPath}/js/main.js"></script>
</body>
</html>