<%@ page import="java.sql.*" %>
<%@ page contentType="text/html;charset=UTF-8" %>
<% if (session.getAttribute("id_utente") == null) { response.sendRedirect("login.jsp"); return; } %>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <title>Crea Ricetta - BakingBread</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/global.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/recipe.css">
</head>
<body>
    <jsp:include page="navbar.jsp" />
    
    <main class="recipe-container">
        <div class="recipe-header">
            <h2>Nuova Ricetta</h2>
        </div>
        
        <%
            if ("POST".equalsIgnoreCase(request.getMethod())) {
                int idUtente = (Integer) session.getAttribute("id_utente");
                String titolo = request.getParameter("titolo");
                String descrizione = request.getParameter("descrizione");
                int tempo = Integer.parseInt(request.getParameter("tempo_preparazione"));
                int porzioni = Integer.parseInt(request.getParameter("porzioni"));
                String immagineBase64 = request.getParameter("immagine_base64"); // Recupera l'immagine come testo!
                
                try (Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/bakingbread?useSSL=false", "root", "")) {
                    Class.forName("com.mysql.cj.jdbc.Driver");
                    String sql = "INSERT INTO ricette (id_utente, titolo, descrizione, tempo_preparazione_min, porzioni, immagine_base64) VALUES (?, ?, ?, ?, ?, ?)";
                    PreparedStatement ps = conn.prepareStatement(sql);
                    ps.setInt(1, idUtente); ps.setString(2, titolo); ps.setString(3, descrizione); 
                    ps.setInt(4, tempo); ps.setInt(5, porzioni); ps.setString(6, immagineBase64);
                    
                    ps.executeUpdate();
                    out.println("<div class='alert alert-success'>Ricetta pubblicata!</div>");
                } catch (Exception e) { out.println("<div class='alert alert-error'>Errore: " + e.getMessage() + "</div>"); }
            }
        %>

        <form method="POST" action="crea_ricetta.jsp">
            <div class="image-upload-box" id="imagePreviewBox" onclick="document.getElementById('fileInput').click()">
                <p>+ Clicca per aggiungere una foto</p>
            </div>
            <input type="file" id="fileInput" style="display:none;" accept="image/*" onchange="handleImageUpload(event)">
            <input type="hidden" name="immagine_base64" id="immagine_base64_input">

            <div class="form-group"><label>Titolo</label><input type="text" name="titolo" required></div>
            <div class="form-group"><label>Descrizione e Passaggi</label><textarea name="descrizione" style="height: 150px;"></textarea></div>
            
            <div class="flex-row">
                <div class="form-group"><label>Minuti</label><input type="number" name="tempo_preparazione" required></div>
                <div class="form-group"><label>Porzioni</label><input type="number" name="porzioni" required></div>
            </div>
            
            <button type="submit" class="btn-primary mt-3">Pubblica</button>
        </form>
    </main>
    <script src="${pageContext.request.contextPath}/js/main.js"></script>
</body>
</html>