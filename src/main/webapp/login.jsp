<%@ page import="java.sql.*" %>
<%@ page import="utils.DBUtils" %>
<%
request.setCharacterEncoding("UTF-8");
String msg = "";
if ("POST".equalsIgnoreCase(request.getMethod())) {
    String username = request.getParameter("username");
    String password = request.getParameter("password");
    if (username == null || password == null || username.isEmpty() || password.isEmpty()) {
        msg = "Compila tutti i campi.";
    } else {
        try (Connection c = DBUtils.getConnection()) {
            String sql = "SELECT id_utente, password_hash, nome_visualizzato FROM utenti WHERE username = ? OR email = ?";
            try (PreparedStatement ps = c.prepareStatement(sql)) {
                ps.setString(1, username);
                ps.setString(2, username);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        String hash = rs.getString("password_hash");
                        // In produzione: verifica hash con BCrypt
                        if (password.equals(hash)) {
                            int id = rs.getInt("id_utente");
                            String nome = rs.getString("nome_visualizzato");
                            session.setAttribute("user_id", id);
                            session.setAttribute("user_name", nome);
                            response.sendRedirect("recipe-list.jsp");
                            return;
                        } else {
                            msg = "Credenziali non valide.";
                        }
                    } else {
                        msg = "Utente non trovato.";
                    }
                }
            }
        } catch (SQLException e) {
            msg = "Errore DB: " + e.getMessage();
        }
    }
}
%>
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Login - Baking Bread</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
<h2>Login</h2>
<form method="post">
  <label>Username o Email: <input type="text" name="username"></label><br>
  <label>Password: <input type="password" name="password"></label><br>
  <button type="submit">Accedi</button>
</form>
<p style="color:red;"><%= msg %></p>
<p>Non hai un account? <a href="register.jsp">Registrati</a></p>
</body>
</html>
