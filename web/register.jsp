<%@ page import="java.sql.*, java.security.MessageDigest, java.math.BigInteger" %>
<%@ page contentType="text/html;charset=UTF-8" %>
<%
String message = "";
boolean isSuccess = false;

if(request.getMethod().equalsIgnoreCase("POST")) {
    String username = request.getParameter("username");
    String email = request.getParameter("email");
    String password = request.getParameter("password");
    String nome_visualizzato = request.getParameter("nome_visualizzato");

    if(username == null || email == null || password == null || username.isEmpty() || email.isEmpty() || password.isEmpty()) {
        message = "Compila tutti i campi obbligatori.";
    } else {
        String password_hash = "";
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            md.update(password.getBytes("UTF-8"));
            password_hash = String.format("%064x", new BigInteger(1, md.digest()));
        } catch(Exception e) {
            message = "Errore hash: " + e.getMessage();
        }

        String USER = "root";
        String PASSWORD = "";
        String DSN = "jdbc:mysql://localhost:3306/bakingbread?useSSL=false&serverTimezone=UTC";

        try (Connection conn = DriverManager.getConnection(DSN, USER, PASSWORD)) {
            Class.forName("com.mysql.cj.jdbc.Driver");
            String sql = "INSERT INTO utenti (username, email, password_hash, nome_visualizzato) VALUES (?, ?, ?, ?)";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setString(1, username);
            ps.setString(2, email);
            ps.setString(3, password_hash);
            ps.setString(4, nome_visualizzato);
            ps.executeUpdate();
            
            message = "Registrazione completata con successo.";
            isSuccess = true;
        } catch(SQLException sqle) {
            if(sqle.getErrorCode() == 1062) { message = "Username o email già registrati."; } 
            else { message = "Errore SQL: " + sqle.getMessage(); }
        } catch(Exception e) {
            message = "Errore: " + e.getMessage();
        }
    }
}
%>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Registrazione - BakingBread</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/global.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/auth.css">
</head>
<body>
    <div class="auth-wrapper">
        <div class="auth-card">
            <div class="auth-header">
                <h2>Crea un Account</h2>
            </div>

            <form method="post" action="register.jsp" id="registerForm">
                <div class="form-group">
                    <label for="username">Username*</label>
                    <input type="text" id="username" name="username" placeholder="Scegli un username" required>
                </div>

                <div class="form-group">
                    <label for="email">Email*</label>
                    <input type="email" id="email" name="email" placeholder="es. mario@email.com" required>
                </div>

                <div class="form-group">
                    <label for="nome_visualizzato">Nome Visualizzato</label>
                    <input type="text" id="nome_visualizzato" name="nome_visualizzato" placeholder="Come vuoi farti chiamare?">
                </div>

                <div class="form-group">
                    <label for="password">Password*</label>
                    <input type="password" id="password" name="password" placeholder="Minimo 6 caratteri" required>
                    <button type="button" class="password-toggle" id="togglePassword">Mostra</button>
                </div>

                <button type="submit" class="btn-primary">Registrati</button>
            </form>

            <% if(!message.isEmpty()) { %>
                <div class="alert <%= isSuccess ? "alert-success" : "alert-error" %>">
                    <%= message %>
                </div>
            <% } %>

            <div class="text-center mt-3">
                <p style="font-size: 14px; color: var(--text-muted);">Hai già un account? <a href="login.jsp">Accedi qui</a></p>
            </div>
        </div>
    </div>
    
    <script src="${pageContext.request.contextPath}/js/register.js"></script>
</body>
</html>