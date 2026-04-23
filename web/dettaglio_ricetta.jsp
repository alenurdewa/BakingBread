<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%
    response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    Integer idUtenteLoggato = (Integer) session.getAttribute("id_utente");
    String dbUrl = "jdbc:mysql://localhost:3306/bakingbread?useSSL=false";
    
    int idRicetta = 0;
    try { idRicetta = Integer.parseInt(request.getParameter("id")); } catch (Exception e) {}
    
    if (idRicetta == 0) {
        response.sendRedirect("home.jsp");
        return;
    }
    
    String azione = request.getParameter("azione");
    String tipo = request.getParameter("tipo");
    int idTarget = 0;
    try { idTarget = Integer.parseInt(request.getParameter("target")); } catch (Exception e) {}
    
    if (idUtenteLoggato != null && azione != null && idTarget > 0) {
        try {
            Connection conn = DriverManager.getConnection(dbUrl, "root", "");
            
            if ("mi piace".equals(azione)) {
                if ("aggiungi".equals(tipo)) {
                    PreparedStatement ps = conn.prepareStatement(
                        "INSERT IGNORE INTO MiPiace (id_ricetta, id_utente) VALUES (?, ?)");
                    ps.setInt(1, idRicetta);
                    ps.setInt(2, idUtenteLoggato);
                    ps.executeUpdate();
                    ps.close();
                } else if ("rimuovi".equals(tipo)) {
                    PreparedStatement ps = conn.prepareStatement(
                        "DELETE FROM MiPiace WHERE id_ricetta = ? AND id_utente = ?");
                    ps.setInt(1, idRicetta);
                    ps.setInt(2, idUtenteLoggato);
                    ps.executeUpdate();
                    ps.close();
                }
            } else if ("valuta".equals(azione)) {
                int stelle = 0;
                try { stelle = Integer.parseInt(request.getParameter("stelle")); } catch (Exception ex) {}
                if (stelle >= 1 && stelle <= 5) {
                    PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO Valutazione (id_ricetta, id_utente, stelle) VALUES (?, ?, ?) " +
                        "ON DUPLICATE KEY UPDATE stelle = ?");
                    ps.setInt(1, idRicetta);
                    ps.setInt(2, idUtenteLoggato);
                    ps.setInt(3, stelle);
                    ps.setInt(4, stelle);
                    ps.executeUpdate();
                    ps.close();
                }
            } else if ("commenta".equals(azione)) {
                String testo = request.getParameter("testo");
                if (testo != null && !testo.trim().isEmpty()) {
                    PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO Commento (id_ricetta, id_utente, testo) VALUES (?, ?, ?)");
                    ps.setInt(1, idRicetta);
                    ps.setInt(2, idUtenteLoggato);
                    ps.setString(3, testo.trim());
                    ps.executeUpdate();
                    ps.close();
                }
            } else if ("elimina_commento".equals(azione)) {
                PreparedStatement ps = conn.prepareStatement(
                    "DELETE FROM Commento WHERE id_commento = ? AND id_utente = ?");
                ps.setInt(1, idTarget);
                ps.setInt(2, idUtenteLoggato);
                ps.executeUpdate();
                ps.close();
            }
            
            conn.close();
            response.sendRedirect("dettaglio_ricetta.jsp?id=" + idRicetta);
            return;
        } catch (Exception e) {
            // ignora errori
        }
    }
    
    String titolo = "", descrizione = "", categoria = "", immagineUrl = "";
    int tempoPrep = 0, tempoCottura = 0, porzioni = 0, idAutore = 0;
    String usernameAutore = "", nomeAutore = "", avatarAutore = "";
    Timestamp creatoIl = null;
    String difficolta = "";
    boolean giaLike = false, giaSalvata = false;
    int numLike = 0, numCommenti = 0;
    double mediaVoti = 0;
    int numValutazioni = 0;
    int mioVoto = 0;
    boolean isAutore = false;
    
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection(dbUrl, "root", "");
        
        PreparedStatement ps = conn.prepareStatement(
            "SELECT r.*, u.id_utente AS uid, u.username, u.nome_visualizzato, u.avatar_url, " +
            "(SELECT COUNT(*) FROM MiPiace WHERE id_ricetta = r.id_ricetta AND id_utente = ?) AS gia_like, " +
            "(SELECT COUNT(*) FROM RicettaSalvata WHERE id_ricetta = r.id_ricetta AND id_utente = ?) AS gia_salvata, " +
            "(SELECT COUNT(*) FROM Valutazione WHERE id_ricetta = r.id_ricetta) AS num_valutazioni, " +
            "(SELECT AVG(stelle) FROM Valutazione WHERE id_ricetta = r.id_ricetta) AS media_voti, " +
            "(SELECT stelle FROM Valutazione WHERE id_ricetta = r.id_ricetta AND id_utente = ?) AS mio_voto " +
            "FROM Ricetta r JOIN Utente u ON r.id_utente = u.id_utente " +
            "WHERE r.id_ricetta = ?");
        
        if (idUtenteLoggato != null) {
            ps.setInt(1, idUtenteLoggato);
            ps.setInt(2, idUtenteLoggato);
            ps.setInt(3, idUtenteLoggato);
        } else {
            ps.setInt(1, 0);
            ps.setInt(2, 0);
            ps.setInt(3, 0);
        }
        ps.setInt(idUtenteLoggato != null ? 4 : 3, idRicetta);
        
        ResultSet rs = ps.executeQuery();
        if (rs.next()) {
            titolo = rs.getString("titolo");
            descrizione = rs.getString("descrizione");
            categoria = rs.getString("categoria");
            tempoPrep = rs.getInt("tempo_preparazione_min");
            tempoCottura = rs.getInt("tempo_cottura_min");
            porzioni = rs.getInt("porzioni");
            difficolta = rs.getString("difficolta");
            immagineUrl = rs.getString(" immagine_url");
            creatoIl = rs.getTimestamp("creato_il");
            idAutore = rs.getInt("uid");
            usernameAutore = rs.getString("username");
            nomeAutore = rs.getString("nome_visualizzato");
            avatarAutore = rs.getString("avatar_url");
            giaLike = rs.getInt("gia_like") > 0;
            giaSalvata = rs.getInt("gia_salvata") > 0;
            numValutazioni = rs.getInt("num_valutazioni");
            mediaVoti = rs.getDouble("media_voti");
            mioVoto = rs.getInt("mio_voto");
            
            if (idUtenteLoggato != null && idAutore == idUtenteLoggato) {
                isAutore = true;
            }
        }
        rs.close();
        ps.close();
        
        rs = conn.createStatement().executeQuery("SELECT COUNT(*) FROM MiPiace WHERE id_ricetta = " + idRicetta);
        if (rs.next()) numLike = rs.getInt(1);
        rs.close();
        
        rs = conn.createStatement().executeQuery("SELECT COUNT(*) FROM Commento WHERE id_ricetta = " + idRicetta);
        if (rs.next()) numCommenti = rs.getInt(1);
        rs.close();
        
        conn.close();
    } catch (Exception e) {
        // errore nel caricamento
    }
    
    if (titolo.isEmpty()) {
        response.sendRedirect("home.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= titolo %> - BakingBread</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/global.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/recipe.css">
    <link rel="icon" href="${pageContext.request.contextPath}/media/favicon.svg">
</head>
<body>
    <jsp:include page="navbar.jsp" />
    
    <main class="container mt-4">
        <article class="post-card animate-entrance">
            <div class="post-header">
                <a href="profile.jsp?id=<%= idAutore %>" class="post-avatar" style="text-decoration:none;">
                    <% if (avatarAutore != null && !avatarAutore.isEmpty()) { %>
                        <img src="<%= avatarAutore %>" alt="<%= nomeAutore %>" class="avatar-sm" style="width:44px;height:44px;border-radius:50%;object-fit:cover;">
                    <% } else { %>
                        <%= nomeAutore.substring(0,1).toUpperCase() %>
                    <% } %>
                </a>
                <div>
                    <a href="profile.jsp?id=<%= idAutore %>" class="post-author-name"><%= nomeAutore %></a>
                    <small class="text-muted" style="display:block;"><%= usernameAutore %></small>
                </div>
                <% if (categoria != null && !categoria.isEmpty()) { %>
                    <span class="badge badge-secondary"><%= categoria %></span>
                <% } %>
            </div>
            
            <% if (idRicetta > 0) { %>
                <div class="recipe-image" style="background:<%= immagineUrl != null && ! immagineUrl.isEmpty() ? "url(" + immagineUrl + ")" : "linear-gradient(135deg, #f3f4f6 0%, #e5e7eb 100%)" %>;background-size:cover;background-position:center;"></div>
            <% } else { %>
                <div class="recipe-image" style="background:linear-gradient(135deg, #f3f4f6 0%, #e5e7eb 100%);"></div>
            <% } %>
            
            <div class="post-body">
                <div class="d-flex align-items-center justify-content-between">
                    <h1><%= titolo %></h1>
                    <% if (idUtenteLoggato != null) { %>
                        <form method="POST" action="dettaglio_ricetta.jsp?id=<%= idRicetta %>" style="display:inline;">
                            <input type="hidden" name="azione" value="salva">
                            <input type="hidden" name="tipo" value="<%= giaSalvata ? "rimuovi" : "aggiungi" %>">
                            <button type="submit" class="btn-icon <%= giaSalvata ? "btn-primary" : "btn-secondary" %>" title="<%= giaSalvata ? "Rimuovi dai salvati" : "Salva ricetta" %>">
                                <svg width="24" height="24" viewBox="0 0 24 24" fill="<%= giaSalvata ? "currentColor" : "none" %>" stroke="currentColor" stroke-width="2">
                                    <path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z"/>
                                </svg>
                            </button>
                        </form>
                    <% } %>
                </div>
                
                <div class="recipe-meta">
                    <% if (tempoPrep > 0) { %>
                        <div class="meta-item">
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>
                            </svg>
                            <span><strong>Prep:</strong> <%= tempoPrep %> min</span>
                        </div>
                    <% } %>
                    <% if (tempoCottura > 0) { %>
                        <div class="meta-item">
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M12 2v4M12 18v4M4.93 4.93l2.83 2.83M16.24 16.24l2.83 2.83M2 12h4M18 12h4M4.93 19.07l2.83-2.83M16.24 7.76l2.83-2.83"/>
                            </svg>
                            <span><strong>Cottura:</strong> <%= tempoCottura %> min</span>
                        </div>
                    <% } %>
                    <% if (porzioni > 0) { %>
                        <div class="meta-item">
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>
                            </svg>
                            <span><strong>Porzioni:</strong> <%= porzioni %></span>
                        </div>
                    <% } %>
                    <% if (difficolta != null && !difficolta.isEmpty()) { %>
                        <div class="meta-item">
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
                            </svg>
                            <span><strong>Difficolta:</strong> <%= difficolta.substring(0,1).toUpperCase() + difficolta.substring(1) %></span>
                        </div>
                    <% } %>
                </div>
                
                <% if (descrizione != null && !descrizione.isEmpty()) { %>
                    <div class="recipe-desc mt-4">
                        <h3>Descrizione</h3>
                        <p><%= descrizione %></p>
                    </div>
                <% } %>
                
                <% try {
                    Connection conn = DriverManager.getConnection(dbUrl, "root", "");
                    PreparedStatement ps = conn.prepareStatement(
                        "SELECT i.nome, ri.quantita, ri.unita_misura, ri.note FROM RicettaIngrediente ri " +
                        "JOIN Ingrediente i ON ri.id_ingrediente = i.id_ingrediente " +
                        "WHERE ri.id_ricetta = ? ORDER BY ri.ordine_visualizzazione");
                    ps.setInt(1, idRicetta);
                    ResultSet rs = ps.executeQuery();
                    boolean hasIngredienti = false;
                    while (rs.next()) {
                        if (!hasIngredienti) {
                %>
                <div class="recipe-ingredienti mt-4">
                    <h3>Ingredienti</h3>
                    <ul class="ingredienti-list">
                <%      hasIngredienti = true; }
                        String nomeIng = rs.getString("nome");
                        String quantita = rs.getString("quantita");
                        String unita = rs.getString("unita_misura");
                        String note = rs.getString("note");
                %>
                        <li><%= quantita != null ? quantita : "" %> <%= unita != null ? unita : "" %> <%= nomeIng %> <%= note != null ? " (" + note + ")" : "" %></li>
                <%     }
                    rs.close();
                    ps.close();
                    conn.close();
                    if (hasIngredienti) { %>
                    </ul>
                </div>
                <%      }
                    } catch (Exception ingEx) {}
                %>
                
                <% try {
                    Connection conn = DriverManager.getConnection(dbUrl, "root", "");
                    PreparedStatement ps = conn.prepareStatement(
                        "SELECT ordine, descrizione, immagine_url FROM Passaggio " +
                        "WHERE id_ricetta = ? ORDER BY ordine");
                    ps.setInt(1, idRicetta);
                    ResultSet rs = ps.executeQuery();
                    boolean hasPassaggi = false;
                    while (rs.next()) {
                        if (!hasPassaggi) {
                %>
                <div class="recipe-passaggi mt-4">
                    <h3>Procedimento</h3>
                    <ol class="passaggi-list">
                <%      hasPassaggi = true; }
                        int ordine = rs.getInt("ordine");
                        String descr = rs.getString("descrizione");
                        String imgUrl = rs.getString(" immagine_url");
                %>
                        <li>
                            <span class="passaggio-numero"><%= ordine %></span>
                            <p><%= descr %></p>
                        </li>
                <%     }
                    rs.close();
                    ps.close();
                    conn.close();
                    if (hasPassaggi) { %>
                    </ol>
                </div>
                <%      }
                    } catch (Exception passEx) {}
                %>
            </div>
            
            <div class="post-footer">
                <% if (idUtenteLoggato != null) { %>
                    <form method="POST" action="dettaglio_ricetta.jsp?id=<%= idRicetta %>" style="display:inline;">
                        <input type="hidden" name="azione" value="mi piace">
                        <input type="hidden" name="tipo" value="<%= giaLike ? "rimuovi" : "aggiungi" %>">
                        <button type="submit" class="action-btn <%= giaLike ? "active" : "" %>">
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="<%= giaLike ? "currentColor" : "none" %>" stroke="currentColor" stroke-width="2">
                                <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
                            </svg>
                            <%= numLike %>
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
                
                <div class="valutazione-stelle">
                    <span class="text-muted">Valutazione: </span>
                    <% if (idUtenteLoggato != null) { %>
                        <form method="POST" action="dettaglio_ricetta.jsp?id=<%= idRicetta %>" style="display:inline;">
                            <input type="hidden" name="azione" value="valuta">
                            <% for (int s = 1; s <= 5; s++) { %>
                                <button type="submit" name="stelle" value="<%= s %>" class="action-btn <%= mioVoto == s ? "active" : "" %>" style="padding:4px;">
                                    <svg width="20" height="20" viewBox="0 0 24 24" fill="<%= s <= mioVoto ? "#fbbf24" : "none" %>" stroke="<%= s <= mioVoto ? "#fbbf24" : "currentColor" %>" stroke-width="2">
                                        <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
                                    </svg>
                                </button>
                            <% } %>
                        </form>
                    <% } else { %>
                        <span class="stars">
                            <% for (int s = 1; s <= 5; s++) { %>
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="<%= s <= mediaVoti ? "#fbbf24" : "none" %>" stroke="<%= s <= mediaVoti ? "#fbbf24" : "#d1d5db" %>" stroke-width="2">
                                    <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
                                </svg>
                            <% } %>
                        </span>
                        <span class="text-muted">(<%= numValutazioni %>)</span>
                    <% } %>
                </div>
            </div>
        </article>
        
        <section class="commenti-section mt-4">
            <h3>Commenti (<%= numCommenti %>)</h3>
            
            <% if (idUtenteLoggato != null) { %>
                <form method="POST" action="dettaglio_ricetta.jsp?id=<%= idRicetta %>" class="comment-form mt-3">
                    <input type="hidden" name="azione" value="commenta">
                    <textarea name="testo" placeholder="Scrivi un commento..." required></textarea>
                    <button type="submit" class="btn-primary mt-2">Invia</button>
                </form>
            <% } else { %>
                <p class="text-muted mt-3"><a href="login.jsp">Accedi</a> per commentare</p>
            <% } %>
            
            <% try {
                Connection conn = DriverManager.getConnection(dbUrl, "root", "");
                PreparedStatement ps = conn.prepareStatement(
                    "SELECT c.id_commento, c.testo, c.creato_il, u.id_utente, u.username, u.nome_visualizzato, u.avatar_url " +
                    "FROM Commento c JOIN Utente u ON c.id_utente = u.id_utente " +
                    "WHERE c.id_ricetta = ? ORDER BY c.creato_il DESC LIMIT 50");
                ps.setInt(1, idRicetta);
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    int idCommento = rs.getInt("id_commento");
                    String testo = rs.getString("testo");
                    Timestamp creato = rs.getTimestamp("creato_il");
                    int idCommentatore = rs.getInt("id_utente");
                    String usernameCommentatore = rs.getString("username");
                    String nomeCommentatore = rs.getString("nome_visualizzato");
                    String avatarCommentatore = rs.getString("avatar_url");
            %>
            <div class="commento-item mt-3">
                <div class="commento-header d-flex align-items-center gap-2">
                    <a href="profile.jsp?id=<%= idCommentatore %>" class="post-avatar avatar-sm">
                        <% if (avatarCommentatore != null && !avatarCommentatore.isEmpty()) { %>
                            <img src="<%= avatarCommentatore %>" alt="<%= nomeCommentatore %>" style="width:36px;height:36px;border-radius:50%;object-fit:cover;">
                        <% } else { %>
                            <%= nomeCommentatore.substring(0,1).toUpperCase() %>
                        <% } %>
                    </a>
                    <div>
                        <a href="profile.jsp?id=<%= idCommentatore %>" class="text-primary" style="font-weight:600;"><%= nomeCommentatore %></a>
                        <small class="text-muted" style="display:block;"><%= usernameCommentatore %></small>
                    </div>
                    <% if (idUtenteLoggato != null && (idCommentatore == idUtenteLoggato || isAutore)) { %>
                        <form method="POST" action="dettaglio_ricetta.jsp?id=<%= idRicetta %>" style="margin-left:auto;">
                            <input type="hidden" name="azione" value="elimina_commento">
                            <input type="hidden" name="target" value="<%= idCommento %>">
                            <button type="submit" class="btn-icon text-muted" title="Elimina">
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>
                                </svg>
                            </button>
                        </form>
                    <% } %>
                </div>
                <p class="mt-2" style="margin-left:52px;"><%= testo %></p>
                <small class="text-muted" style="margin-left:52px;display:block;"><%= creato %></small>
            </div>
            <%     }
                rs.close();
                ps.close();
                conn.close();
            } catch (Exception e) {}
            %>
        </section>
    </main>
    
    <script src="${pageContext.request.contextPath}/js/main.js"></script>
</body>
</html>