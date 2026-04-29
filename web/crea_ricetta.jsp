<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, java.util.*, com.bakingbread.util.UrlUtils" %>
<%
    response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    Integer idUtente = (Integer) session.getAttribute("id_utente");
    if (idUtente == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String ctx = request.getContextPath();
    int idRicettaModifica = 0;
    try { idRicettaModifica = Integer.parseInt(request.getParameter("modifica")); } catch (Exception ignore) {}
    boolean isModifica = idRicettaModifica > 0;

    Map<String, Object> ricetta = null;
    List<Map<String, Object>> ingredienti = new ArrayList<Map<String, Object>>();
    List<Map<String, Object>> passaggi = new ArrayList<Map<String, Object>>();

    if (isModifica) {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/bakingbread?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true", "root", "");
            PreparedStatement ps = conn.prepareStatement("SELECT * FROM Ricetta WHERE id_ricetta = ? AND id_utente = ?");
            ps.setInt(1, idRicettaModifica);
            ps.setInt(2, idUtente);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                ricetta = new HashMap<String, Object>();
                ricetta.put("titolo", rs.getString("titolo"));
                ricetta.put("descrizione", rs.getString("descrizione"));
                ricetta.put("categoria", rs.getString("categoria"));
                ricetta.put("tempo_preparazione_min", rs.getObject("tempo_preparazione_min"));
                ricetta.put("tempo_cottura_min", rs.getObject("tempo_cottura_min"));
                ricetta.put("porzioni", rs.getObject("porzioni"));
                ricetta.put("difficolta", rs.getString("difficolta"));
                ricetta.put("dieta", rs.getString("dieta"));
                ricetta.put("immagine_url", rs.getString("immagine_url"));
                ricetta.put("pubblicata", rs.getBoolean("pubblicata"));
            }
            rs.close();
            ps.close();

            if (ricetta != null) {
                ps = conn.prepareStatement("SELECT i.nome, ri.quantita, ri.unita_misura FROM RicettaIngrediente ri JOIN Ingrediente i ON ri.id_ingrediente = i.id_ingrediente WHERE ri.id_ricetta = ? ORDER BY ri.ordine_visualizzazione");
                ps.setInt(1, idRicettaModifica);
                rs = ps.executeQuery();
                while (rs.next()) {
                    Map<String, Object> item = new HashMap<String, Object>();
                    item.put("nome", rs.getString("nome"));
                    item.put("quantita", rs.getString("quantita"));
                    item.put("unita", rs.getString("unita_misura"));
                    ingredienti.add(item);
                }
                rs.close();
                ps.close();

                ps = conn.prepareStatement("SELECT descrizione FROM Passaggio WHERE id_ricetta = ? ORDER BY ordine");
                ps.setInt(1, idRicettaModifica);
                rs = ps.executeQuery();
                while (rs.next()) {
                    Map<String, Object> item = new HashMap<String, Object>();
                    item.put("descrizione", rs.getString("descrizione"));
                    passaggi.add(item);
                }
                rs.close();
                ps.close();
            }
            conn.close();
        } catch (Exception ignore) {}
    }

    if (ricetta == null && isModifica) {
        response.sendRedirect("home.jsp");
        return;
    }

    String titoloVal = ricetta != null && ricetta.get("titolo") != null ? (String) ricetta.get("titolo") : "";
    String descrizioneVal = ricetta != null && ricetta.get("descrizione") != null ? (String) ricetta.get("descrizione") : "";
    String categoriaVal = ricetta != null && ricetta.get("categoria") != null ? (String) ricetta.get("categoria") : "";
    String prepVal = ricetta != null && ricetta.get("tempo_preparazione_min") != null ? String.valueOf(ricetta.get("tempo_preparazione_min")) : "15";
    String cotturaVal = ricetta != null && ricetta.get("tempo_cottura_min") != null ? String.valueOf(ricetta.get("tempo_cottura_min")) : "30";
    String porzioniVal = ricetta != null && ricetta.get("porzioni") != null ? String.valueOf(ricetta.get("porzioni")) : "4";
    String difficoltaVal = ricetta != null && ricetta.get("difficolta") != null ? (String) ricetta.get("difficolta") : "facile";
    String dietaVal = ricetta != null && ricetta.get("dieta") != null ? (String) ricetta.get("dieta") : "";
    String immagineVal = UrlUtils.resolve(ctx, ricetta != null && ricetta.get("immagine_url") != null ? (String) ricetta.get("immagine_url") : "");
    boolean pubblicata = ricetta == null || Boolean.TRUE.equals(ricetta.get("pubblicata"));
%>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= isModifica ? "Modifica" : "Crea" %> ricetta - BakingBread</title>
    <link rel="stylesheet" href="<%= ctx %>/css/global.css">
    <link rel="stylesheet" href="<%= ctx %>/css/recipe.css">
    <link rel="icon" href="<%= ctx %>/media/favicon.svg">
</head>
<body>
    <jsp:include page="navbar.jsp" />

    <main class="container recipe-form-page">
        <section class="card recipe-form-card animate-entrance">
            <div class="section-head">
                <div>
                    <p class="eyebrow"><%= isModifica ? "Aggiorna" : "Nuova" %> ricetta</p>
                    <h1><%= isModifica ? "Modifica la tua ricetta" : "Crea una ricetta" %></h1>
                </div>
            </div>

            <form class="recipe-form" method="post" action="<%= ctx %>/recipe/save" enctype="multipart/form-data">
                <input type="hidden" name="id_ricetta" value="<%= isModifica ? idRicettaModifica : "" %>">
                <input type="hidden" name="current_image_url" value="<%= immagineVal == null ? "" : immagineVal %>">

                <div class="recipe-hero-upload">
                    <div class="image-preview-box" id="imagePreviewBox">
                        <% if (immagineVal != null && !immagineVal.trim().isEmpty()) { %>
                            <img src="<%= immagineVal %>" alt="Anteprima" class="image-preview-img">
                        <% } else { %>
                            <span class="image-preview-placeholder">+</span>
                        <% } %>
                    </div>
                    <div class="hero-upload-copy">
                        <h3>Immagine della ricetta</h3>
                        <p>Carica un file dal computer oppure incolla un URL immagine.</p>
                        <input type="file" name="recipe_image_file" id="recipe_image_file" accept="image/*" class="file-input" onchange="handleRecipeImagePreview(this)">
                        <input type="url" name="immagine_url" placeholder="https://..." value="<%= immagineVal == null ? "" : immagineVal %>">
                    </div>
                </div>

                <div class="form-grid-2">
                    <div class="form-group"><label for="titolo">Titolo</label><input type="text" id="titolo" name="titolo" maxlength="200" required value="<%= titoloVal %>" placeholder="Es. Tiramisu classico"></div>
                    <div class="form-group"><label for="categoria">Categoria</label>
                        <select id="categoria" name="categoria">
                            <option value="">Seleziona...</option>
                            <option value="Antipasto" <%= "Antipasto".equals(categoriaVal) ? "selected" : "" %>>Antipasto</option>
                            <option value="Primo" <%= "Primo".equals(categoriaVal) ? "selected" : "" %>>Primo piatto</option>
                            <option value="Secondo" <%= "Secondo".equals(categoriaVal) ? "selected" : "" %>>Secondo piatto</option>
                            <option value="Contorno" <%= "Contorno".equals(categoriaVal) ? "selected" : "" %>>Contorno</option>
                            <option value="Dessert" <%= "Dessert".equals(categoriaVal) ? "selected" : "" %>>Dessert</option>
                            <option value="Bevanda" <%= "Bevanda".equals(categoriaVal) ? "selected" : "" %>>Bevanda</option>
                        </select>
                    </div>
                </div>

                <div class="form-group"><label for="descrizione">Descrizione</label><textarea id="descrizione" name="descrizione" rows="4" placeholder="Descrivi la tua ricetta..."><%= descrizioneVal %></textarea></div>

                <div class="form-grid-3">
                    <div class="form-group"><label for="tempo_preparazione">Tempo prep. (min)</label><input type="number" id="tempo_preparazione" name="tempo_preparazione" min="0" value="<%= prepVal %>"></div>
                    <div class="form-group"><label for="tempo_cottura">Tempo cottura (min)</label><input type="number" id="tempo_cottura" name="tempo_cottura" min="0" value="<%= cotturaVal %>"></div>
                    <div class="form-group"><label for="porzioni">Porzioni</label><input type="number" id="porzioni" name="porzioni" min="1" max="50" value="<%= porzioniVal %>"></div>
                </div>

                <div class="form-grid-2">
                    <div class="form-group"><label for="difficolta">Difficoltà</label>
                        <select id="difficolta" name="difficolta">
                            <option value="facile" <%= "facile".equals(difficoltaVal) ? "selected" : "" %>>Facile</option>
                            <option value="media" <%= "media".equals(difficoltaVal) ? "selected" : "" %>>Media</option>
                            <option value="difficile" <%= "difficile".equals(difficoltaVal) ? "selected" : "" %>>Difficile</option>
                        </select>
                    </div>
                    <div class="form-group"><label for="dieta">Dieta</label>
                        <select id="dieta" name="dieta">
                            <option value="">Nessuna</option>
                            <option value="vegetariana" <%= "vegetariana".equals(dietaVal) ? "selected" : "" %>>Vegetariana</option>
                            <option value="vegana" <%= "vegana".equals(dietaVal) ? "selected" : "" %>>Vegana</option>
                            <option value="senza glutine" <%= "senza glutine".equals(dietaVal) ? "selected" : "" %>>Senza glutine</option>
                            <option value="senza lattosio" <%= "senza lattosio".equals(dietaVal) ? "selected" : "" %>>Senza lattosio</option>
                        </select>
                    </div>
                </div>

                <label class="switch-row"><input type="checkbox" name="pubblica" <%= pubblicata ? "checked" : "" %>><span>Pubblica la ricetta</span></label>

                <section class="editor-block">
                    <div class="section-head compact">
                        <div><p class="eyebrow">Ingredienti</p><h2>Aggiungi gli ingredienti</h2></div>
                        <button type="button" class="btn-outline" onclick="aggiungiIngrediente()">Aggiungi ingrediente</button>
                    </div>
                    <div id="ingredienti-container" class="dynamic-list">
                        <% if (!ingredienti.isEmpty()) { %>
                            <% for (Map<String, Object> ing : ingredienti) { %>
                                <div class="row-item">
                                    <input type="text" name="ingrediente_nome" placeholder="Ingrediente" value="<%= ing.get("nome") %>" required>
                                    <input type="text" name="ingrediente_quantita" placeholder="Quantità" value="<%= ing.get("quantita") != null ? ing.get("quantita") : "" %>">
                                    <input type="text" name="ingrediente_unita" placeholder="Unità" value="<%= ing.get("unita") != null ? ing.get("unita") : "" %>">
                                    <button type="button" class="icon-btn" onclick="rimuoviRiga(this)">×</button>
                                </div>
                            <% } %>
                        <% } else { %>
                            <div class="row-item"><input type="text" name="ingrediente_nome" placeholder="Ingrediente" required><input type="text" name="ingrediente_quantita" placeholder="Quantità"><input type="text" name="ingrediente_unita" placeholder="Unità"><button type="button" class="icon-btn" onclick="rimuoviRiga(this)">×</button></div>
                        <% } %>
                    </div>
                </section>

                <section class="editor-block">
                    <div class="section-head compact">
                        <div><p class="eyebrow">Procedimento</p><h2>Scrivi i passaggi</h2></div>
                        <button type="button" class="btn-outline" onclick="aggiungiPassaggio()">Aggiungi passaggio</button>
                    </div>
                    <div id="passaggi-container" class="dynamic-list">
                        <% if (!passaggi.isEmpty()) { %>
                            <% for (Map<String, Object> step : passaggi) { %>
                                <div class="step-row"><textarea name="passaggio_descrizione" rows="3" placeholder="Descrivi questo passaggio..." required><%= step.get("descrizione") %></textarea><button type="button" class="icon-btn" onclick="rimuoviRiga(this)">×</button></div>
                            <% } %>
                        <% } else { %>
                            <div class="step-row"><textarea name="passaggio_descrizione" rows="3" placeholder="Descrivi questo passaggio..." required></textarea><button type="button" class="icon-btn" onclick="rimuoviRiga(this)">×</button></div>
                        <% } %>
                    </div>
                </section>

                <div class="form-actions"><a href="home.jsp" class="btn-secondary">Annulla</a><button type="submit" class="btn-primary"><%= isModifica ? "Salva modifiche" : "Pubblica ricetta" %></button></div>
            </form>
        </section>
    </main>

    <script src="<%= ctx %>/js/recipe.js"></script>
</body>
</html>
