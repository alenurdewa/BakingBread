<%@ page import="java.sql.*, java.security.MessageDigest" %>
<%@ page contentType="text/html;charset=UTF-8" %>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Registrati - BakingBread</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/global.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/auth.css">
</head>
<body>
    <div class="auth-wrapper">
        <div class="auth-card">
            <div class="auth-header">
                <h2>Crea Account</h2>
                <p style="color: var(--text-muted); font-size: 14px; margin-top: 5px;">Unisciti alla community di BakingBread</p>
            </div>
            
            <%
                String errorMsg = ""; String successMsg = "";
                if ("POST".equalsIgnoreCase(request.getMethod())) {
                    String username = request.getParameter("username");
                    String email = request.getParameter("email");
                    String password = request.getParameter("password");
                    
                    if (username != null && email != null && password != null && !username.isEmpty()) {
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
                            
                            String sql = "INSERT INTO utenti (username, email, password_hash, nome_visualizzato) VALUES (?, ?, ?, ?)";
                            PreparedStatement ps = conn.prepareStatement(sql);
                            ps.setString(1, username); ps.setString(2, email); ps.setString(3, hexString.toString()); ps.setString(4, username);
                            
                            if (ps.executeUpdate() > 0) {
                                successMsg = "Registrazione completata! Ora puoi fare il <a href='login.jsp'>Login</a>.";
                            }
                        } catch (SQLIntegrityConstraintViolationException e) { errorMsg = "Username o Email già in uso.";
                        } catch (Exception e) { errorMsg = "Errore: " + e.getMessage(); }
                    }
                }
            %>
            
            <% if (!errorMsg.isEmpty()) { %><div class="alert alert-error"><%= errorMsg %></div><% } %>
            <% if (!successMsg.isEmpty()) { %><div class="alert alert-success"><%= successMsg %></div><% } %>

            <form method="POST" action="register.jsp">
                <div class="form-group"><label>Username</label><input type="text" name="username" required></div>
                <div class="form-group"><label>Email</label><input type="email" name="email" required></div>
                <div class="form-group"><label>Password</label><input type="password" name="password" required></div>
                <button type="submit" class="btn-primary mt-3">Registrati</button>
            </form>
            <p class="text-center mt-3" style="font-size: 14px;">Hai già un account? <a href="login.jsp">Accedi</a></p>
        </div>
    </div>
</body>
</html>