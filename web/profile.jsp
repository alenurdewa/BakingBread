<%@ page import="java.sql.*" %>
<%@ page contentType="text/html;charset=UTF-8" %>
<% 
    if (session.getAttribute("id_utente") == null) { 
        response.sendRedirect("login.jsp"); 
        return; 
    } 
    int currentUserId = (Integer) session.getAttribute("id_utente");
%>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Il mio Profilo - BakingBread</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/global.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/profile.css">
</head>
<body>
    <jsp:include page="navbar.jsp" />

    <main class="profile-container">
        
        <%
            // GESTIONE AGGIORNAMENTO PROFILO
            String updateMsg = "";
            if ("POST".equalsIgnoreCase(request.getMethod())) {
                String newNome = request.getParameter("nome_visualizzato");
                String newUsername = request.getParameter("username");
                String newBio = request.getParameter("bio");
                String newAvatarB64 = request.getParameter("avatar_base64"); // Popolato via JS
                String newPass = request.getParameter("password");

                try (Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/bakingbread?useSSL=false", "root", "")) {
                    Class.forName("com.mysql.cj.jdbc.Driver");
                    
                    String updateSql;
                    PreparedStatement updatePs;
                    
                    // Se la password non è vuota, aggiorniamo anche password_hash
                    if (newPass != null && !newPass.trim().isEmpty()) {
                        // NOTA: In produzione dovresti hashare la password (es. con BCrypt) prima di salvarla
                        updateSql = "UPDATE utenti SET nome_visualizzato = ?, username = ?, bio = ?, avatar_base64 = ?, password_hash = ? WHERE id_utente = ?";
                        updatePs = conn.prepareStatement(updateSql);
                        updatePs.setString(5, newPass);
                        updatePs.setInt(6, currentUserId);
                    } else {
                        updateSql = "UPDATE utenti SET nome_visualizzato = ?, username = ?, bio = ?, avatar_base64 = ? WHERE id_utente = ?";
                        updatePs = conn.prepareStatement(updateSql);
                        updatePs.setInt(5, currentUserId);
                    }
                    
                    updatePs.setString(1, newNome);
                    updatePs.setString(2, newUsername);
                    updatePs.setString(3, newBio);
                    updatePs.setString(4, newAvatarB64);
                    
                    updatePs.executeUpdate();
                    session.setAttribute("nome_utente", newNome); // Aggiorna sessione
                    updateMsg = "<div class='alert alert-success'>Profilo aggiornato con successo!</div>";
                } catch(Exception e) { 
                    updateMsg = "<div class='alert alert-error'>Errore durante l'aggiornamento: " + e.getMessage() + "</div>"; 
                }
            }

            // RECUPERO DATI UTENTE E STATISTICHE
            String username = "", nomeVis = "", bio = "", avatarBase64 = "";
            int numRicette = 0, numFollowers = 0, numFollowing = 0;
            
            try (Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/bakingbread?useSSL=false", "root", "")) {
                Class.forName("com.mysql.cj.jdbc.Driver");
                
                // Dati Utente
                PreparedStatement psUser = conn.prepareStatement("SELECT username, nome_visualizzato, bio, avatar_base64 FROM utenti WHERE id_utente = ?");
                psUser.setInt(1, currentUserId);
                ResultSet rsUser = psUser.executeQuery();
                if(rsUser.next()) {
                    username = rsUser.getString("username");
                    nomeVis = rsUser.getString("nome_visualizzato");
                    bio = rsUser.getString("bio") != null ? rsUser.getString("bio") : "";
                    avatarBase64 = rsUser.getString("avatar_base64") != null ? rsUser.getString("avatar_base64") : "";
                }
                
                // Conteggio ricette
                PreparedStatement psCount = conn.prepareStatement("SELECT COUNT(*) AS total FROM ricette WHERE id_utente = ?");
                psCount.setInt(1, currentUserId);
                ResultSet rsCount = psCount.executeQuery();
                if(rsCount.next()) numRicette = rsCount.getInt("total");

                // Conteggio Followers (chi segue te)
                PreparedStatement psFollowers = conn.prepareStatement("SELECT COUNT(*) AS total FROM seguiti WHERE followed_id = ?");
                psFollowers.setInt(1, currentUserId);
                ResultSet rsFollowers = psFollowers.executeQuery();
                if(rsFollowers.next()) numFollowers = rsFollowers.getInt("total");

                // Conteggio Seguiti (chi segui tu)
                PreparedStatement psFollowing = conn.prepareStatement("SELECT COUNT(*) AS total FROM seguiti WHERE follower_id = ?");
                psFollowing.setInt(1, currentUserId);
                ResultSet rsFollowing = psFollowing.executeQuery();
                if(rsFollowing.next()) numFollowing = rsFollowing.getInt("total");
        %>
        
        <%= updateMsg %>

        <div class="profile-header">
            <% if (!avatarBase64.isEmpty()) { %>
                <img src="<%= avatarBase64 %>" class="profile-avatar-large" alt="Profilo">
            <% } else { %>
                <div class="profile-avatar-large default-avatar"></div>
            <% } %>
            
            <div class="profile-info">
                <h1 class="profile-name"><%= nomeVis != null ? nomeVis : username %></h1>
                <p class="profile-username">@<%= username %></p>
                <p class="profile-bio"><%= bio.isEmpty() ? "Nessuna biografia inserita. Modifica il profilo per aggiungerla." : bio %></p>
                
                <div class="profile-stats">
                    <div class="stat-item">
                        <span class="stat-value"><%= numRicette %></span>
                        <span class="stat-label">Ricette</span>
                    </div>
                    <a href="network.jsp?type=followers" class="stat-item stat-link">
                        <span class="stat-value"><%= numFollowers %></span>
                        <span class="stat-label">Follower</span>
                    </a>
                    <a href="network.jsp?type=following" class="stat-item stat-link">
                        <span class="stat-value"><%= numFollowing %></span>
                        <span class="stat-label">Seguiti</span>
                    </a>
                </div>
                
                <button class="btn-primary" style="width: auto; padding: 8px 16px;" onclick="document.getElementById('editForm').style.display='block'">Modifica Profilo</button>
            </div>
        </div>

        <div id="editForm" style="display:none; background: var(--card-bg); padding: 20px; border-radius: var(--border-radius-md); margin-bottom: 30px; border: 1px solid var(--border-color);">
            <form method="POST" action="profile.jsp">
                <div class="form-group">
                    <label>Immagine Profilo</label>
                    <input type="file" id="fileInput" accept="image/*">
                    <p style="font-size:12px; color:var(--text-muted); margin-top:5px;">Seleziona un'immagine (max 2MB consigliato)</p>
                </div>
                <input type="hidden" name="avatar_base64" id="avatar_base64" value="<%= avatarBase64 %>">

                <div class="form-group">
                    <label>Nome Visualizzato</label>
                    <input type="text" name="nome_visualizzato" value="<%= nomeVis != null ? nomeVis : "" %>">
                </div>
                <div class="form-group">
                    <label>Username</label>
                    <input type="text" name="username" value="<%= username %>" required>
                </div>
                <div class="form-group">
                    <label>Nuova Password (lascia vuoto per non cambiare)</label>
                    <input type="password" name="password" placeholder="Inserisci nuova password">
                </div>
                <div class="form-group">
                    <label>Biografia</label>
                    <textarea name="bio"><%= bio %></textarea>
                </div>
                <button type="submit" class="btn-primary">Salva Modifiche</button>
                <button type="button" class="action-btn mt-3" onclick="document.getElementById('editForm').style.display='none'">Annulla</button>
            </form>
        </div>

        <div class="profile-tabs">
            <button class="tab-btn active" onclick="switchTab('my-recipes', this)">Le mie Ricette</button>
            <button class="tab-btn" onclick="switchTab('saved-recipes', this)">Salvate</button>
        </div>

        <div id="my-recipes" class="recipe-grid tab-content" style="display: grid;">
            <%
                PreparedStatement psRecipes = conn.prepareStatement("SELECT id_ricetta, titolo, tempo_preparazione_min, immagine_base64 FROM ricette WHERE id_utente = ? ORDER BY creato_il DESC");
                psRecipes.setInt(1, currentUserId);
                ResultSet rsRecipes = psRecipes.executeQuery();
                boolean hasUserRecipes = false;
                while(rsRecipes.next()) {
                    hasUserRecipes = true;
                    String imgB64 = rsRecipes.getString("immagine_base64");
            %>
                <div class="recipe-grid-item">
                    <% if(imgB64 != null && !imgB64.isEmpty()) { %>
                        <img src="<%= imgB64 %>" class="grid-img" alt="Ricetta">
                    <% } else { %>
                        <div class="grid-img default-recipe-img"></div>
                    <% } %>
                    <div class="grid-info">
                        <h3 class="grid-title"><%= rsRecipes.getString("titolo") %></h3>
                        <p style="font-size: 13px; color: var(--text-muted); margin:0;">⏱ <%= rsRecipes.getInt("tempo_preparazione_min") %> min</p>
                    </div>
                </div>
            <%  }
                if(!hasUserRecipes) out.println("<p style='color: var(--text-muted); grid-column: 1 / -1;'>Non hai ancora pubblicato ricette.</p>");
            %>
        </div>

        <div id="saved-recipes" class="recipe-grid tab-content" style="display: none;">
            <%
                PreparedStatement psSaved = conn.prepareStatement("SELECT r.id_ricetta, r.titolo, r.tempo_preparazione_min, r.immagine_base64 FROM ricette r JOIN ricette_salvate rs ON r.id_ricetta = rs.id_ricetta WHERE rs.id_utente = ? ORDER BY rs.salvato_il DESC");
                psSaved.setInt(1, currentUserId);
                ResultSet rsSaved = psSaved.executeQuery();
                boolean hasSavedRecipes = false;
                while(rsSaved.next()) {
                    hasSavedRecipes = true;
                    String imgB64 = rsSaved.getString("immagine_base64");
            %>
                <div class="recipe-grid-item">
                    <% if(imgB64 != null && !imgB64.isEmpty()) { %>
                        <img src="<%= imgB64 %>" class="grid-img" alt="Ricetta">
                    <% } else { %>
                        <div class="grid-img default-recipe-img"></div>
                    <% } %>
                    <div class="grid-info">
                        <h3 class="grid-title"><%= rsSaved.getString("titolo") %></h3>
                        <p style="font-size: 13px; color: var(--text-muted); margin:0;">⏱ <%= rsSaved.getInt("tempo_preparazione_min") %> min</p>
                    </div>
                </div>
            <%  }
                if(!hasSavedRecipes) out.println("<p style='color: var(--text-muted); grid-column: 1 / -1;'>Non hai ancora salvato nessuna ricetta.</p>");
            %>
        </div>

        <%
            } catch(Exception e) { out.println("<p style='color:red;'>Errore caricamento database: " + e.getMessage() + "</p>"); }
        %>

    </main>

    <script src="${pageContext.request.contextPath}/js/profile.js"></script>
</body>
</html>