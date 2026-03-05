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
                <h2>Accedi a BakingBread</h2>
            </div>

            <form action="loginAction.jsp" method="post">
                <div class="form-group">
                    <label for="username">Username o Email</label>
                    <input type="text" id="username" name="username" placeholder="Es. mario.rossi" required>
                </div>

                <div class="form-group">
                    <label for="password">Password</label>
                    <input type="password" id="password" name="password" placeholder="••••••••" required>
                    <button type="button" class="password-toggle" id="togglePassword">Mostra</button>
                </div>

                <button type="submit" class="btn-primary">Accedi</button>
            </form>

            <% String errore = request.getParameter("errore");
               if (errore != null) { %>
                <div class="alert alert-error">Credenziali non valide. Riprova.</div>
            <% } %>

            <div class="text-center mt-3">
                <p style="font-size: 14px; color: var(--text-muted);">Non hai un account? <a href="register.jsp">Registrati ora</a></p>
            </div>
        </div>
    </div>
    
    <script src="${pageContext.request.contextPath}/js/login.js"></script>
</body>
</html>