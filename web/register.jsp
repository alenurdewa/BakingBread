<%@ page import="java.sql.*, java.security.MessageDigest, java.math.BigInteger" %>
<%@ page contentType="text/html;charset=UTF-8" %>
<html>
<head>
    <title>Registrazione Utente - BakingBread</title>
</head>
<body>
<h2>Registrazione Utente</h2>

<%
String message = "";
if(request.getMethod().equalsIgnoreCase("POST")) {
    String username = request.getParameter("username");
    String email = request.getParameter("email");
    String password = request.getParameter("password");
    String nome_visualizzato = request.getParameter("nome_visualizzato");

    if(username == null || email == null || password == null || username.isEmpty() || email.isEmpty() || password.isEmpty()) {
        message = "Compila tutti i campi obbligatori!";
    } else {
        // Hash della password con SHA-256
        String password_hash = "";
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            md.update(password.getBytes("UTF-8"));
            password_hash = String.format("%064x", new BigInteger(1, md.digest()));
        } catch(Exception e) {
            message = "Errore durante la generazione dell'hash della password: " + e.getMessage();
        }

        // Connessione al DB
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
            message = "Registrazione completata con successo ✅";

        } catch(SQLException sqle) {
            if(sqle.getErrorCode() == 1062) { // duplicate entry
                message = "Username o email già registrati!";
            } else {
                message = "Errore SQL: " + sqle.getMessage();
            }
        } catch(Exception e) {
            message = "Errore: " + e.getMessage();
        }
    }
}
%>

<form method="post" action="register.jsp">
    <label>Username*:</label><br>
    <input type="text" name="username" required><br><br>

    <label>Email*:</label><br>
    <input type="email" name="email" required><br><br>

    <label>Password*:</label><br>
    <input type="password" name="password" required><br><br>

    <label>Nome Visualizzato:</label><br>
    <input type="text" name="nome_visualizzato"><br><br>

    <input type="submit" value="Registrati">
</form>

<% if(!message.isEmpty()) { %>
    <p style="color: <%= message.contains("successo") ? "green" : "red" %>;"><%= message %></p>
<% } %>

</body>
</html>