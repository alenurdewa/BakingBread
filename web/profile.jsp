<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.bakingbread.util.*" %>
<%@ page import="com.bakingbread.model.*" %>
<%--
    ============================================================
    FILE: profile.jsp
    SCOPO: Mostra il profilo di un utente (proprio o altrui).
    - Legge ?id=N per decidere quale profilo mostrare.
      Se manca l'ID mostra il profilo dell'utente loggato.
    - Se POST → gestisce il follow/unfollow
    - Carica: dati utente, statistiche, ricette pubblicate
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

    // Legge l'ID del profilo da visualizzare dal parametro URL (?id=N)
    int idProfiloTarget = idUtenteLoggato; // Default: mostra il proprio profilo
    String idParam = request.getParameter("id");
    if (idParam != null && !idParam.trim().isEmpty()) {
        try {
            idProfiloTarget = Integer.parseInt(idParam.trim());
        } catch (NumberFormatException e) {
            idProfiloTarget = idUtenteLoggato; // Parametro non valido: usa l'utente loggato
        }
    }

    // Flag: true se stiamo guardando il profilo di qualcun altro
    boolean isAltruiProfilo = (idProfiloTarget != idUtenteLoggato);

    // --------------------------------------------------------
    // GESTIONE POST: follow o unfollow
    // --------------------------------------------------------
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String azione = request.getParameter("azione"); // "segui" o "smetti"

        if (azione != null && isAltruiProfilo) {
            Connection connAzione = null;
            try {
                connAzione = Db.getConnection();

                if ("segui".equals(azione)) {
                    // Segui l'utente: inserisce nella tabella Seguito
                    PreparedStatement ps = connAzione.prepareStatement(
                        "INSERT IGNORE INTO Seguito (follower_id, followed_id) VALUES (?, ?)"
                    );
                    ps.setInt(1, idUtenteLoggato);  // Chi segue
                    ps.setInt(2, idProfiloTarget);  // Chi viene seguito
                    ps.executeUpdate();
                    ps.close();

                } else if ("smetti".equals(azione)) {
                    // Smetti di seguire: rimuove dalla tabella Seguito
                    PreparedStatement ps = connAzione.prepareStatement(
                        "DELETE FROM Seguito WHERE follower_id = ? AND followed_id = ?"
                    );
                    ps.setInt(1, idUtenteLoggato);
                    ps.setInt(2, idProfiloTarget);
                    ps.executeUpdate();
                    ps.close();
                }

            } catch (Exception e) {
                // Errore ignorato: l'azione sarà rispecchiata al prossimo caricamento
            } finally {
                if (connAzione != null) {
                    try { connAzione.close(); } catch (Exception ignore) {}
                }
            }
        }
        // Dopo il POST, reindirizza per evitare ri-invio del form
        response.sendRedirect("profile.jsp?id=" + idProfiloTarget);
        return;
    }

    // --------------------------------------------------------
    // CARICAMENTO DATI PROFILO
    // --------------------------------------------------------

    // Variabili per i dati dell'utente di cui visualizziamo il profilo
    String  nomeUtente      = "";
    String  usernameTarget  = "";
    String  bio             = "";
    String  avatarUrl       = "";
    boolean seguoGiaTarget  = false; // True se l'utente loggato segue il target
    int     numFollower     = 0;
    int     numSeguiti      = 0;
    int     numRicette      = 0;

    // Array con le ricette pubblicate dall'utente target
    RicettaCard[] ricette = new RicettaCard[0];

    Connection conn = null;
    try {
        conn = Db.getConnection();

        // ---- Carica i dati anagrafici dell'utente ----
        PreparedStatement psUtente = conn.prepareStatement(
            "SELECT nome_visualizzato, username, bio, avatar_url FROM Utente WHERE id_utente = ?"
        );
        psUtente.setInt(1, idProfiloTarget);
        ResultSet rsUtente = psUtente.executeQuery();

        if (rsUtente.next()) {
            nomeUtente     = rsUtente.getString("nome_visualizzato");
            usernameTarget = rsUtente.getString("username");
            bio            = rsUtente.getString("bio");
            avatarUrl      = UrlUtils.risolvi(ctx, rsUtente.getString("avatar_url"));
        }
        rsUtente.close();
        psUtente.close();

        // ---- Conta i follower ----
        PreparedStatement psFollower = conn.prepareStatement(
            "SELECT COUNT(*) FROM Seguito WHERE followed_id = ?"
        );
        psFollower.setInt(1, idProfiloTarget);
        ResultSet rsFollower = psFollower.executeQuery();
        if (rsFollower.next()) {
            numFollower = rsFollower.getInt(1);
        }
        rsFollower.close();
        psFollower.close();

        // ---- Conta i seguiti ----
        PreparedStatement psSeguiti = conn.prepareStatement(
            "SELECT COUNT(*) FROM Seguito WHERE follower_id = ?"
        );
        psSeguiti.setInt(1, idProfiloTarget);
        ResultSet rsSeguiti = psSeguiti.executeQuery();
        if (rsSeguiti.next()) {
            numSeguiti = rsSeguiti.getInt(1);
        }
        rsSeguiti.close();
        psSeguiti.close();

        // ---- Controlla se l'utente loggato segue già il target ----
        if (isAltruiProfilo) {
            PreparedStatement psSeguo = conn.prepareStatement(
                "SELECT 1 FROM Seguito WHERE follower_id = ? AND followed_id = ?"
            );
            psSeguo.setInt(1, idUtenteLoggato);
            psSeguo.setInt(2, idProfiloTarget);
            ResultSet rsSeguo = psSeguo.executeQuery();
            seguoGiaTarget = rsSeguo.next(); // true se esiste una riga
            rsSeguo.close();
            psSeguo.close();
        }

        // ---- Conta le ricette ----
        PreparedStatement psCountR = conn.prepareStatement(
            "SELECT COUNT(*) FROM Ricetta WHERE id_utente = ? AND pubblicata = TRUE"
        );
        psCountR.setInt(1, idProfiloTarget);
        ResultSet rsCountR = psCountR.executeQuery();
        if (rsCountR.next()) {
            numRicette = rsCountR.getInt(1);
        }
        rsCountR.close();
        psCountR.close();

        // Limita a 24 ricette nella griglia
        if (numRicette > 24) {
            numRicette = 24;
        }

        // ---- Carica le ricette ----
        ricette = new RicettaCard[numRicette];
        PreparedStatement psRicette = conn.prepareStatement(
            "SELECT id_ricetta, titolo, immagine_url, categoria, difficolta " +
            "FROM Ricetta WHERE id_utente = ? AND pubblicata = TRUE " +
            "ORDER BY creato_il DESC LIMIT 24"
        );
        psRicette.setInt(1, idProfiloTarget);
        ResultSet rsRicette = psRicette.executeQuery();
        int i = 0;
        while (rsRicette.next() && i < ricette.length) {
            RicettaCard card = new RicettaCard();
            card.setIdRicetta(rsRicette.getInt("id_ricetta"));
            card.setTitolo(rsRicette.getString("titolo"));
            card.setImmagineUrl(UrlUtils.risolvi(ctx, rsRicette.getString("immagine_url")));
            card.setCategoria(rsRicette.getString("categoria"));
            card.setDifficolta(rsRicette.getString("difficolta"));
            ricette[i] = card;
            i++;
        }
        rsRicette.close();
        psRicette.close();

    } catch (Exception e) {
        // In caso di errore i dati rimangono vuoti
    } finally {
        if (conn != null) {
            try { conn.close(); } catch (Exception ignore) {}
        }
    }

    // Calcola la lettera iniziale per l'avatar fallback
    String iniziale = (nomeUtente != null && !nomeUtente.isEmpty())
                      ? nomeUtente.substring(0, 1).toUpperCase() : "U";
%>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= nomeUtente %> - BakingBread</title>
    <link rel="stylesheet" href="<%= ctx %>/css/global.css">
    <link rel="stylesheet" href="<%= ctx %>/css/profile.css">
    <link rel="icon" href="<%= ctx %>/media/favicon.svg">
</head>
<body>
    <jsp:include page="navbar.jsp" />

    <main class="container page-narrow" style="padding: 28px 0 56px;">
        <div class="profile-page">

            <%-- Intestazione profilo: avatar, nome, bio, statistiche --%>
            <div class="profile-header card">
                <div class="profile-avatar-wrap">
                    <% if (avatarUrl != null && !avatarUrl.isEmpty()) { %>
                        <img src="<%= avatarUrl %>" alt="Avatar" class="profile-avatar-big">
                    <% } else { %>
                        <span class="profile-avatar-big profile-avatar-fallback"><%= iniziale %></span>
                    <% } %>
                </div>

                <div class="profile-info-block">
                    <div class="profile-title-row">
                        <div>
                            <h1 style="margin:0 0 4px;"><%= nomeUtente %></h1>
                            <p class="text-muted" style="margin:0;">@<%= usernameTarget %></p>
                        </div>

                        <%-- Pulsanti azione: mostrati solo se guardi il profilo altrui --%>
                        <% if (isAltruiProfilo) { %>
                            <div style="display:flex; gap:10px; flex-wrap:wrap;">
                                <%-- Form follow/unfollow: POST alla stessa pagina --%>
                                <form method="POST" action="profile.jsp?id=<%= idProfiloTarget %>"
                                      style="margin:0;">
                                    <% if (seguoGiaTarget) { %>
                                        <input type="hidden" name="azione" value="smetti">
                                        <button type="submit" class="btn-secondary btn-sm">
                                            ✓ Stai seguendo
                                        </button>
                                    <% } else { %>
                                        <input type="hidden" name="azione" value="segui">
                                        <button type="submit" class="btn-primary btn-sm">
                                            + Segui
                                        </button>
                                    <% } %>
                                </form>
                                <%-- Link per inviare un messaggio diretto --%>
                                <a href="messaggi.jsp?chat=<%= idProfiloTarget %>"
                                   class="btn-secondary btn-sm">✉ Messaggio</a>
                            </div>
                        <% } else { %>
                            <%-- È il tuo profilo: link alle impostazioni --%>
                            <a href="impostazioni.jsp" class="btn-secondary btn-sm">
                                ⚙ Modifica profilo
                            </a>
                        <% } %>
                    </div>

                    <%-- Bio dell'utente (se presente) --%>
                    <% if (bio != null && !bio.isEmpty()) { %>
                        <p class="profile-meta" style="margin-top:14px;"><%= bio %></p>
                    <% } %>

                    <%-- Statistiche: ricette, follower, seguiti --%>
                    <div class="form-grid-3 profile-stats" style="margin-top:20px;">
                        <div class="stat-item">
                            <strong><%= numRicette %></strong>
                            <span class="text-muted">Ricette</span>
                        </div>
                        <div class="stat-item">
                            <a href="network.jsp?id=<%= idProfiloTarget %>&tab=follower"
                               style="text-decoration:none; color:inherit;">
                                <strong><%= numFollower %></strong>
                                <span class="text-muted">Follower</span>
                            </a>
                        </div>
                        <div class="stat-item">
                            <a href="network.jsp?id=<%= idProfiloTarget %>&tab=seguiti"
                               style="text-decoration:none; color:inherit;">
                                <strong><%= numSeguiti %></strong>
                                <span class="text-muted">Seguiti</span>
                            </a>
                        </div>
                    </div>
                </div>
            </div>

            <%-- Griglia ricette dell'utente --%>
            <div class="profile-recipes card">
                <div class="section-head">
                    <h2 style="margin:0;">Ricette</h2>
                    <% if (!isAltruiProfilo) { %>
                        <a href="crea_ricetta.jsp" class="btn-primary btn-sm">+ Nuova ricetta</a>
                    <% } %>
                </div>

                <% if (ricette.length == 0) { %>
                    <div class="empty-state">
                        <p>🍳 Nessuna ricetta pubblicata ancora.</p>
                        <% if (!isAltruiProfilo) { %>
                            <a href="crea_ricetta.jsp" class="btn-primary btn-sm">Crea la prima ricetta</a>
                        <% } %>
                    </div>
                <% } else { %>
                    <div class="recipe-grid profile-recipe-grid">
                        <% for (int i = 0; i < ricette.length; i++) { %>
                            <% RicettaCard r = ricette[i]; %>
                            <a href="dettaglio_ricetta.jsp?id=<%= r.getIdRicetta() %>"
                               class="recipe-card" style="min-height:220px; display:block;">
                                <% if (r.getImmagineUrl() != null && !r.getImmagineUrl().isEmpty()) { %>
                                    <img src="<%= r.getImmagineUrl() %>"
                                         alt="<%= r.getTitolo() %>"
                                         class="recipe-card-placeholder"
                                         style="width:100%; height:220px; object-fit:cover;">
                                <% } else { %>
                                    <div class="recipe-card-placeholder" style="height:220px;"></div>
                                <% } %>
                                <div class="recipe-card-overlay">
                                    <h3><%= r.getTitolo() %></h3>
                                    <% if (r.getDifficolta() != null) { %>
                                        <small><%= r.getDifficolta() %></small>
                                    <% } %>
                                </div>
                                <%-- Link modifica visibile solo sul proprio profilo --%>
                                <% if (!isAltruiProfilo) { %>
                                    <a href="crea_ricetta.jsp?modifica=<%= r.getIdRicetta() %>"
                                       class="btn-sm btn-secondary"
                                       style="position:absolute; top:10px; right:10px; padding:6px 12px;"
                                       onclick="event.stopPropagation();">✏ Modifica</a>
                                <% } %>
                            </a>
                        <% } %>
                    </div>
                <% } %>
            </div>

        </div>
    </main>
</body>
</html>
