<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, java.security.*, java.util.*" %>
<%
    response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    String errorMsg = "";
    String successMsg = "";
    
    Integer idUtenteLoggato = (Integer) session.getAttribute("id_utente");
    if (idUtenteLoggato != null) {
        response.sendRedirect("home.jsp");
        return;
    }
    
    String dbUrl = "jdbc:mysql://localhost:3306/bakingbread?useSSL=false";
    String dbUser = "root";
    String dbPass = "";
    
    Cookie[] cookies = request.getCookies();
    String rememberToken = null;
    if (cookies != null) {
        for (Cookie c : cookies) {
            if ("remember_token".equals(c.getName())) {
                rememberToken = c.getValue();
                break;
            }
        }
    }
    
    if (rememberToken != null && "POST".equalsIgnoreCase(request.getMethod()) == false) {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
            PreparedStatement ps = conn.prepareStatement(
                "SELECT st.id_utente, u.username, u.nome_visualizzato FROM SessioneToken st " +
                "JOIN Utente u ON st.id_utente = u.id_utente " +
                "WHERE st.token = ? AND st.scade_il > NOW() AND u.attivo = TRUE");
            ps.setString(1, rememberToken);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                session.setAttribute("id_utente", rs.getInt("id_utente"));
                session.setAttribute("nome_utente", rs.getString("nome_visualizzato"));
                session.setAttribute("username", rs.getString("username"));
                
                ps = conn.prepareStatement("UPDATE Utente SET ultimo_accesso = NOW() WHERE id_utente = ?");
                ps.setInt(1, rs.getInt("id_utente"));
                ps.executeUpdate();
                
                rs.close();
                ps.close();
                conn.close();
                response.sendRedirect("home.jsp");
                return;
            }
            rs.close();
            ps.close();
            conn.close();
        } catch (Exception e) {
            // token non valido, continua con login normale
        }
    }
    
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String username = request.getParameter("username");
        String password = request.getParameter("password");
        String rememberMe = request.getParameter("ricordami");
        
        if (username == null || username.trim().isEmpty()) {
            errorMsg = "Inserisci il nome utente.";
        } else if (password == null || password.isEmpty()) {
            errorMsg = "Inserisci la password.";
        } else {
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                Connection conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
                
                PreparedStatement ps = conn.prepareStatement(
                    "SELECT id_utente, username, nome_visualizzato, password_hash FROM Utente " +
                    "WHERE username = ? AND attivo = TRUE");
                ps.setString(1, username.trim());
                ResultSet rs = ps.executeQuery();
                
                if (rs.next()) {
                    String storedHash = rs.getString("password_hash");
                    int idUtente = rs.getInt("id_utente");
                    String nomeVisualizzato = rs.getString("nome_visualizzato");
                    String dbUsername = rs.getString("username");
                    
                     boolean passwordValida = false;
                     try {
                         String storedSaltHex = storedHash.substring(0, 32);
                         String storedHashHex = storedHash.substring(32);
                         
                         // Decodifica hex salt in bytes
                         byte[] salt = new byte[16];
                         for (int i = 0; i < 32; i += 2) {
                             salt[i/2] = (byte) ((Character.digit(storedSaltHex.charAt(i), 16) << 4) 
                                                + Character.digit(storedSaltHex.charAt(i+1), 16));
                         }
                         
                         MessageDigest md = MessageDigest.getInstance("SHA-256");
                         md.update(salt);
                         byte[] hash = md.digest(password.getBytes("UTF-8"));
                         
                         StringBuilder hexString = new StringBuilder();
                         for (byte b : hash) {
                             String hex = Integer.toHexString(0xff & b);
                             if (hex.length() == 1) hexString.append('0');
                             hexString.append(hex);
                         }
                         
                         passwordValida = storedHashHex.equals(hexString.toString());
                     } catch (Exception hashEx) {
                         // se hashing fallisce, prova confronto diretto ( retrocompatibilita')
                         passwordValida = password.equals(storedHash);
                     }
                    
                    if (passwordValida) {
                        session.setAttribute("id_utente", idUtente);
                        session.setAttribute("nome_utente", nomeVisualizzato);
                        session.setAttribute("username", dbUsername);
                        session.setAttribute("login_time", new java.util.Date());
                        
                        ps = conn.prepareStatement("UPDATE Utente SET ultimo_accesso = NOW() WHERE id_utente = ?");
                        ps.setInt(1, idUtente);
                        ps.executeUpdate();
                        
                        if ("on".equals(rememberMe)) {
                            SecureRandom random = new SecureRandom();
                            byte[] tokenBytes = new byte[32];
                            random.nextBytes(tokenBytes);
                            StringBuilder tokenBuilder = new StringBuilder();
                            for (byte b : tokenBytes) {
                                String hex = Integer.toHexString(0xff & b);
                                if (hex.length() == 1) tokenBuilder.append('0');
                                tokenBuilder.append(hex);
                            }
                            String token = tokenBuilder.toString();
                            
                            Calendar cal = Calendar.getInstance();
                            cal.add(Calendar.DAY_OF_MONTH, 30);
                            java.util.Date scadenza = cal.getTime();
                            
                            ps = conn.prepareStatement(
                                "INSERT INTO SessioneToken (id_utente, token, user_agent, ip_address, scade_il) " +
                                "VALUES (?, ?, ?, ?, ?)");
                            ps.setInt(1, idUtente);
                            ps.setString(2, token);
                            ps.setString(3, request.getHeader("User-Agent"));
                            ps.setString(4, request.getRemoteAddr());
                            ps.setTimestamp(5, new java.sql.Timestamp(scadenza.getTime()));
                            ps.executeUpdate();
                            
                            Cookie rememberCookie = new Cookie("remember_token", token);
                            rememberCookie.setMaxAge(30 * 24 * 60 * 60);
                            rememberCookie.setPath("/");
                            rememberCookie.setHttpOnly(true);
                            rememberCookie.setSecure(request.isSecure());
                            response.addCookie(rememberCookie);
                            
                            ps.close();
                            conn.close();
                        }
                        
                        response.sendRedirect("home.jsp");
                        return;
                    } else {
                        errorMsg = "Nome utente o password errati.";
                    }
                } else {
                    errorMsg = "Nome utente o password errati.";
                }
                
                rs.close();
                ps.close();
                conn.close();
                
            } catch (Exception e) {
                errorMsg = "Errore di connessione. Riprova piu' tardi.";
                // in produzione: log e remove messaggio dettagliato
            }
        }
    }
%>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Accedi - BakingBread</title>
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
                <h2>Bentornato</h2>
                <p class="text-muted">Accedi per continuare su BakingBread</p>
            </div>
            
            <% if (!errorMsg.isEmpty()) { %>
                <div class="alert alert-error animate-entrance">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:8px;flex-shrink:0;">
                        <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>
                    </svg>
                    <%= errorMsg %>
                </div>
            <% } %>
            
            <% if (!successMsg.isEmpty()) { %>
                <div class="alert alert-success animate-entrance">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:8px;flex-shrink:0;">
                        <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/>
                    </svg>
                    <%= successMsg %>
                </div>
            <% } %>
            
            <form method="POST" action="login.jsp" accept-charset="UTF-8">
                <div class="form-group">
                    <label for="username">Nome utente</label>
                    <input type="text" id="username" name="username" required 
                           autocomplete="username" maxlength="50"
                           value="<%= request.getParameter("username") != null ? request.getParameter("username") : "" %>">
                </div>
                
                <div class="form-group">
                    <label for="password">Password</label>
                    <div style="position:relative;">
                        <input type="password" id="password" name="password" required 
                               autocomplete="current-password">
                        <button type="button" class="password-toggle" onclick="togglePassword()" aria-label="Mostra/nascondi password">
                            <svg id="eyeIcon" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>
                            </svg>
                        </button>
                    </div>
                </div>
                
                <div class="form-group" style="display:flex;align-items:center;justify-content:space-between;">
                    <label style="display:flex;align-items:center;gap:8px;margin:0;font-weight:500;cursor:pointer;">
                        <input type="checkbox" name="ricordami" id="ricordami" style="width:auto;">
                        <span>Ricordami</span>
                    </label>
                    <a href="recupero_password.jsp" style="font-size:14px;">Password dimenticata?</a>
                </div>
                
                <button type="submit" class="btn-primary mt-3">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:8px;">
                        <path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4"/><polyline points="10 17 15 12 10 7"/><line x1="15" y1="12" x2="3" y2="12"/>
                    </svg>
                    Accedi
                </button>
            </form>
            
            <p class="text-center mt-4 text-muted" style="font-size:14px;">
                Non hai un account? <a href="register.jsp">Registrati</a>
            </p>
        </div>
    </div>
    
    <script>
    function togglePassword() {
        var pwd = document.getElementById('password');
        var icon = document.getElementById('eyeIcon');
        if (pwd.type === 'password') {
            pwd.type = 'text';
            icon.innerHTML = '<path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.23a3 3 0 0 0-4.18-4.18"/><line x1="1" y1="1" x2="23" y2="23"/>';
        } else {
            pwd.type = 'password';
            icon.innerHTML = '<path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>';
        }
    }
    </script>
</body>
</html>