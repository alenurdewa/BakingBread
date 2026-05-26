<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.bakingbread.util.*" %>
<%--
    ============================================================
    FILE: navbar.jsp
    SCOPO: Barra di navigazione inclusa in tutte le pagine
           tramite <jsp:include page="navbar.jsp" />.
    - Legge dalla sessione i dati dell'utente loggato
    - Conta i messaggi non letti (per mostrare il badge)
    - Mostra avatar, nome utente e menu a tendina
    ============================================================
--%>
<%
    // Recupera il percorso base dell'applicazione web
    // Es. "" se deployata in root, "/BakingBread" altrimenti
    String ctx = request.getContextPath();

    // Legge dalla sessione le info dell'utente corrente
    Integer idUtenteLoggato  = (Integer) session.getAttribute("id_utente");
    String  nomeUtente       = (String)  session.getAttribute("nome_utente");
    String  usernameLoggato  = (String)  session.getAttribute("username");
    String  avatarLoggato    = (String)  session.getAttribute("avatar_url");

    // Contatore messaggi non letti (mostrato come badge sul link messaggi)
    int messaggiNonLetti = 0;

    // Carica dati aggiornati dal DB solo se l'utente è loggato
    if (idUtenteLoggato != null) {
        Connection conn = null;
        try {
            conn = Db.getConnection(); // Apre connessione al DB

            // Recupera i dati freschi dell'utente dal database
            PreparedStatement ps = conn.prepareStatement(
                "SELECT nome_visualizzato, username, avatar_url " +
                "FROM Utente WHERE id_utente = ?"
            );
            ps.setInt(1, idUtenteLoggato);
            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                // Aggiorna le variabili con dati freschi dal DB
                // (possono essere cambiati da impostazioni.jsp)
                if (avatarLoggato == null || avatarLoggato.isEmpty()) {
                    avatarLoggato = rs.getString("avatar_url");
                }
                if (nomeUtente == null || nomeUtente.isEmpty()) {
                    nomeUtente = rs.getString("nome_visualizzato");
                }
                if (usernameLoggato == null || usernameLoggato.isEmpty()) {
                    usernameLoggato = rs.getString("username");
                }
            }
            rs.close();
            ps.close();

            // Conta quanti messaggi l'utente non ha ancora letto
            PreparedStatement psMsg = conn.prepareStatement(
                "SELECT COUNT(*) FROM Messaggio WHERE destinatario_id = ? AND letto = FALSE"
            );
            psMsg.setInt(1, idUtenteLoggato);
            ResultSet rsMsg = psMsg.executeQuery();
            if (rsMsg.next()) {
                messaggiNonLetti = rsMsg.getInt(1); // Legge il conteggio
            }
            rsMsg.close();
            psMsg.close();

        } catch (Exception ignore) {
            // Se c'è un errore di DB, la navbar funziona comunque
            // (senza contatore messaggi aggiornato)
        } finally {
            if (conn != null) {
                try { conn.close(); } catch (Exception ignore) {}
            }
        }
    }

    // Risolve l'URL dell'avatar per usarlo in un tag <img>
    // (aggiunge il contextPath se è un percorso relativo)
    String avatarRisolto = UrlUtils.risolvi(ctx, avatarLoggato);

    // Calcola la lettera iniziale del nome da mostrare come avatar fallback
    // (se l'utente non ha ancora caricato una foto profilo)
    String iniziale = "U"; // Default: "U" per Utente
    if (nomeUtente != null && !nomeUtente.isEmpty()) {
        iniziale = nomeUtente.substring(0, 1).toUpperCase(); // Prima lettera maiuscola
    } else if (usernameLoggato != null && !usernameLoggato.isEmpty()) {
        iniziale = usernameLoggato.substring(0, 1).toUpperCase();
    }
%>

<%-- ============ HTML DELLA NAVBAR ============ --%>
<nav class="navbar">
    <div class="container navbar-inner">

        <!-- Logo e nome dell'applicazione (cliccabile) -->
        <a href="<%= ctx %>/home.jsp" class="navbar-brand">
            <span class="brand-mark">
                <img src="<%= ctx %>/media/favicon.svg" alt="Logo" width="28" height="28">
            </span>
            BakingBread
        </a>

        <!-- Barra di ricerca (collega a home con parametro di ricerca) -->
        <div class="navbar-search">
            <form class="navbar-search-form" action="<%= ctx %>/home.jsp" method="get">
                <input type="text"
                       name="cerca"
                       placeholder="Cerca ricette..."
                       value="<%= request.getParameter("cerca") != null ? request.getParameter("cerca") : "" %>">
                <button type="submit" class="btn-secondary btn-sm">Cerca</button>
            </form>
        </div>

        <!-- Menu di navigazione a destra -->
        <ul class="navbar-nav">

            <!-- Link Home -->
            <li><a href="<%= ctx %>/home.jsp">Home</a></li>

            <% if (idUtenteLoggato != null) { %>
                <!-- Utente loggato: mostra link con icone -->

                <!-- Link Nuova Ricetta -->
                <li>
                    <a href="<%= ctx %>/crea_ricetta.jsp" class="btn-primary btn-sm">
                        + Ricetta
                    </a>
                </li>

                <!-- Link Messaggi con badge messaggi non letti -->
                <li>
                    <a href="<%= ctx %>/messaggi.jsp" style="position:relative;">
                        ✉
                        <% if (messaggiNonLetti > 0) { %>
                            <!-- Badge rosso con numero di messaggi non letti -->
                            <span class="badge badge-primary"
                                  style="position:absolute; top:-8px; right:-10px; background:#dc2626; color:#fff;">
                                <%= messaggiNonLetti %>
                            </span>
                        <% } %>
                    </a>
                </li>

                <!-- Menu a tendina con avatar utente -->
                <li>
                    <div class="dropdown" id="navDropdown">

                        <!-- Pulsante avatar che apre il menu a tendina -->
                        <button onclick="toggleDropdown(event)"
                                class="dropdown-toggle"
                                aria-label="Menu utente"
                                style="background:none; border:none; cursor:pointer; padding:0;">
                            <% if (avatarRisolto != null && !avatarRisolto.isEmpty()) { %>
                                <!-- Mostra l'immagine profilo dell'utente -->
                                <img src="<%= avatarRisolto %>"
                                     alt="Avatar"
                                     class="nav-avatar-img"
                                     style="width:38px; height:38px; border-radius:50%; object-fit:cover;">
                            <% } else { %>
                                <!-- Mostra la lettera iniziale come fallback -->
                                <span class="nav-avatar-fallback"
                                      style="width:38px; height:38px; border-radius:50%; display:inline-flex; align-items:center; justify-content:center; font-weight:800;">
                                    <%= iniziale %>
                                </span>
                            <% } %>
                        </button>

                        <!-- Menu a tendina (si apre al click sull'avatar) -->
                        <div class="dropdown-menu">
                            <!-- Intestazione del menu con nome utente -->
                            <div style="padding:10px 14px 8px; border-bottom:1px solid rgba(148,163,184,0.16);">
                                <strong><%= nomeUtente != null ? nomeUtente : usernameLoggato %></strong><br>
                                <small class="text-muted">@<%= usernameLoggato %></small>
                            </div>

                            <!-- Voci del menu -->
                            <a href="<%= ctx %>/profile.jsp" class="dropdown-item">👤 Il mio profilo</a>
                            <a href="<%= ctx %>/collezioni.jsp" class="dropdown-item">📚 Collezioni</a>
                            <a href="<%= ctx %>/network.jsp" class="dropdown-item">🌐 Network</a>
                            <a href="<%= ctx %>/impostazioni.jsp" class="dropdown-item">⚙ Impostazioni</a>
                            <a href="<%= ctx %>/logout.jsp" class="dropdown-item dropdown-item-danger">🚪 Esci</a>
                        </div>
                    </div>
                </li>

            <% } else { %>
                <!-- Utente non loggato: mostra link Accedi e Registrati -->
                <li><a href="<%= ctx %>/login.jsp">Accedi</a></li>
                <li>
                    <a href="<%= ctx %>/register.jsp" class="btn-primary btn-sm">Registrati</a>
                </li>
            <% } %>
        </ul>

    </div>
</nav>
<!-- File JS per aprire/chiudere il menu a tendina -->
<script src="<%= ctx %>/js/main.js"></script>
