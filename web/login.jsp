<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.security.*" %>
<%--
    ============================================================
    FILE: login.jsp
    SCOPO: Gestisce il login dell'utente.
    - Se l'utente è già loggato → reindirizza a home.jsp
    - Se il form è stato inviato (POST) → verifica credenziali
    - Se le credenziali sono corrette → crea la sessione
    - Altrimenti → mostra il form con messaggio di errore
    ============================================================
--%>
<%
    // Impedisce al browser di mettere in cache questa pagina
    // (importante perché contiene dati sensibili)
    response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    // Variabili per i messaggi da mostrare all'utente
    String errorMsg   = ""; // Messaggio di errore (es. "Password errata")
    String successMsg = ""; // Messaggio di successo (non usato qui ma pronto)

    // Legge dalla sessione se l'utente è già loggato
    Integer idUtenteLoggato = (Integer) session.getAttribute("id_utente");

    // Se l'utente è già loggato non ha senso stare qui: va alla home
    if (idUtenteLoggato != null) {
        response.sendRedirect("home.jsp");
        return; // Blocca l'esecuzione del resto della pagina
    }

    // --------------------------------------------------------
    // BLOCCO POST: eseguito solo quando l'utente clicca "Accedi"
    // --------------------------------------------------------
    if ("POST".equalsIgnoreCase(request.getMethod())) {

        // Legge i valori inseriti nel form
        String username = request.getParameter("username"); // Campo username
        String password = request.getParameter("password"); // Campo password

        // Validazione base: controlla che i campi non siano vuoti
        if (username == null || username.trim().isEmpty()) {
            errorMsg = "Inserisci il nome utente.";

        } else if (password == null || password.isEmpty()) {
            errorMsg = "Inserisci la password.";

        } else {
            // I dati sembrano validi: tentiamo il login nel database
            Connection conn = null; // Connessione al DB (inizialmente null)
            try {
                // Apre la connessione al database tramite la classe Db
                conn = com.bakingbread.util.Db.getConnection();

                // Query: cerca l'utente per username tra gli utenti attivi
                PreparedStatement ps = conn.prepareStatement(
                    "SELECT id_utente, username, nome_visualizzato, password_hash, avatar_url " +
                    "FROM Utente WHERE username = ? AND attivo = TRUE"
                );
                ps.setString(1, username.trim()); // Imposta il parametro ?
                ResultSet rs = ps.executeQuery(); // Esegue la query

                if (rs.next()) {
                    // Utente trovato: leggi i suoi dati dal risultato
                    int    idUtente         = rs.getInt("id_utente");
                    String nomeVisualizzato = rs.getString("nome_visualizzato");
                    String dbUsername       = rs.getString("username");
                    String avatarUrl        = rs.getString("avatar_url");
                    String storedHash       = rs.getString("password_hash"); // Hash salvato nel DB

                    // Verifica la password con l'algoritmo SHA-256 + salt
                    // Il formato nel DB è: SALT(32 chars hex) + HASH(64 chars hex)
                    boolean passwordValida = false;

                    try {
                        // Estrae i primi 32 caratteri = il salt in formato esadecimale
                        String saltHex  = storedHash.substring(0, 32);
                        // Estrae i restanti 64 caratteri = l'hash vero e proprio
                        String hashHex  = storedHash.substring(32);

                        // Converte il salt da stringa esadecimale a array di byte
                        byte[] saltBytes = new byte[16]; // 16 byte = 32 caratteri hex
                        for (int i = 0; i < 32; i += 2) {
                            // Ogni coppia di caratteri hex → un byte
                            int alto  = Character.digit(saltHex.charAt(i),     16);
                            int basso = Character.digit(saltHex.charAt(i + 1), 16);
                            saltBytes[i / 2] = (byte) ((alto << 4) + basso);
                        }

                        // Calcola SHA-256 della password inserita con lo stesso salt
                        MessageDigest md = MessageDigest.getInstance("SHA-256");
                        md.update(saltBytes);          // Aggiunge il salt
                        byte[] hashBytes = md.digest( // Calcola l'hash
                            password.getBytes("UTF-8")
                        );

                        // Converte l'hash calcolato in stringa esadecimale
                        StringBuilder hashCalcolato = new StringBuilder();
                        for (byte b : hashBytes) {
                            String hex = Integer.toHexString(0xff & b); // Converte byte in hex
                            if (hex.length() == 1) {
                                hashCalcolato.append('0'); // Aggiunge zero se necessario
                            }
                            hashCalcolato.append(hex);
                        }

                        // Confronta l'hash calcolato con quello nel database
                        passwordValida = hashHex.equals(hashCalcolato.toString());

                    } catch (Exception hashEx) {
                        // Se qualcosa va storto nell'hashing,
                        // per sicurezza la password è considerata non valida
                        passwordValida = false;
                    }

                    if (passwordValida) {
                        // Password corretta! Crea la sessione per l'utente.
                        // La sessione "ricorda" chi è loggato tra una pagina e l'altra.
                        session.setAttribute("id_utente",   idUtente);          // ID numerico
                        session.setAttribute("username",    dbUsername);        // Username
                        session.setAttribute("nome_utente", nomeVisualizzato);  // Nome da visualizzare
                        session.setAttribute("avatar_url",  avatarUrl);         // URL avatar

                        // Aggiorna l'orario dell'ultimo accesso nel database
                        PreparedStatement psUpdate = conn.prepareStatement(
                            "UPDATE Utente SET ultimo_accesso = NOW() WHERE id_utente = ?"
                        );
                        psUpdate.setInt(1, idUtente);
                        psUpdate.executeUpdate();
                        psUpdate.close();

                        rs.close();
                        ps.close();
                        conn.close();

                        // Login riuscito: manda l'utente alla home
                        response.sendRedirect("home.jsp");
                        return; // Interrompe il resto della pagina JSP
                    } else {
                        // Password sbagliata
                        errorMsg = "Nome utente o password errati.";
                    }

                } else {
                    // Nessun utente trovato con quell'username
                    errorMsg = "Nome utente o password errati.";
                }

                rs.close();
                ps.close();

            } catch (Exception e) {
                // Errore di connessione o query: mostra messaggio generico
                errorMsg = "Errore di connessione al server. Riprova.";
            } finally {
                // Chiude la connessione in ogni caso (evita perdite di risorse)
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
    <title>Accedi - BakingBread</title>
    <!-- Fogli di stile globali e specifici per le pagine di autenticazione -->
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/global.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/auth.css">
    <link rel="icon" href="${pageContext.request.contextPath}/media/favicon.svg">
</head>
<body>
    <!-- Contenitore centrato verticalmente e orizzontalmente -->
    <div class="auth-wrapper">
        <div class="auth-card animate-entrance">

            <!-- Intestazione con logo e titolo -->
            <div class="auth-header">
                <a href="home.jsp" style="justify-content:center; margin-bottom:20px; display:flex;">
                    <img src="${pageContext.request.contextPath}/media/favicon.svg"
                         alt="BakingBread Logo" style="width:40px; height:40px;">
                </a>
                <h2>Bentornato</h2>
                <p class="text-muted">Accedi per continuare su BakingBread</p>
            </div>

            <%-- Mostra il messaggio di errore solo se non è vuoto --%>
            <% if (!errorMsg.isEmpty()) { %>
                <div class="alert alert-error animate-entrance">
                    ⚠ <%= errorMsg %>
                </div>
            <% } %>

            <%-- Form di login: invia i dati in POST a questa stessa pagina --%>
            <form method="POST" action="login.jsp" accept-charset="UTF-8">

                <!-- Campo username -->
                <div class="form-group">
                    <label for="username">Nome utente</label>
                    <input type="text"
                           id="username"
                           name="username"
                           required
                           autocomplete="username"
                           maxlength="50"
                           value="<%= request.getParameter("username") != null ? request.getParameter("username") : "" %>">
                </div>

                <!-- Campo password con pulsante mostra/nascondi -->
                <div class="form-group">
                    <label for="password">Password</label>
                    <div style="position:relative;">
                        <input type="password"
                               id="password"
                               name="password"
                               required
                               autocomplete="current-password">
                        <!-- Pulsante per alternare tra testo visibile e nascosto -->
                        <button type="button"
                                class="password-toggle"
                                id="togglePassword"
                                aria-label="Mostra o nascondi la password">
                            👁
                        </button>
                    </div>
                </div>

                <!-- Pulsante di invio del form -->
                <button type="submit" class="btn-primary mt-3" style="width:100%;">
                    Accedi
                </button>
            </form>

            <!-- Link alla pagina di registrazione -->
            <p class="text-center mt-3 text-muted" style="font-size:14px;">
                Non hai un account? <a href="register.jsp">Registrati</a>
            </p>

        </div>
    </div>

    <!-- Collegamento al file JavaScript per il toggle della password -->
    <script src="${pageContext.request.contextPath}/js/login.js"></script>
</body>
</html>
