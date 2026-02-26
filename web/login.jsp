<%@ page contentType="text/html;charset=UTF-8" %>
<!DOCTYPE html>
<html>
<head>
    <title>Login - BakingBread</title>
</head>
<body>

<h2>Login</h2>

<form action="loginAction.jsp" method="post">
    Username o Email:<br>
    <input type="text" name="username" required><br><br>

    Password:<br>
    <input type="password" name="password" required><br><br>

    <input type="submit" value="Accedi">
</form>

<%
    String errore = request.getParameter("errore");
    if (errore != null) {
%>
    <p style="color:red;">Credenziali non valide</p>
<%
    }
%>

</body>
</html>