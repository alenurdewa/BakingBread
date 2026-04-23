<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, java.util.*" %>
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
    String errorMsg = "";
    String successMsg = "";
    
    int idRicettaModifica = 0;
    try { idRicettaModifica = Integer.parseInt(request.getParameter("modifica")); } catch (Exception e) {}
    boolean isModifica = idRicettaModifica > 0;
    
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String titolo = request.getParameter("titolo");
        String descrizione = request.getParameter("descrizione");
        String categoria = request.getParameter("categoria");
        String tempoPrepStr = request.getParameter("tempo_preparazione");
        String tempoCotturaStr = request.getParameter("tempo_cottura");
        String porzioniStr = request.getParameter("porzioni");
        String difficolta = request.getParameter("difficolta");
        String dieta = request.getParameter("dieta");
        String immagineUrl = request.getParameter("immagine_url");
        String pubblica = request.getParameter("pubblica");
        
        if (titolo == null || titolo.trim().isEmpty()) {
            errorMsg = "Inserisci il titolo della ricetta.";
        } else if (titolo.length() > 200) {
            errorMsg = "Il titolo e' troppo lungo (max 200 caratteri).";
        } else {
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                Connection conn = DriverManager.getConnection(dbUrl, "root", "");
                
                int tempoPrep = 0, tempoCottura = 0, porzioni = 4;
                try { tempoPrep = Integer.parseInt(tempoPrepStr); } catch (Exception ex) {}
                try { tempoCottura = Integer.parseInt(tempoCotturaStr); } catch (Exception ex) {}
                try { porzioni = Integer.parseInt(porzioniStr); } catch (Exception ex) {}
                
                boolean pub = "on".equals(pubblica);
                
                PreparedStatement ps;
                int idNuovaRicetta = 0;
                
                if (isModifica) {
                    ps = conn.prepareStatement(
                        "UPDATE Ricetta SET titolo = ?, descrizione = ?, categoria = ?, " +
                        "tempo_preparazione_min = ?, tempo_cottura_min = ?, porzioni = ?, " +
                        "difficolta = ?, dieta = ?, immagine_url = ?, pubblicata = ?, aggiornato_il = NOW() " +
                        "WHERE id_ricetta = ? AND id_utente = ?");
                    ps.setString(1, titolo.trim());
                    ps.setString(2, descrizione);
                    ps.setString(3, categoria);
                    ps.setInt(4, tempoPrep);
                    ps.setInt(5, tempoCottura);
                    ps.setInt(6, porzioni);
                    ps.setString(7, difficolta);
                    ps.setString(8, dieta);
                    ps.setString(9, immagineUrl);
                    ps.setBoolean(10, pub);
                    ps.setInt(11, idRicettaModifica);
                    ps.setInt(12, idUtenteLoggato);
                    ps.executeUpdate();
                    idNuovaRicetta = idRicettaModifica;
                    ps.close();
                    
                    ps = conn.prepareStatement("DELETE FROM RicettaIngrediente WHERE id_ricetta = ?");
                    ps.setInt(1, idNuovaRicetta);
                    ps.executeUpdate();
                    ps.close();
                    
                    ps = conn.prepareStatement("DELETE FROM Passaggio WHERE id_ricetta = ?");
                    ps.setInt(1, idNuovaRicetta);
                    ps.executeUpdate();
                    ps.close();
                } else {
                    ps = conn.prepareStatement(
                        "INSERT INTO Ricetta (id_utente, titolo, descrizione, categoria, " +
                        "tempo_preparazione_min, tempo_cottura_min, porzioni, difficolta, " +
                        "dieta, immagine_url, pubblicata) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                        PreparedStatement.RETURN_GENERATED_KEYS);
                    ps.setInt(1, idUtenteLoggato);
                    ps.setString(2, titolo.trim());
                    ps.setString(3, descrizione);
                    ps.setString(4, categoria);
                    ps.setInt(5, tempoPrep);
                    ps.setInt(6, tempoCottura);
                    ps.setInt(7, porzioni);
                    ps.setString(8, difficolta);
                    ps.setString(9, dieta);
                    ps.setString(10, immagineUrl);
                    ps.setBoolean(11, pub);
                    ps.executeUpdate();
                    
                    ResultSet rs = ps.getGeneratedKeys();
                    if (rs.next()) {
                        idNuovaRicetta = rs.getInt(1);
                    }
                    rs.close();
                    ps.close();
                }
                
                String[] ingredienti = request.getParameterValues("ingrediente_nome");
                String[] quantitaArr = request.getParameterValues("ingrediente_quantita");
                String[] unitaArr = request.getParameterValues("ingrediente_unita");
                
                if (ingredienti != null) {
                    for (int i = 0; i < ingredienti.length; i++) {
                        String nomeIng = ingredienti[i];
                        if (nomeIng != null && !nomeIng.trim().isEmpty()) {
                            String quantita = quantitaArr != null && quantitaArr.length > i ? quantitaArr[i] : "";
                            String unita = unitaArr != null && unitaArr.length > i ? unitaArr[i] : "";
                            
                            ps = conn.prepareStatement(
                                "SELECT id_ingrediente FROM Ingrediente WHERE nome = ?");
                            ps.setString(1, nomeIng.trim());
                            ResultSet rs = ps.executeQuery();
                            int idIng = 0;
                            if (rs.next()) {
                                idIng = rs.getInt("id_ingrediente");
                            } else {
                                ps.close();
                                ps = conn.prepareStatement(
                                    "INSERT INTO Ingrediente (nome) VALUES (?)",
                                    PreparedStatement.RETURN_GENERATED_KEYS);
                                ps.setString(1, nomeIng.trim());
                                ps.executeUpdate();
                                rs = ps.getGeneratedKeys();
                                if (rs.next()) {
                                    idIng = rs.getInt(1);
                                }
                                rs.close();
                            }
                            ps.close();
                            
                            if (idIng > 0) {
                                ps = conn.prepareStatement(
                                    "INSERT INTO RicettaIngrediente (id_ricetta, id_ingrediente, quantita, unita_misura, ordine_visualizzazione) " +
                                    "VALUES (?, ?, ?, ?, ?)");
                                ps.setInt(1, idNuovaRicetta);
                                ps.setInt(2, idIng);
                                ps.setString(3, quantita);
                                ps.setString(4, unita);
                                ps.setInt(5, i + 1);
                                ps.executeUpdate();
                                ps.close();
                            }
                        }
                    }
                }
                
                String[] passaggi = request.getParameterValues("passaggio_descrizione");
                if (passaggi != null) {
                    for (int i = 0; i < passaggi.length; i++) {
                        String descr = passaggi[i];
                        if (descr != null && !descr.trim().isEmpty()) {
                            ps = conn.prepareStatement(
                                "INSERT INTO Passaggio (id_ricetta, ordine, descrizione) VALUES (?, ?, ?)");
                            ps.setInt(1, idNuovaRicetta);
                            ps.setInt(2, i + 1);
                            ps.setString(3, descr.trim());
                            ps.executeUpdate();
                            ps.close();
                        }
                    }
                }
                
                conn.close();
                
                if (idNuovaRicetta > 0) {
                    successMsg = isModifica ? "Ricetta aggiornata!" : "Ricetta creata con successo!";
                    if (!isModifica) {
                        response.sendRedirect("dettaglio_ricetta.jsp?id=" + idNuovaRicetta);
                        return;
                    }
                }
                
            } catch (Exception ex) {
                errorMsg = "Errore nel salvataggio: " + ex.getMessage();
            }
        }
    }
    
    Map<String, Object> ricettaModifica = null;
    List<Map<String, Object>> ingredientiModifica = new ArrayList<>();
    List<Map<String, Object>> passaggiModifica = new ArrayList<>();
    
    if (isModifica) {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection(dbUrl, "root", "");
            
            PreparedStatement ps = conn.prepareStatement(
                "SELECT * FROM Ricetta WHERE id_ricetta = ? AND id_utente = ?");
            ps.setInt(1, idRicettaModifica);
            ps.setInt(2, idUtenteLoggato);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                ricettaModifica = new HashMap<>();
                ricettaModifica.put("titolo", rs.getString("titolo"));
                ricettaModifica.put("descrizione", rs.getString("descrizione"));
                ricettaModifica.put("categoria", rs.getString("categoria"));
                ricettaModifica.put("tempo_preparazione_min", rs.getInt("tempo_preparazione_min"));
                ricettaModifica.put("tempo_cottura_min", rs.getInt("tempo_cottura_min"));
                ricettaModifica.put("porzioni", rs.getInt("porzioni"));
                ricettaModifica.put("difficolta", rs.getString("difficolta"));
                ricettaModifica.put("dieta", rs.getString("dieta"));
                ricettaModifica.put(" immagine_url", rs.getString(" immagine_url"));
                ricettaModifica.put("pubblicata", rs.getBoolean("pubblicata"));
            }
            rs.close();
            ps.close();
            
            if (ricettaModifica != null) {
                ps = conn.prepareStatement(
                    "SELECT i.nome, ri.quantita, ri.unita_misura " +
                    "FROM RicettaIngrediente ri JOIN Ingrediente i ON ri.id_ingrediente = i.id_ingrediente " +
                    "WHERE ri.id_ricetta = ? ORDER BY ri.ordine_visualizzazione");
                ps.setInt(1, idRicettaModifica);
                rs = ps.executeQuery();
                while (rs.next()) {
                    Map<String, Object> ing = new HashMap<>();
                    ing.put("nome", rs.getString("nome"));
                    ing.put("quantita", rs.getString("quantita"));
                    ing.put("unita", rs.getString("unita_misura"));
                    ingredientiModifica.add(ing);
                }
                rs.close();
                ps.close();
                
                ps = conn.prepareStatement(
                    "SELECT descrizione FROM Passaggio WHERE id_ricetta = ? ORDER BY ordine");
                ps.setInt(1, idRicettaModifica);
                rs = ps.executeQuery();
                while (rs.next()) {
                    Map<String, Object> p = new HashMap<>();
                    p.put("descrizione", rs.getString("descrizione"));
                    passaggiModifica.add(p);
                }
                rs.close();
                ps.close();
            }
            
            conn.close();
        } catch (Exception e) {}
    }
%>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= isModifica ? "Modifica" : "Crea" %> Ricetta - BakingBread</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/global.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/recipe.css">
    <link rel="icon" href="${pageContext.request.contextPath}/media/favicon.svg">
</head>
<body>
    <jsp:include page="navbar.jsp" />
    
    <main class="container mt-4">
        <div class="post-card animate-entrance" style="max-width:800px;margin:0 auto;">
            <h2><%= isModifica ? "Modifica" : "Crea" %> Ricetta</h2>
            
            <% if (!errorMsg.isEmpty()) { %>
                <div class="alert alert-error mt-3">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:8px;">
                        <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>
                    </svg>
                    <%= errorMsg %>
                </div>
            <% } %>
            
            <% if (!successMsg.isEmpty()) { %>
                <div class="alert alert-success mt-3">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:8px;">
                        <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/>
                    </svg>
                    <%= successMsg %>
                </div>
            <% } %>
            
            <form method="POST" action="crea_ricetta.jsp<%= isModifica ? "?modifica=" + idRicettaModifica : "" %>" accept-charset="UTF-8">
                <div class="form-group mt-4">
                    <label for="titolo">Titolo *</label>
                    <input type="text" id="titolo" name="titolo" required maxlength="200"
                           value="<%= ricettaModifica != null ? ricettaModifica.get("titolo") : "" %>"
                           placeholder="Es. Tiramisu classico">
                </div>
                
                <div class="form-group">
                    <label for="descrizione">Descrizione</label>
                    <textarea id="descrizione" name="descrizione" rows="3"
                            placeholder="Descrivi la tua ricetta..."><%= ricettaModifica != null ? ricettaModifica.get("descrizione") : "" %></textarea>
                </div>
                
                <div class="form-group">
                    <label for="categoria">Categoria</label>
                    <select id="categoria" name="categoria">
                        <option value="">Seleziona...</option>
                        <option value="Antipasto" <%= "Antipasto".equals(ricettaModifica != null ? ricettaModifica.get("categoria") : "") ? "selected" : "" %>>Antipasto</option>
                        <option value="Primo" <%= "Primo".equals(ricettaModifica != null ? ricettaModifica.get("categoria") : "") ? "selected" : "" %>>Primo piatto</option>
                        <option value="Secondo" <%= "Secondo".equals(ricettaModifica != null ? ricettaModifica.get("categoria") : "") ? "selected" : "" %>>Secondo piatto</option>
                        <option value="Contorno" <%= "Contorno".equals(ricettaModifica != null ? ricettaModifica.get("categoria") : "") ? "selected" : "" %>>Contorno</option>
                        <option value="Dessert" <%= "Dessert".equals(ricettaModifica != null ? ricettaModifica.get("categoria") : "") ? "selected" : "" %>>Dessert</option>
                        <option value="Bevanda" <%= "Bevanda".equals(ricettaModifica != null ? ricettaModifica.get("categoria") : "") ? "selected" : "" %>>Bevanda</option>
                    </select>
                </div>
                
                <div class="row mt-3">
                    <div class="col-md-4">
                        <div class="form-group">
                            <label for="tempo_preparazione">Tempo Prep (min)</label>
                            <input type="number" id="tempo_preparazione" name="tempo_preparazione" min="0"
                                   value="<%= ricettaModifica != null ? ricettaModifica.get("tempo_preparazione_min") : "15" %>">
                        </div>
                    </div>
                    <div class="col-md-4">
                        <div class="form-group">
                            <label for="tempo_cottura">Tempo Cottura (min)</label>
                            <input type="number" id="tempo_cottura" name="tempo_cottura" min="0"
                                   value="<%= ricettaModifica != null ? ricettaModifica.get("tempo_cottura_min") : "30" %>">
                        </div>
                    </div>
                    <div class="col-md-4">
                        <div class="form-group">
                            <label for="porzioni">Porzioni</label>
                            <input type="number" id="porzioni" name="porzioni" min="1" max="20"
                                   value="<%= ricettaModifica != null ? ricettaModifica.get("porzioni") : "4" %>">
                        </div>
                    </div>
                </div>
                
                <div class="row mt-3">
                    <div class="col-md-6">
                        <div class="form-group">
                            <label for="difficolta">Difficolta</label>
                            <select id="difficolta" name="difficolta">
                                <option value="facile" <%= "facile".equals(ricettaModifica != null ? ricettaModifica.get("difficolta") : "") ? "selected" : "" %>>Facile</option>
                                <option value="media" <%= "media".equals(ricettaModifica != null ? ricettaModifica.get("difficolta") : "") ? "selected" : "" %>>Media</option>
                                <option value="difficile" <%= "difficile".equals(ricettaModifica != null ? ricettaModifica.get("difficolta") : "") ? "selected" : "" %>>Difficile</option>
                            </select>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="form-group">
                            <label for="dieta">Dieta</label>
                            <select id="dieta" name="dieta">
                                <option value="">Nessuna</option>
                                <option value="vegetariana" <%= "vegetariana".equals(ricettaModifica != null ? ricettaModifica.get("dieta") : "") ? "selected" : "" %>>Vegetariana</option>
                                <option value="vegana" <%= "vegana".equals(ricettaModifica != null ? ricettaModifica.get("dieta") : "") ? "selected" : "" %>>Vegana</option>
                                <option value="senza glutine" <%= "senza glutine".equals(ricettaModifica != null ? ricettaModifica.get("dieta") : "") ? "selected" : "" %>>Senza Glutine</option>
                                <option value="senza lattosio" <%= "senza lattosio".equals(ricettaModifica != null ? ricettaModifica.get("dieta") : "") ? "selected" : "" %>>Senza Lattosio</option>
                            </select>
                        </div>
                    </div>
                </div>
                
                <div class="form-group mt-3">
                    <label for=" immagine_url">URL Immagine</label>
                    <input type="url" id=" immagine_url" name=" immagine_url" 
                           value="<%= ricettaModifica != null ? ricettaModifica.get(" immagine_url") : "" %>"
                           placeholder="https://...">
                    <small class="text-muted">Inserisci l'URL di un'immagine per la ricetta</small>
                </div>
                
                <div class="form-group mt-3">
                    <label class="d-flex align-items-center" style="cursor:pointer;">
                        <input type="checkbox" name="pubblica" id="pubblica" style="width:auto;margin-right:8px;"
                               <%= (ricettaModifica != null && (Boolean)ricettaModifica.get("pubblicata")) || ricettaModifica == null ? "checked" : "" %>>
                        <span>Pubblica la ricetta</span>
                    </label>
                </div>
                
                <hr style="margin:30px 0;">
                
                <h3>Ingredienti</h3>
                <div id="ingredienti-container">
                    <% if (ingredientiModifica.size() > 0) { %>
                        <% for (Map<String, Object> ing : ingredientiModifica) { %>
                            <div class="ingrediente-row d-flex gap-2 mt-2">
                                <input type="text" name="ingrediente_nome[]" placeholder="Ingrediente" value="<%= ing.get("nome") %>" style="flex:2;">
                                <input type="text" name="ingrediente_quantita[]" placeholder="Qta" value="<%= ing.get("quantita") %>" style="flex:1;">
                                <input type="text" name="ingrediente_unita[]" placeholder="Unita" value="<%= ing.get("unita") %>" style="flex:1;">
                                <button type="button" class="btn-secondary btn-icon" onclick="this.parentElement.remove()">
                                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
                                    </svg>
                                </button>
                            </div>
                        <% } %>
                    <% } else { %>
                        <div class="ingrediente-row d-flex gap-2 mt-2">
                            <input type="text" name="ingrediente_nome[]" placeholder="Ingrediente" style="flex:2;">
                            <input type="text" name="ingrediente_quantita[]" placeholder="Qta" style="flex:1;">
                            <input type="text" name="ingrediente_unita[]" placeholder="Unita" style="flex:1;">
                            <button type="button" class="btn-secondary btn-icon" onclick="this.parentElement.remove()">
                                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
                                </svg>
                            </button>
                        </div>
                    <% } %>
                </div>
                <button type="button" class="btn-outline mt-3" onclick="aggiungiIngrediente()">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:8px;">
                        <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
                    </svg>
                    Aggiungi Ingrediente
                </button>
                
                <hr style="margin:30px 0;">
                
                <h3>Procedimento</h3>
                <div id="passaggi-container">
                    <% if (passaggiModifica.size() > 0) { %>
                        <% for (Map<String, Object> p : passaggiModifica) { %>
                            <div class="passaggio-row d-flex gap-2 mt-2">
                                <textarea name="passaggio_descrizione[]" placeholder="Descrivi questo passaggio..." rows="2"><%= p.get("descrizione") %></textarea>
                                <button type="button" class="btn-secondary btn-icon" onclick="this.parentElement.remove()">
                                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
                                    </svg>
                                </button>
                            </div>
                        <% } %>
                    <% } else { %>
                        <div class="passaggio-row d-flex gap-2 mt-2">
                            <textarea name="passaggio_descrizione[]" placeholder="Descrivi questo passaggio..." rows="2"></textarea>
                            <button type="button" class="btn-secondary btn-icon" onclick="this.parentElement.remove()">
                                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
                                </svg>
                            </button>
                        </div>
                    <% } %>
                </div>
                <button type="button" class="btn-outline mt-3" onclick="aggiungiPassaggio()">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:8px;">
                        <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
                    </svg>
                    Aggiungi Passaggio
                </button>
                
                <hr style="margin:30px 0;">
                
                <button type="submit" class="btn-primary">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:8px;">
                        <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/><polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/>
                    </svg>
                    <%= isModifica ? "Salva Modifiche" : "Crea Ricetta" %>
                </button>
            </form>
        </div>
    </main>
    
    <script>
    function aggiungiIngrediente() {
        var container = document.getElementById('ingredienti-container');
        var row = document.createElement('div');
        row.className = 'ingrediente-row d-flex gap-2 mt-2';
        row.innerHTML = '<input type="text" name="ingrediente_nome[]" placeholder="Ingrediente" style="flex:2;"><input type="text" name="ingrediente_quantita[]" placeholder="Qta" style="flex:1;"><input type="text" name="ingrediente_unita[]" placeholder="Unita" style="flex:1;"><button type="button" class="btn-secondary btn-icon" onclick="this.parentElement.remove()"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg></button>';
        container.appendChild(row);
    }
    
    function aggiungiPassaggio() {
        var container = document.getElementById('passaggi-container');
        var row = document.createElement('div');
        row.className = 'passaggio-row d-flex gap-2 mt-2';
        row.innerHTML = '<textarea name="passaggio_descrizione[]" placeholder="Descrivi questo passaggio..." rows="2"></textarea><button type="button" class="btn-secondary btn-icon" onclick="this.parentElement.remove()"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg></button>';
        container.appendChild(row);
    }
    </script>
</body>
</html>