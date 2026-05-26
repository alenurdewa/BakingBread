<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="javax.servlet.http.Part" %>
<%@ page import="com.bakingbread.util.*" %>
<%--
    ============================================================
    FILE: impostazioni.jsp
    SCOPO: Permette all'utente di modificare il proprio profilo.
    - Nome visualizzato, email, bio
    - Upload avatar tramite file oppure URL diretto
    - Cambio password (opzionale)
    GET  → mostra il form con i dati attuali
    POST → salva le modifiche nel database
    ============================================================
--%>
<%
    response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    String ctx = request.getContextPath();

    // Verifica che l'utente sia loggato
    Integer idUtenteLoggato = (Integer) session.getAttribute("id_utente");
    if (idUtenteLoggato == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String errorMsg   = "";
    String successMsg = "";

    // Variabili che contengono i dati attuali del profilo
    // (riempite dal DB in GET, o dai valori inviati in POST)
    String nomeVisualizzato = "";
    String email            = "";
    String bio              = "";
    String avatarUrl        = "";

    // --------------------------------------------------------
    // GESTIONE POST: aggiorna i dati del profilo
    // --------------------------------------------------------
    if ("POST".equalsIgnoreCase(request.getMethod())) {

        // Legge i campi inviati dal form
        String nuovoNome  = request.getParameter("nome_visualizzato");
        String nuovaEmail = request.getParameter("email");
        String nuovaBio   = request.getParameter("bio");
        String avatarDaUrl = request.getParameter("avatar_url"); // URL inserito manualmente

        // Validazione base
        if (nuovoNome == null || nuovoNome.trim().isEmpty()) {
            errorMsg = "Il nome visualizzato non può essere vuoto.";

        } else if (nuovaEmail == null || nuovaEmail.trim().isEmpty()) {
            errorMsg = "L'email non può essere vuota.";

        } else {
            Connection conn = null;
            try {
                conn = Db.getConnection();

                // ---- Gestione avatar ----
                // Prima tenta l'upload del file; se non c'è file usa l'URL
                String nuovoAvatarUrl = null;

                try {
                    // Prova a leggere il file caricato (multipart)
                    Part avatarPart = request.getPart("avatar_file");
                    String avatarSalvato = FileStore.salva(
                        avatarPart,              // Il file ricevuto
                        application,             // ServletContext per il percorso
                        "avatars",               // Sottocartella di destinazione
                        "avatar_" + idUtenteLoggato // Prefisso del nome file
                    );
                    if (avatarSalvato != null) {
                        nuovoAvatarUrl = avatarSalvato; // Usa il file appena caricato
                    }
                } catch (Exception uploadEx) {
                    // Se l'upload fallisce (es. file non presente), non è un errore grave
                }

                // Se non c'è stato upload, controlla se è stato inserito un URL
                if (nuovoAvatarUrl == null) {
                    if (avatarDaUrl != null && !avatarDaUrl.trim().isEmpty()) {
                        nuovoAvatarUrl = avatarDaUrl.trim(); // Usa l'URL inserito
                    }
                    // Altrimenti lascia l'avatar com'è (null = non cambiare)
                }

                // ---- Controlla se la nuova email è già usata da un altro utente ----
                PreparedStatement psCheck = conn.prepareStatement(
                    "SELECT id_utente FROM Utente WHERE email = ? AND id_utente != ?"
                );
                psCheck.setString(1, nuovaEmail.trim().toLowerCase());
                psCheck.setInt(2, idUtenteLoggato);
                ResultSet rsCheck = psCheck.executeQuery();

                if (rsCheck.next()) {
                    errorMsg = "Questa email è già usata da un altro account.";
                    rsCheck.close();
                    psCheck.close();
                } else {
                    rsCheck.close();
                    psCheck.close();

                    // ---- Aggiorna i dati nel database ----
                    if (nuovoAvatarUrl != null) {
                        // Aggiorna tutto incluso l'avatar
                        PreparedStatement psUpdate = conn.prepareStatement(
                            "UPDATE Utente SET nome_visualizzato = ?, email = ?, bio = ?, " +
                            "avatar_url = ? WHERE id_utente = ?"
                        );
                        psUpdate.setString(1, nuovoNome.trim());
                        psUpdate.setString(2, nuovaEmail.trim().toLowerCase());
                        psUpdate.setString(3, nuovaBio != null ? nuovaBio.trim() : "");
                        psUpdate.setString(4, nuovoAvatarUrl);
                        psUpdate.setInt(5, idUtenteLoggato);
                        psUpdate.executeUpdate();
                        psUpdate.close();

                        // Aggiorna anche la sessione con il nuovo avatar
                        session.setAttribute("avatar_url", nuovoAvatarUrl);

                    } else {
                        // Aggiorna tutto tranne l'avatar (lo mantiene come prima)
                        PreparedStatement psUpdate = conn.prepareStatement(
                            "UPDATE Utente SET nome_visualizzato = ?, email = ?, bio = ? " +
                            "WHERE id_utente = ?"
                        );
                        psUpdate.setString(1, nuovoNome.trim());
                        psUpdate.setString(2, nuovaEmail.trim().toLowerCase());
                        psUpdate.setString(3, nuovaBio != null ? nuovaBio.trim() : "");
                        psUpdate.setInt(4, idUtenteLoggato);
                        psUpdate.executeUpdate();
                        psUpdate.close();
                    }

                    // ---- Cambio password (opzionale) ----
                    String nuovaPassword    = request.getParameter("nuova_password");
                    String confermaPassword = request.getParameter("conferma_password");

                    // Cambia la password solo se l'utente ha compilato i campi
                    if (nuovaPassword != null && !nuovaPassword.isEmpty()) {
                        if (nuovaPassword.length() < 8) {
                            errorMsg = "La nuova password deve avere almeno 8 caratteri.";
                        } else if (!nuovaPassword.equals(confermaPassword)) {
                            errorMsg = "Le due password non corrispondono.";
                        } else {
                            // Genera nuovo salt e calcola il nuovo hash
                            java.security.SecureRandom rnd = new java.security.SecureRandom();
                            byte[] salt = new byte[16];
                            rnd.nextBytes(salt);

                            StringBuilder saltHex = new StringBuilder();
                            for (int s = 0; s < salt.length; s++) {
                                String hex = Integer.toHexString(0xff & salt[s]);
                                if (hex.length() == 1) { saltHex.append('0'); }
                                saltHex.append(hex);
                            }

                            java.security.MessageDigest md = java.security.MessageDigest.getInstance("SHA-256");
                            md.update(salt);
                            byte[] hashBytes = md.digest(nuovaPassword.getBytes("UTF-8"));

                            StringBuilder hashHex = new StringBuilder();
                            for (int h = 0; h < hashBytes.length; h++) {
                                String hex = Integer.toHexString(0xff & hashBytes[h]);
                                if (hex.length() == 1) { hashHex.append('0'); }
                                hashHex.append(hex);
                            }

                            String nuovoHash = saltHex.toString() + hashHex.toString();

                            PreparedStatement psPwd = conn.prepareStatement(
                                "UPDATE Utente SET password_hash = ? WHERE id_utente = ?"
                            );
                            psPwd.setString(1, nuovoHash);
                            psPwd.setInt(2, idUtenteLoggato);
                            psPwd.executeUpdate();
                            psPwd.close();
                        }
                    }

                    // Aggiorna la sessione con il nuovo nome
                    session.setAttribute("nome_utente", nuovoNome.trim());

                    if (errorMsg.isEmpty()) {
                        successMsg = "Profilo aggiornato con successo!";
                    }
                }

            } catch (Exception e) {
                errorMsg = "Errore durante il salvataggio. Riprova.";
            } finally {
                if (conn != null) {
                    try { conn.close(); } catch (Exception ignore) {}
                }
            }
        }
    }

    // --------------------------------------------------------
    // CARICAMENTO DATI ATTUALI (GET o dopo POST con errore)
    // --------------------------------------------------------
    Connection connLoad = null;
    try {
        connLoad = Db.getConnection();
        PreparedStatement ps = connLoad.prepareStatement(
            "SELECT nome_visualizzato, email, bio, avatar_url FROM Utente WHERE id_utente = ?"
        );
        ps.setInt(1, idUtenteLoggato);
        ResultSet rs = ps.executeQuery();
        if (rs.next()) {
            nomeVisualizzato = rs.getString("nome_visualizzato");
            email            = rs.getString("email");
            bio              = rs.getString("bio");
            avatarUrl        = UrlUtils.risolvi(ctx, rs.getString("avatar_url"));
        }
        rs.close();
        ps.close();
    } catch (Exception e) {
        // Dati non caricati: le variabili rimangono vuote
    } finally {
        if (connLoad != null) {
            try { connLoad.close(); } catch (Exception ignore) {}
        }
    }

    if (bio == null) { bio = ""; }

    // Calcola la lettera iniziale per il fallback avatar
    String iniziale = (nomeVisualizzato != null && !nomeVisualizzato.isEmpty())
                      ? nomeVisualizzato.substring(0, 1).toUpperCase() : "U";
%>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Impostazioni - BakingBread</title>
    <link rel="stylesheet" href="<%= ctx %>/css/global.css">
    <link rel="stylesheet" href="<%= ctx %>/css/settings.css">
    <link rel="icon" href="<%= ctx %>/media/favicon.svg">
</head>
<body>
    <jsp:include page="navbar.jsp" />

    <main class="settings-page">
        <div class="container">

            <div class="settings-card">
                <div class="section-head" style="margin-bottom:24px;">
                    <div>
                        <p class="eyebrow">Account</p>
                        <h1 style="margin:0;">Impostazioni</h1>
                    </div>
                </div>

                <%-- Messaggi di esito operazione --%>
                <% if (!errorMsg.isEmpty()) { %>
                    <div class="alert alert-error" style="margin-bottom:20px;">⚠ <%= errorMsg %></div>
                <% } %>
                <% if (!successMsg.isEmpty()) { %>
                    <div class="alert alert-success" style="margin-bottom:20px;">✓ <%= successMsg %></div>
                <% } %>

                <%--
                    Il form usa enctype="multipart/form-data" perché permette
                    l'upload di file (avatar). Senza questo attributo il file
                    non verrebbe trasmesso al server.
                --%>
                <form method="POST"
                      action="impostazioni.jsp"
                      enctype="multipart/form-data"
                      class="settings-form">

                    <%-- Sezione avatar --%>
                    <div class="settings-avatar-row">
                        <!-- Anteprima avatar corrente -->
                        <div>
                            <% if (avatarUrl != null && !avatarUrl.isEmpty()) { %>
                                <img src="<%= avatarUrl %>"
                                     alt="Avatar attuale"
                                     class="settings-avatar-preview"
                                     id="avatarPreview">
                            <% } else { %>
                                <span class="settings-avatar-preview settings-avatar-fallback"
                                      id="avatarPreview">
                                    <%= iniziale %>
                                </span>
                            <% } %>
                        </div>

                        <div class="settings-avatar-copy">
                            <p style="margin:0; font-weight:700;">Foto profilo</p>

                            <!-- Upload file immagine -->
                            <div class="form-group">
                                <label for="avatar_file">Carica un'immagine</label>
                                <input type="file"
                                       id="avatar_file"
                                       name="avatar_file"
                                       accept="image/*"
                                       onchange="anteprimaAvatar(this)">
                            </div>

                            <!-- Oppure inserisci un URL -->
                            <div class="form-group">
                                <label for="avatar_url">Oppure inserisci un URL</label>
                                <input type="url"
                                       id="avatar_url"
                                       name="avatar_url"
                                       class="url-input"
                                       placeholder="https://esempio.com/foto.jpg"
                                       value="<%= avatarUrl != null ? avatarUrl : "" %>">
                            </div>
                        </div>
                    </div>

                    <%-- Dati anagrafici --%>
                    <div class="form-group">
                        <label for="nome_visualizzato">Nome visualizzato</label>
                        <input type="text"
                               id="nome_visualizzato"
                               name="nome_visualizzato"
                               required
                               maxlength="100"
                               value="<%= nomeVisualizzato %>">
                    </div>

                    <div class="form-group">
                        <label for="email">Email</label>
                        <input type="email"
                               id="email"
                               name="email"
                               required
                               maxlength="100"
                               value="<%= email %>">
                    </div>

                    <div class="form-group">
                        <label for="bio">Bio</label>
                        <textarea id="bio"
                                  name="bio"
                                  rows="4"
                                  maxlength="500"
                                  placeholder="Racconta qualcosa di te..."><%= bio %></textarea>
                    </div>

                    <%-- Sezione cambio password --%>
                    <div style="padding-top:20px; border-top:1px solid rgba(148,163,184,0.16);">
                        <h3 style="margin:0 0 16px;">Cambia password</h3>
                        <p class="text-muted" style="margin-bottom:16px;">
                            Lascia vuoti questi campi se non vuoi cambiare la password.
                        </p>

                        <div class="form-grid-2">
                            <div class="form-group">
                                <label for="nuova_password">Nuova password</label>
                                <input type="password"
                                       id="nuova_password"
                                       name="nuova_password"
                                       minlength="8"
                                       autocomplete="new-password">
                            </div>
                            <div class="form-group">
                                <label for="conferma_password">Conferma password</label>
                                <input type="password"
                                       id="conferma_password"
                                       name="conferma_password"
                                       minlength="8"
                                       autocomplete="new-password">
                            </div>
                        </div>
                    </div>

                    <%-- Pulsanti azione --%>
                    <div class="form-actions">
                        <a href="profile.jsp" class="btn-secondary">Annulla</a>
                        <button type="submit" class="btn-primary">Salva modifiche</button>
                    </div>

                </form>
            </div>
        </div>
    </main>

    <script src="<%= ctx %>/js/profile.js"></script>
</body>
</html>
