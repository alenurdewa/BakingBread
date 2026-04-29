<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, java.security.*, java.util.*" %>
<%
    // Header per evitare cache
    response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    String errorMsg = "";
    String successMsg = "";
    
    // Se l'utente è già loggato, reindirizza alla home
    Integer idUtenteLoggato = (Integer) session.getAttribute("id_utente");
    if (idUtenteLoggato != null) {
        response.sendRedirect("home.jsp");
        return;
    }
    
    // Parametri DB - Modificati per Driver 9.6.0 e sicurezza timezone
    String dbUrl = "jdbc:mysql://localhost:3306/bakingbread?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true";
    String dbUser = "root";
    String dbPass = ""; // Inserisci la tua password se presente
    
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String username = request.getParameter("username");
        String email = request.getParameter("email");
        String password = request.getParameter("password");
        String confermaPassword = request.getParameter("conferma_password");
        
        // Validazione Input
        if (username == null || username.trim().isEmpty()) {
            errorMsg = "Inserisci il nome utente.";
        } else if (username.length() < 3 || username.length() > 50) {
            errorMsg = "Il nome utente deve essere tra 3 e 50 caratteri.";
        } else if (!username.matches("^[a-zA-Z0-9_]+$")) {
            errorMsg = "Il nome utente può contenere solo lettere, numeri e underscore.";
        } else if (email == null || email.trim().isEmpty()) {
            errorMsg = "Inserisci l'indirizzo email.";
        } else if (!email.matches("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+$")) {
            errorMsg = "Inserisci un indirizzo email valido.";
        } else if (password == null || password.length() < 8) {
            errorMsg = "La password deve essere di almeno 8 caratteri.";
        } else if (!password.equals(confermaPassword)) {
            errorMsg = "Le password non corrispondono.";
        } else {
            // Logica di Registrazione
            Connection conn = null;
            PreparedStatement ps = null;
            ResultSet rs = null;
            try {
                // Caricamento Driver (per mysql-connector-j-9.6.0.jar)
                Class.forName("com.mysql.cj.jdbc.Driver");
                conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
                
                // 1. Controllo se utente o email esistono già
                ps = conn.prepareStatement("SELECT id_utente FROM Utente WHERE username = ? OR email = ?");
                ps.setString(1, username.trim());
                ps.setString(2, email.trim().toLowerCase());
                rs = ps.executeQuery();
                
                if (rs.next()) {
                    errorMsg = "Nome utente o email già in uso.";
                } else {
                    // 2. Generazione SALT e HASH SHA-256
                    SecureRandom random = new SecureRandom();
                    byte[] salt = new byte[16];
                    random.nextBytes(salt);
                    
                    StringBuilder saltHex = new StringBuilder();
                    for (byte b : salt) {
                        String hex = Integer.toHexString(0xff & b);
                        if (hex.length() == 1) saltHex.append('0');
                        saltHex.append(hex);
                    }
                    
                    MessageDigest md = MessageDigest.getInstance("SHA-256");
                    md.update(salt);
                    byte[] hash = md.digest(password.getBytes("UTF-8"));
                    
                    StringBuilder hashHex = new StringBuilder();
                    for (byte b : hash) {
                        String hex = Integer.toHexString(0xff & b);
                        if (hex.length() == 1) hashHex.append('0');
                        hashHex.append(hex);
                    }
                    
                    // Concateniamo salt (32 chars) + hash (64 chars)
                    String passwordHash = saltHex.toString() + hashHex.toString();
                    
                    // 3. Inserimento nuovo utente
                    // Nota: Chiudiamo il vecchio ps prima di aprirne uno nuovo
                    ps.close(); 
                    ps = conn.prepareStatement(
                        "INSERT INTO Utente (username, email, password_hash, nome_visualizzato, attivo) " +
                        "VALUES (?, ?, ?, ?, TRUE)");
                    ps.setString(1, username.trim());
                    ps.setString(2, email.trim().toLowerCase());
                    ps.setString(3, passwordHash);
                    ps.setString(4, username.trim()); // Nome visualizzato default = username
                    
                    if (ps.executeUpdate() > 0) {
                        successMsg = "Account creato con successo! Ora puoi <a href='login.jsp'>accedere</a>.";
                    }
                }
            } catch (ClassNotFoundException e) {
                errorMsg = "Errore critico: Driver JDBC non trovato. Controlla WEB-INF/lib.";
            } catch (SQLException e) {
                errorMsg = "Errore Database: " + e.getMessage();
            } catch (Exception e) {
                errorMsg = "Errore imprevisto: " + e.getMessage();
            } finally {
                // CHIUSURA RISORSE (Fondamentale)
                if (rs != null) try { rs.close(); } catch (Exception e) {}
                if (ps != null) try { ps.close(); } catch (Exception e) {}
                if (conn != null) try { conn.close(); } catch (Exception e) {}
            }
        }
    }
%>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Registrati - BakingBread</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/global.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/auth.css">
    <link rel="icon" href="${pageContext.request.contextPath}/media/favicon.svg">
</head>
<body>
    <div class="auth-wrapper">
        <div class="auth-card animate-entrance">
            <div class="auth-header">
                <a href="home.jsp" class="navbar-brand" style="justify-content:center;margin-bottom:20px;">
    <img src="media/favicon.svg" alt="BakingBread Logo" style="width:40px;height:40px;object-fit:contain;">
</a>
                <h2>Crea Account</h2>
                <p class="text-muted">Unisciti alla community di BakingBread</p>
            </div>
            
            <% if (!errorMsg.isEmpty()) { %>
                <div class="alert alert-error">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:8px;flex-shrink:0;">
                        <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>
                    </svg>
                    <%= errorMsg %>
                </div>
            <% } %>
            
            <% if (!successMsg.isEmpty()) { %>
                <div class="alert alert-success">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:8px;flex-shrink:0;">
                        <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/>
                    </svg>
                    <%= successMsg %>
                </div>
            <% } %>
            
            <form method="POST" action="register.jsp" accept-charset="UTF-8">
                <div class="form-group">
                    <label for="username">Nome utente</label>
                    <input type="text" id="username" name="username" required 
                           autocomplete="username" maxlength="50" pattern="[a-zA-Z0-9_]+"
                           value="<%= (request.getParameter("username") != null) ? request.getParameter("username") : "" %>">
                    <small class="text-muted" style="font-size:11px;">Solo lettere, numeri e underscore (_)</small>
                </div>
                
                <div class="form-group">
                    <label for="email">Email</label>
                    <input type="email" id="email" name="email" required 
                           autocomplete="email" maxlength="100"
                           value="<%= (request.getParameter("email") != null) ? request.getParameter("email") : "" %>">
                </div>
                
                <div class="form-group">
                    <label for="password">Password</label>
                    <div style="position:relative;">
                        <input type="password" id="password" name="password" required 
                               autocomplete="new-password" minlength="8">
                        <button type="button" class="password-toggle" onclick="togglePassword('password')">
                            <svg id="eyeIcon1" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>
                            </svg>
                        </button>
                    </div>
                    <small class="text-muted" style="font-size:11px;">Minimo 8 caratteri</small>
                </div>
                
                <div class="form-group">
                    <label for="conferma_password">Conferma Password</label>
                    <div style="position:relative;">
                        <input type="password" id="conferma_password" name="conferma_password" required 
                               autocomplete="new-password" minlength="8">
                        <button type="button" class="password-toggle" onclick="togglePassword('conferma_password')">
                            <svg id="eyeIcon2" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>
                            </svg>
                        </button>
                    </div>
                </div>
                
                <button type="submit" class="btn-primary" style="width:100%;">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:8px;">
                        <path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="8.5" cy="7" r="4"/><line x1="20" y1="8" x2="20" y2="14"/><line x1="23" y1="11" x2="17" y2="11"/>
                    </svg>
                    Registrati
                </button>
            </form>
            
            <p class="text-center mt-4 text-muted" style="font-size:14px;">
                Hai già un account? <a href="login.jsp">Accedi</a>
            </p>
        </div>
    </div>
    
    <script>
    function togglePassword(inputId) {
        var input = document.getElementById(inputId);
        if (input.type === 'password') {
            input.type = 'text';
        } else {
            input.type = 'password';
        }
    }
    </script>
</body>
</html>