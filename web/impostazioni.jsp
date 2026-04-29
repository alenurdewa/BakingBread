<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, java.security.*, java.io.*, java.util.Base64" %>
<%
    response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    Integer idUtenteLoggato = (Integer) session.getAttribute("id_utente");
    if (idUtenteLoggato == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String dbUrl = "jdbc:mysql://localhost:3306/bakingbread?useSSL=false";
    String nomeVisualizzato = "", username = "", email = "", bio = "", avatarUrl = "";
    String msgSuccesso = "";
    String msgErrore = "";

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection(dbUrl, "root", "");
        PreparedStatement ps = conn.prepareStatement(
            "SELECT nome_visualizzato, username, email, bio, avatar_url FROM Utente WHERE id_utente = ?");
        ps.setInt(1, idUtenteLoggato);
        ResultSet rs = ps.executeQuery();
        if (rs.next()) {
            nomeVisualizzato = rs.getString("nome_visualizzato");
            username = rs.getString("username");
            email = rs.getString("email");
            bio = rs.getString("bio");
            avatarUrl = rs.getString("avatar_url");
        }
        rs.close();
        ps.close();
        conn.close();
    } catch (Exception e) {}

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String azione = request.getParameter("azione");

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection(dbUrl, "root", "");

            if ("aggiorna_profilo".equals(azione)) {
                String nuovoNome = request.getParameter("nome_visualizzato");
                String nuovoUsername = request.getParameter("username");
                String nuovaEmail = request.getParameter("email");
                String nuovaBio = request.getParameter("bio");
                String nuovoAvatar = request.getParameter("avatar_url");

                String avatarBase64 = request.getParameter("avatar_base64");
                if (avatarBase64 != null && !avatarBase64.isEmpty() && avatarBase64.startsWith("data:image")) {
                    try {
                        String base64Data = avatarBase64.substring(avatarBase64.indexOf(",") + 1);
                        byte[] imageBytes = Base64.getDecoder().decode(base64Data);
                        String fileName = "avatar_" + idUtenteLoggato + "_" + System.currentTimeMillis() + ".jpg";
                        String savePath = application.getRealPath("/media/avatars");
                        File dir = new File(savePath);
                        if (!dir.exists()) dir.mkdirs();
                        File imageFile = new File(dir, fileName);
                        FileOutputStream fos = new FileOutputStream(imageFile);
                        fos.write(imageBytes);
                        fos.close();
                        nuovoAvatar = "/media/avatars/" + fileName;
                    } catch (Exception ex) {
                        ex.printStackTrace();
                    }
                }

                if (nuovoNome == null || nuovoNome.trim().isEmpty()) {
                    msgErrore = "Il nome visualizzato è obbligatorio.";
                } else if (nuovoUsername == null || nuovoUsername.length() < 3 || nuovoUsername.length() > 50) {
                    msgErrore = "Il nome utente deve essere tra 3 e 50 caratteri.";
                } else if (!nuovoUsername.matches("^[a-zA-Z0-9_]+$")) {
                    msgErrore = "Il nome utente può contenere solo lettere, numeri e underscore.";
                } else if (nuovaEmail == null || !nuovaEmail.matches("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+$")) {
                    msgErrore = "Inserisci un indirizzo email valido.";
                } else {
                    PreparedStatement psCheck = conn.prepareStatement(
                        "SELECT id_utente FROM Utente WHERE (username = ? OR email = ?) AND id_utente != ?");
                    psCheck.setString(1, nuovoUsername.trim());
                    psCheck.setString(2, nuovaEmail.trim().toLowerCase());
                    psCheck.setInt(3, idUtenteLoggato);
                    ResultSet rsCheck = psCheck.executeQuery();

                    if (rsCheck.next()) {
                        msgErrore = "Nome utente o email già in uso.";
                    } else {
                        PreparedStatement psUpdate = conn.prepareStatement(
                            "UPDATE Utente SET nome_visualizzato = ?, username = ?, email = ?, bio = ?, avatar_url = ? WHERE id_utente = ?");
                        psUpdate.setString(1, nuovoNome.trim());
                        psUpdate.setString(2, nuovoUsername.trim());
                        psUpdate.setString(3, nuovaEmail.trim().toLowerCase());
                        psUpdate.setString(4, nuovaBio != null ? nuovaBio.trim() : "");
                        psUpdate.setString(5, nuovoAvatar != null ? nuovoAvatar.trim() : "");
                        psUpdate.setInt(6, idUtenteLoggato);
                        psUpdate.executeUpdate();
                        psUpdate.close();

                        session.setAttribute("nome_utente", nuovoNome.trim());
                        session.setAttribute("username", nuovoUsername.trim());

                        nomeVisualizzato = nuovoNome.trim();
                        username = nuovoUsername.trim();
                        email = nuovaEmail.trim().toLowerCase();
                        bio = nuovaBio != null ? nuovaBio.trim() : "";
                        avatarUrl = nuovoAvatar != null ? nuovoAvatar.trim() : "";

                        msgSuccesso = "Profilo aggiornato con successo!";
                    }
                    rsCheck.close();
                    psCheck.close();
                }
            } else if ("cambia_password".equals(azione)) {
                String vecchiaPwd = request.getParameter("vecchia_password");
                String nuovaPwd = request.getParameter("nuova_password");
                String confermaPwd = request.getParameter("conferma_password");

                if (vecchiaPwd == null || nuovaPwd == null || confermaPwd == null) {
                    msgErrore = "Tutti i campi password sono obbligatori.";
                } else if (nuovaPwd.length() < 8) {
                    msgErrore = "La nuova password deve essere di almeno 8 caratteri.";
                } else if (!nuovaPwd.equals(confermaPwd)) {
                    msgErrore = "Le nuove password non corrispondono.";
                } else {
                    PreparedStatement psPwd = conn.prepareStatement("SELECT password_hash FROM Utente WHERE id_utente = ?");
                    psPwd.setInt(1, idUtenteLoggato);
                    ResultSet rsPwd = psPwd.executeQuery();
                    if (rsPwd.next()) {
                        String currentHash = rsPwd.getString("password_hash");
                        String saltHex = currentHash.substring(0, 32);
                        String storedHashHex = currentHash.substring(32);

                        byte[] salt = new byte[16];
                        for (int i = 0; i < 16; i++) {
                            salt[i] = (byte) Integer.parseInt(saltHex.substring(i * 2, i * 2 + 2), 16);
                        }

                        MessageDigest md = MessageDigest.getInstance("SHA-256");
                        md.update(salt);
                        byte[] hash = md.digest(vecchiaPwd.getBytes("UTF-8"));
                        StringBuilder oldHashHex = new StringBuilder();
                        for (byte b : hash) {
                            String hex = Integer.toHexString(0xff & b);
                            if (hex.length() == 1) oldHashHex.append('0');
                            oldHashHex.append(hex);
                        }

                        if (oldHashHex.toString().equals(storedHashHex)) {
                            SecureRandom random = new SecureRandom();
                            byte[] newSalt = new byte[16];
                            random.nextBytes(newSalt);
                            StringBuilder newSaltHex = new StringBuilder();
                            for (byte b : newSalt) {
                                String hex = Integer.toHexString(0xff & b);
                                if (hex.length() == 1) newSaltHex.append('0');
                                newSaltHex.append(hex);
                            }

                            md.reset();
                            md.update(newSalt);
                            byte[] newHash = md.digest(nuovaPwd.getBytes("UTF-8"));
                            StringBuilder newHashHex = new StringBuilder();
                            for (byte b : newHash) {
                                String hex = Integer.toHexString(0xff & b);
                                if (hex.length() == 1) newHashHex.append('0');
                                newHashHex.append(hex);
                            }

                            String newPasswordHash = newSaltHex.toString() + newHashHex.toString();
                            PreparedStatement psUpdate = conn.prepareStatement("UPDATE Utente SET password_hash = ? WHERE id_utente = ?");
                            psUpdate.setString(1, newPasswordHash);
                            psUpdate.setInt(2, idUtenteLoggato);
                            psUpdate.executeUpdate();
                            psUpdate.close();

                            msgSuccesso = "Password aggiornata con successo!";
                        } else {
                            msgErrore = "La password attuale non è corretta.";
                        }
                    }
                    rsPwd.close();
                    psPwd.close();
                }
            }
            conn.close();
        } catch (Exception e) {
            msgErrore = "Errore: " + e.getMessage();
        }
    }
%>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Impostazioni - BakingBread</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/global.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/settings.css">
    <link rel="icon" href="${pageContext.request.contextPath}/media/favicon.svg">
</head>
<body>
    <jsp:include page="navbar.jsp" />

    <main class="container mt-4">
        <h2 class="mb-4">Impostazioni</h2>

        <% if (!msgErrore.isEmpty()) { %>
            <div class="alert alert-error">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:8px;flex-shrink:0;">
                    <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>
                </svg>
                <%= msgErrore %>
            </div>
        <% } %>
        <% if (!msgSuccesso.isEmpty()) { %>
            <div class="alert alert-success">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:8px;flex-shrink:0;">
                    <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/>
                </svg>
                <%= msgSuccesso %>
            </div>
        <% } %>

        <div class="row">
            <div class="card">
                <div class="card-header">
                    <h3 style="margin:0;">Profilo</h3>
                    <p class="text-muted" style="margin:5px 0 0 0;font-size:14px;">Aggiorna le tue informazioni personali</p>
                </div>
                <form method="POST" action="impostazioni.jsp" onsubmit="return prepareAvatar()">
                    <input type="hidden" name="azione" value="aggiorna_profilo">
                    <input type="hidden" id="avatar_base64" name="avatar_base64" value="">
                    <div class="form-group">
                        <label for="nome_visualizzato">Nome visualizzato</label>
                        <input type="text" id="nome_visualizzato" name="nome_visualizzato" required
                               value="<%= nomeVisualizzato %>">
                    </div>
                    <div class="form-group">
                        <label for="username">Nome utente</label>
                        <input type="text" id="username" name="username" required
                               pattern="[a-zA-Z0-9_]+" minlength="3" maxlength="50"
                               value="<%= username %>">
                        <small class="text-muted" style="font-size:11px;">Solo lettere, numeri e underscore (_)</small>
                    </div>
                    <div class="form-group">
                        <label for="email">Email</label>
                        <input type="email" id="email" name="email" required
                               value="<%= email %>">
                    </div>
                    <div class="form-group">
                        <label for="bio">Bio</label>
                        <textarea id="bio" name="bio" rows="4" maxlength="500"
                                  style="width:100%;padding:12px 16px;border:2px solid var(--border-color);border-radius:var(--border-radius-sm);background:#fafafa;font-size:15px;resize:vertical;"><%= bio != null ? bio : "" %></textarea>
                        <small class="text-muted" style="font-size:11px;">Massimo 500 caratteri</small>
                    </div>
                    <div class="form-group">
                        <label>Immagine Profilo</label>
                        <div style="display:flex;gap:15px;align-items:center;margin-bottom:10px;">
                            <div class="post-avatar avatar-sm" style="width:60px;height:60px;font-size:24px;flex-shrink:0;overflow:hidden;">
                                <% if (avatarUrl != null && !avatarUrl.isEmpty()) { %>
                                    <img id="avatarPreview" src="<%= avatarUrl.startsWith("http") ? avatarUrl : request.getContextPath() + avatarUrl %>" alt="Avatar" style="width:60px;height:60px;border-radius:50%;object-fit:cover;">
                                <% } else { %>
                                    <span id="avatarInitial"><%= nomeVisualizzato.substring(0,1).toUpperCase() %></span>
                                <% } %>
                            </div>
                            <div style="flex:1;">
                                <input type="file" id="avatar_file" name="avatar_file" accept="image/*" onchange="loadAvatar(event)" style="font-size:14px;padding:8px 0;">
                                <small class="text-muted" style="font-size:11px;display:block;margin-top:4px;">JPG, PNG o GIF. Max 2MB.</small>
                            </div>
                        </div>
                        <input type="hidden" id="avatar_url" name="avatar_url" value="<%= avatarUrl != null ? avatarUrl : "" %>">
                    </div>
                    <button type="submit" class="btn-primary">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:8px;">
                            <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/><polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/>
                        </svg>
                        Salva Modifiche
                    </button>
                </form>
            </div>

            <div class="card">
                <div class="card-header">
                    <h3 style="margin:0;">Cambia Password</h3>
                    <p class="text-muted" style="margin:5px 0 0 0;font-size:14px;">Aggiorna la tua password</p>
                </div>
                <form method="POST" action="impostazioni.jsp">
                    <input type="hidden" name="azione" value="cambia_password">
                    <div class="form-group">
                        <label for="vecchia_password">Password attuale</label>
                        <div style="position:relative;">
                            <input type="password" id="vecchia_password" name="vecchia_password" required>
                            <button type="button" class="password-toggle" onclick="togglePassword('vecchia_password')">
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>
                                </svg>
                            </button>
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="nuova_password">Nuova Password</label>
                        <div style="position:relative;">
                            <input type="password" id="nuova_password" name="nuova_password" required minlength="8">
                            <button type="button" class="password-toggle" onclick="togglePassword('nuova_password')">
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>
                                </svg>
                            </button>
                        </div>
                        <small class="text-muted" style="font-size:11px;">Minimo 8 caratteri</small>
                    </div>
                    <div class="form-group">
                        <label for="conferma_password">Conferma Nuova Password</label>
                        <div style="position:relative;">
                            <input type="password" id="conferma_password" name="conferma_password" required minlength="8">
                            <button type="button" class="password-toggle" onclick="togglePassword('conferma_password')">
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>
                                </svg>
                            </button>
                        </div>
                    </div>
                    <button type="submit" class="btn-primary">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:8px;">
                            <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>
                        </svg>
                        Cambia Password
                    </button>
                </form>
            </div>
        </div>
    </main>

    <script>
    function togglePassword(inputId) {
        var input = document.getElementById(inputId);
        if (input.type === 'password') {
            input.type = 'text';
        } else {
            input.type = 'password';
        }
    }

    function loadAvatar(event) {
        var file = event.target.files[0];
        if (!file) return;
        if (file.size > 2 * 1024 * 1024) {
            alert('Il file è troppo grande. Massimo 2MB.');
            event.target.value = '';
            return;
        }
        var reader = new FileReader();
        reader.onload = function(e) {
            var preview = document.getElementById('avatarPreview');
            var initial = document.getElementById('avatarInitial');
            if (preview) preview.remove();
            if (initial) initial.remove();
            var img = document.createElement('img');
            img.id = 'avatarPreview';
            img.src = e.target.result;
            img.style = 'width:60px;height:60px;border-radius:50%;object-fit:cover;';
            var container = document.querySelector('.post-avatar.avatar-sm');
            container.appendChild(img);
            container.style.fontSize = '0';
        };
        reader.readAsDataURL(file);
    }

    function prepareAvatar() {
        var fileInput = document.getElementById('avatar_file');
        var base64Input = document.getElementById('avatar_base64');
        if (fileInput.files.length > 0) {
            var reader = new FileReader();
            reader.onload = function(e) {
                base64Input.value = e.target.result;
                document.querySelector('form[onsubmit]').submit();
            };
            reader.readAsDataURL(fileInput.files[0]);
            return false;
        }
        return true;
    }
    </script>
    <script src="${pageContext.request.contextPath}/js/main.js"></script>
</body>
</html>
