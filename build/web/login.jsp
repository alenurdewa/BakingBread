<%@ page import="java.sql.*, java.security.MessageDigest" %>
<%@ page contentType="text/html;charset=UTF-8" %>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login - BakingBread</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/global.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/auth.css">
</head>
<body>
    <div class="auth-wrapper">
        <div class="auth-card">
            <div class="auth-header">
                <h2>Bentornato</h2>
                <p style="color: var(--text-muted); font-size: 14px; margin-top: 5px;">Accedi per continuare su BakingBread</p>
            </div>
            
            <%
                String errorMsg = "";
                if ("POST".equalsIgnoreCase(request.getMethod())) {
                    String username = request.getParameter("username");
                    String password = request.getParameter("password");
                    
                    if (username != null && password != null) {
                        try (Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/bakingbread?useSSL=false", "root", "")) {
                            Class.forName("com.mysql.cj.jdbc.Driver");
                            MessageDigest md = MessageDigest.getInstance("SHA-256");
                            byte[] hash = md.digest(password.getBytes("UTF-8"));
                            StringBuilder hexString = new StringBuilder();
                            for (byte b : hash) {
                                String hex = Integer.toHexString(0xff & b);
                                if(hex.length() == 1) hexString.append('0');
                                hexString.append(hex);
                            }
                            String passwordHash = hexString.toString();

                            String sql = "SELECT id_utente, nome_visualizzato FROM utenti WHERE username = ? AND password_hash = ?";
                            PreparedStatement ps = conn.prepareStatement(sql);
                            ps.setString(1, username);
                            ps.setString(2, passwordHash);
                            
                            ResultSet rs = ps.executeQuery();
                            if (rs.next()) {
                                session.setAttribute("id_utente", rs.getInt("id_utente"));
                                session.setAttribute("nome_utente", rs.getString("nome_visualizzato"));
                                response.sendRedirect("home.jsp");
                                return;
                            } else {
                                errorMsg = "Username o password errati.";
                            }
                        } catch (Exception e) {
                            errorMsg = "Errore di connessione: " + e.getMessage();
                        }
                    }
                }
            %>
            
            <% if (!errorMsg.isEmpty()) { %><div class="alert alert-error"><%= errorMsg %></div><% } %>

            <form method="POST" action="login.jsp">
                <div class="form-group">
                    <label>Username</label>
                    <input type="text" name="username" required>
                </div>
                <div class="form-group">
                    <label>Password</label>
                    <input type="password" name="password" id="pwd" required>
                    <button type="button" class="password-toggle" onclick="togglePwd()">Mostra</button>
                </div>
                <button type="submit" class="btn-primary mt-3">Accedi</button>
            </form>
            <p class="text-center mt-3" style="font-size: 14px;">Non hai un account? <a href="register.jsp">Registrati</a></p>
        </div>
    </div>
    <script>
        function togglePwd() {
            var pwd = document.getElementById("pwd");
            var btn = document.querySelector(".password-toggle");
            if (pwd.type === "password") { pwd.type = "text"; btn.textContent = "Nascondi"; } 
            else { pwd.type = "password"; btn.textContent = "Mostra"; }
        }
    </script>
</body>
</html>