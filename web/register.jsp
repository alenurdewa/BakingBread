<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.security.*" %>
<%--
    ============================================================
    FILE: register.jsp
    SCOPO: Gestisce la registrazione di un nuovo utente.
    - Se l'utente è già loggato → reindirizza a home.jsp
    - Se il form è inviato (POST) → valida i dati e registra
    - Se la registrazione va a buon fine → crea la sessione
    - Se ci sono errori → mostra il form con i messaggi
    ============================================================
--%>
<%
    // Impedisce la cache del browser su questa pagina sensibile
    response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    String errorMsg   = ""; // Errore da mostrare all'utente
    String successMsg = ""; // Messaggio di successo (non usato qui)

    // Se l'utente è già loggato, non deve poter registrarsi di nuovo
    Integer idUtenteLoggato = (Integer) session.getAttribute("id_utente");
    if (idUtenteLoggato != null) {
        response.sendRedirect("home.jsp");
        return;
    }

    // --------------------------------------------------------
    // BLOCCO POST: eseguito quando l'utente clicca "Registrati"
    // --------------------------------------------------------
    if ("POST".equalsIgnoreCase(request.getMethod())) {

        // Legge i dati inseriti nel form di registrazione
        String username         = request.getParameter("username");
        String email            = request.getParameter("email");
        String password         = request.getParameter("password");
        String confermaPassword = request.getParameter("conferma_password");

        // ---- VALIDAZIONE DEI DATI ----
        // Controlla ogni campo in sequenza con if-else

        if (username == null || username.trim().isEmpty()) {
            errorMsg = "Inserisci il nome utente.";

        } else if (username.trim().length() < 3 || username.trim().length() > 50) {
            errorMsg = "Il nome utente deve avere tra 3 e 50 caratteri.";

        } else if (!username.trim().matches("^[a-zA-Z0-9_]+$")) {
            // Solo lettere, numeri e underscore: niente spazi o simboli
            errorMsg = "Il nome utente può contenere solo lettere, numeri e _.";

        } else if (email == null || email.trim().isEmpty()) {
            errorMsg = "Inserisci l'indirizzo email.";

        } else if (!email.trim().matches("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+$")) {
            // Formato email basico: qualcosa@dominio.ext
            errorMsg = "Inserisci un indirizzo email valido.";

        } else if (password == null || password.length() < 8) {
            errorMsg = "La password deve avere almeno 8 caratteri.";

        } else if (!password.equals(confermaPassword)) {
            errorMsg = "Le due password non corrispondono.";

        } else {
            // Tutti i campi sono validi: tentiamo la registrazione

            Connection conn = null;
            try {
                conn = com.bakingbread.util.Db.getConnection();

                // Controlla se username o email sono già in uso nel DB
                PreparedStatement psCheck = conn.prepareStatement(
                    "SELECT id_utente FROM Utente WHERE username = ? OR email = ?"
                );
                psCheck.setString(1, username.trim());
                psCheck.setString(2, email.trim().toLowerCase());
                ResultSet rsCheck = psCheck.executeQuery();

                if (rsCheck.next()) {
                    // Trovato un utente con stesso username o email
                    errorMsg = "Nome utente o email già registrati.";
                    rsCheck.close();
                    psCheck.close();

                } else {
                    rsCheck.close();
                    psCheck.close();

                    // ---- CALCOLO HASH DELLA PASSWORD ----
                    // Non salviamo mai la password in chiaro!
                    // Usiamo SHA-256 con un "sale" casuale per sicurezza.

                    // Genera 16 byte casuali come "sale" (salt)
                    SecureRandom random = new SecureRandom();
                    byte[] salt = new byte[16];
                    random.nextBytes(salt); // Riempie l'array con byte casuali

                    // Converte il salt in stringa esadecimale (32 caratteri)
                    StringBuilder saltHex = new StringBuilder();
                    for (int i = 0; i < salt.length; i++) {
                        String hex = Integer.toHexString(0xff & salt[i]);
                        if (hex.length() == 1) {
                            saltHex.append('0'); // Aggiunge zero iniziale se serve
                        }
                        saltHex.append(hex);
                    }

                    // Calcola SHA-256(salt + password)
                    MessageDigest md = MessageDigest.getInstance("SHA-256");
                    md.update(salt); // Prima aggiunge il salt
                    byte[] hashBytes = md.digest(password.getBytes("UTF-8")); // Poi la password

                    // Converte l'hash in stringa esadecimale (64 caratteri)
                    StringBuilder hashHex = new StringBuilder();
                    for (int i = 0; i < hashBytes.length; i++) {
                        String hex = Integer.toHexString(0xff & hashBytes[i]);
                        if (hex.length() == 1) {
                            hashHex.append('0');
                        }
                        hashHex.append(hex);
                    }

                    // Combina: salt(32 chars) + hash(64 chars) = 96 chars totali
                    String passwordHash = saltHex.toString() + hashHex.toString();

                    // ---- INSERIMENTO NEL DATABASE ----
                    PreparedStatement psInsert = conn.prepareStatement(
                        "INSERT INTO Utente (username, email, password_hash, nome_visualizzato, attivo) " +
                        "VALUES (?, ?, ?, ?, TRUE)",
                        PreparedStatement.RETURN_GENERATED_KEYS // Recupera l'ID generato
                    );
                    psInsert.setString(1, username.trim());
                    psInsert.setString(2, email.trim().toLowerCase()); // Email in minuscolo
                    psInsert.setString(3, passwordHash);
                    psInsert.setString(4, username.trim()); // Nome = username di default
                    psInsert.executeUpdate();

                    // Recupera l'ID dell'utente appena creato
                    ResultSet rsKeys = psInsert.getGeneratedKeys();
                    int nuovoId = 0;
                    if (rsKeys.next()) {
                        nuovoId = rsKeys.getInt(1); // Legge l'ID auto-generato
                    }
                    rsKeys.close();
                    psInsert.close();
                    conn.close();

                    // ---- CREAZIONE SESSIONE ----
                    // Registrazione riuscita: loggaamo subito l'utente
                    session.setAttribute("id_utente",   nuovoId);
                    session.setAttribute("username",    username.trim());
                    session.setAttribute("nome_utente", username.trim());
                    session.setAttribute("avatar_url",  null);

                    // Vai alla home
                    response.sendRedirect("home.jsp");
                    return;
                }

            } catch (Exception e) {
                errorMsg = "Errore durante la registrazione. Riprova.";
            } finally {
                if (conn != null) {
                    try { conn.close(); } catch (Exception ignore) {}
                }
            }
        }
    } // fine blocco POST
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
                <a href="home.jsp" style="justify-content:center; margin-bottom:20px; display:flex;">
                    <img src="${pageContext.request.contextPath}/media/favicon.svg"
                         alt="BakingBread Logo" style="width:40px; height:40px;">
                </a>
                <h2>Crea il tuo account</h2>
                <p class="text-muted">Unisciti alla community di BakingBread</p>
            </div>

            <%-- Messaggio di errore (visibile solo se errorMsg non è vuoto) --%>
            <% if (!errorMsg.isEmpty()) { %>
                <div class="alert alert-error animate-entrance">
                    ⚠ <%= errorMsg %>
                </div>
            <% } %>

            <%-- Form di registrazione: POST a questa stessa pagina --%>
            <form method="POST" action="register.jsp" accept-charset="UTF-8" id="registerForm">

                <!-- Campo username -->
                <div class="form-group">
                    <label for="username">Nome utente</label>
                    <input type="text"
                           id="username"
                           name="username"
                           required
                           minlength="3"
                           maxlength="50"
                           placeholder="es. mario_rossi"
                           value="<%= request.getParameter("username") != null ? request.getParameter("username") : "" %>">
                </div>

                <!-- Campo email -->
                <div class="form-group">
                    <label for="email">Indirizzo email</label>
                    <input type="email"
                           id="email"
                           name="email"
                           required
                           maxlength="100"
                           placeholder="es. mario@email.it"
                           value="<%= request.getParameter("email") != null ? request.getParameter("email") : "" %>">
                </div>

                <!-- Campo password con toggle visibilità -->
                <div class="form-group">
                    <label for="password">Password</label>
                    <div style="position:relative;">
                        <input type="password"
                               id="password"
                               name="password"
                               required
                               minlength="8"
                               autocomplete="new-password">
                        <button type="button"
                                class="password-toggle"
                                id="togglePassword"
                                aria-label="Mostra o nascondi la password">
                            👁
                        </button>
                    </div>
                </div>

                <!-- Campo conferma password -->
                <div class="form-group">
                    <label for="conferma_password">Conferma password</label>
                    <input type="password"
                           id="conferma_password"
                           name="conferma_password"
                           required
                           minlength="8"
                           autocomplete="new-password">
                </div>

                <!-- Pulsante di invio -->
                <button type="submit" class="btn-primary mt-3" style="width:100%;">
                    Registrati
                </button>
            </form>

            <p class="text-center mt-3 text-muted" style="font-size:14px;">
                Hai già un account? <a href="login.jsp">Accedi</a>
            </p>

        </div>
    </div>

    <script src="${pageContext.request.contextPath}/js/register.js"></script>
</body>
</html>
