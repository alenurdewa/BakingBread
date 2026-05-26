<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.bakingbread.util.*" %>
<%@ page import="com.bakingbread.model.*" %>
<%--
    ============================================================
    FILE: messaggi.jsp
    SCOPO: Gestisce la chat privata tra utenti.
    GET ?chat=N → apre la conversazione con l'utente N
    POST        → invia un messaggio all'utente selezionato
    - Mostra la lista delle conversazioni attive (colonna sx)
    - Mostra i messaggi della chat selezionata (colonna dx)
    ============================================================
--%>
<%
    response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    String ctx = request.getContextPath();
    Integer idUtenteLoggato = (Integer) session.getAttribute("id_utente");
    if (idUtenteLoggato == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    // Legge con chi parlare (parametro ?chat=N)
    int chatConId = 0;
    String chatParam = request.getParameter("chat");
    if (chatParam != null && !chatParam.trim().isEmpty()) {
        try { chatConId = Integer.parseInt(chatParam.trim()); } catch (Exception e) {}
    }

    // Non si può chattare con se stessi
    if (chatConId == idUtenteLoggato) {
        chatConId = 0;
    }

    String errorMsg = "";

    // --------------------------------------------------------
    // GESTIONE POST: invia un messaggio
    // --------------------------------------------------------
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String testo        = request.getParameter("testo");
        int    destinatario = 0;
        try { destinatario = Integer.parseInt(request.getParameter("destinatario_id")); } catch (Exception e) {}

        // Validazione: ci vuole testo e un destinatario valido
        if (testo != null && !testo.trim().isEmpty() && destinatario > 0 && destinatario != idUtenteLoggato) {
            Connection connPost = null;
            try {
                connPost = Db.getConnection();
                PreparedStatement ps = connPost.prepareStatement(
                    "INSERT INTO Messaggio (mittente_id, destinatario_id, testo) VALUES (?, ?, ?)"
                );
                ps.setInt(1, idUtenteLoggato); // Chi invia
                ps.setInt(2, destinatario);    // Chi riceve
                ps.setString(3, testo.trim()); // Contenuto
                ps.executeUpdate();
                ps.close();
            } catch (Exception e) {
                errorMsg = "Errore nell'invio del messaggio.";
            } finally {
                if (connPost != null) { try { connPost.close(); } catch (Exception ignore) {} }
            }
        }
        // Reindirizza per pulire il POST
        response.sendRedirect("messaggi.jsp?chat=" + destinatario);
        return;
    }

    // --------------------------------------------------------
    // CARICAMENTO LISTA CONVERSAZIONI
    // Trova tutti gli utenti con cui l'utente loggato ha
    // scambiato almeno un messaggio
    // --------------------------------------------------------

    // Prima conta le conversazioni attive
    Connection conn = null;
    UtenteCard[]    conversazioni  = new UtenteCard[0];
    MessaggioItem[] messaggiChat   = new MessaggioItem[0];
    String          nomeInterlocut = ""; // Nome dell'utente con cui stiamo chattando

    try {
        conn = Db.getConnection();

        // ---- Conta le conversazioni (utenti unici con cui ha parlato) ----
        PreparedStatement psCountConv = conn.prepareStatement(
            "SELECT COUNT(DISTINCT " +
            "  CASE WHEN mittente_id = ? THEN destinatario_id ELSE mittente_id END " +
            ") FROM Messaggio WHERE mittente_id = ? OR destinatario_id = ?"
        );
        psCountConv.setInt(1, idUtenteLoggato);
        psCountConv.setInt(2, idUtenteLoggato);
        psCountConv.setInt(3, idUtenteLoggato);
        ResultSet rsCountConv = psCountConv.executeQuery();
        int numConv = 0;
        if (rsCountConv.next()) { numConv = rsCountConv.getInt(1); }
        rsCountConv.close(); psCountConv.close();

        // Se stiamo aprendo una chat con qualcuno di nuovo (non nella lista)
        // aggiungiamo spazio per lui
        boolean chatNuova = false;
        if (chatConId > 0) {
            // Verifica se questo utente è già tra le conversazioni
            PreparedStatement psEsiste = conn.prepareStatement(
                "SELECT COUNT(*) FROM Messaggio " +
                "WHERE (mittente_id = ? AND destinatario_id = ?) " +
                "   OR (mittente_id = ? AND destinatario_id = ?)"
            );
            psEsiste.setInt(1, idUtenteLoggato); psEsiste.setInt(2, chatConId);
            psEsiste.setInt(3, chatConId);        psEsiste.setInt(4, idUtenteLoggato);
            ResultSet rsEsiste = psEsiste.executeQuery();
            int cntEsiste = 0;
            if (rsEsiste.next()) { cntEsiste = rsEsiste.getInt(1); }
            rsEsiste.close(); psEsiste.close();
            if (cntEsiste == 0) {
                chatNuova = true; // L'utente è nuovo: aggiungiamo alla lista
                numConv++;        // Incrementa per fare spazio nell'array
            }
        }

        // ---- Carica le conversazioni con ultimo messaggio ----
        conversazioni = new UtenteCard[numConv];

        // Query: trova i partner delle conversazioni con l'ultimo messaggio
        PreparedStatement psConv = conn.prepareStatement(
            "SELECT u.id_utente, u.username, u.nome_visualizzato, u.avatar_url, " +
            "  (SELECT testo FROM Messaggio m2 " +
            "   WHERE (m2.mittente_id = ? AND m2.destinatario_id = u.id_utente) " +
            "      OR (m2.mittente_id = u.id_utente AND m2.destinatario_id = ?) " +
            "   ORDER BY m2.creato_il DESC LIMIT 1) AS ultimo_msg " +
            "FROM Utente u " +
            "WHERE u.id_utente IN ( " +
            "  SELECT DISTINCT CASE WHEN mittente_id = ? THEN destinatario_id ELSE mittente_id END " +
            "  FROM Messaggio WHERE mittente_id = ? OR destinatario_id = ? " +
            ") " +
            "ORDER BY (SELECT creato_il FROM Messaggio m3 " +
            "          WHERE (m3.mittente_id = ? AND m3.destinatario_id = u.id_utente) " +
            "             OR (m3.mittente_id = u.id_utente AND m3.destinatario_id = ?) " +
            "          ORDER BY m3.creato_il DESC LIMIT 1) DESC"
        );
        // Imposta tutti i parametri della query
        psConv.setInt(1, idUtenteLoggato);
        psConv.setInt(2, idUtenteLoggato);
        psConv.setInt(3, idUtenteLoggato);
        psConv.setInt(4, idUtenteLoggato);
        psConv.setInt(5, idUtenteLoggato);
        psConv.setInt(6, idUtenteLoggato);
        psConv.setInt(7, idUtenteLoggato);
        ResultSet rsConv = psConv.executeQuery();

        int iConv = 0;
        while (rsConv.next() && iConv < conversazioni.length) {
            UtenteCard uc = new UtenteCard();
            uc.setIdUtente(rsConv.getInt("id_utente"));
            uc.setUsername(rsConv.getString("username"));
            uc.setNomeVisualizzato(rsConv.getString("nome_visualizzato"));
            uc.setAvatarUrl(UrlUtils.risolvi(ctx, rsConv.getString("avatar_url")));
            uc.setUltimoMessaggio(rsConv.getString("ultimo_msg"));
            conversazioni[iConv] = uc;
            iConv++;
        }
        rsConv.close(); psConv.close();

        // ---- Aggiunge l'utente "nuovo" in cima se non era nella lista ----
        if (chatNuova && chatConId > 0) {
            PreparedStatement psNuovo = conn.prepareStatement(
                "SELECT id_utente, username, nome_visualizzato, avatar_url FROM Utente WHERE id_utente = ?"
            );
            psNuovo.setInt(1, chatConId);
            ResultSet rsNuovo = psNuovo.executeQuery();
            if (rsNuovo.next()) {
                // Sposta tutte le conversazioni di una posizione in avanti
                // per inserire il nuovo utente all'inizio dell'array
                for (int k = conversazioni.length - 1; k > 0; k--) {
                    conversazioni[k] = conversazioni[k - 1];
                }
                // Inserisce il nuovo utente nella prima posizione
                UtenteCard ucNuovo = new UtenteCard();
                ucNuovo.setIdUtente(rsNuovo.getInt("id_utente"));
                ucNuovo.setUsername(rsNuovo.getString("username"));
                ucNuovo.setNomeVisualizzato(rsNuovo.getString("nome_visualizzato"));
                ucNuovo.setAvatarUrl(UrlUtils.risolvi(ctx, rsNuovo.getString("avatar_url")));
                ucNuovo.setUltimoMessaggio("Inizia una conversazione...");
                conversazioni[0] = ucNuovo;
                iConv++;
            }
            rsNuovo.close(); psNuovo.close();
        }

        // ---- Se c'è una chat aperta, carica i messaggi ----
        if (chatConId > 0) {
            // Recupera il nome dell'interlocutore per il titolo della chat
            PreparedStatement psNome = conn.prepareStatement(
                "SELECT nome_visualizzato FROM Utente WHERE id_utente = ?"
            );
            psNome.setInt(1, chatConId);
            ResultSet rsNome = psNome.executeQuery();
            if (rsNome.next()) { nomeInterlocut = rsNome.getString("nome_visualizzato"); }
            rsNome.close(); psNome.close();

            // Conta i messaggi di questa conversazione
            PreparedStatement psCountMsg = conn.prepareStatement(
                "SELECT COUNT(*) FROM Messaggio " +
                "WHERE (mittente_id = ? AND destinatario_id = ?) " +
                "   OR (mittente_id = ? AND destinatario_id = ?)"
            );
            psCountMsg.setInt(1, idUtenteLoggato); psCountMsg.setInt(2, chatConId);
            psCountMsg.setInt(3, chatConId);        psCountMsg.setInt(4, idUtenteLoggato);
            ResultSet rsCountMsg = psCountMsg.executeQuery();
            int numMsg = 0;
            if (rsCountMsg.next()) { numMsg = rsCountMsg.getInt(1); }
            rsCountMsg.close(); psCountMsg.close();

            messaggiChat = new MessaggioItem[numMsg];

            // Carica i messaggi ordinati dal più vecchio al più recente
            PreparedStatement psMsg = conn.prepareStatement(
                "SELECT id_messaggio, mittente_id, testo, creato_il FROM Messaggio " +
                "WHERE (mittente_id = ? AND destinatario_id = ?) " +
                "   OR (mittente_id = ? AND destinatario_id = ?) " +
                "ORDER BY creato_il ASC"
            );
            psMsg.setInt(1, idUtenteLoggato); psMsg.setInt(2, chatConId);
            psMsg.setInt(3, chatConId);        psMsg.setInt(4, idUtenteLoggato);
            ResultSet rsMsg = psMsg.executeQuery();
            int im = 0;
            while (rsMsg.next() && im < messaggiChat.length) {
                MessaggioItem m = new MessaggioItem();
                m.setIdMessaggio(rsMsg.getInt("id_messaggio"));
                m.setMittenteId(rsMsg.getInt("mittente_id"));
                m.setTesto(rsMsg.getString("testo"));
                m.setData(rsMsg.getTimestamp("creato_il"));
                messaggiChat[im] = m;
                im++;
            }
            rsMsg.close(); psMsg.close();

            // Segna tutti i messaggi ricevuti come letti
            PreparedStatement psLetti = conn.prepareStatement(
                "UPDATE Messaggio SET letto = TRUE " +
                "WHERE mittente_id = ? AND destinatario_id = ? AND letto = FALSE"
            );
            psLetti.setInt(1, chatConId);
            psLetti.setInt(2, idUtenteLoggato);
            psLetti.executeUpdate();
            psLetti.close();
        }

    } catch (Exception e) {
        errorMsg = "Errore nel caricamento dei messaggi.";
    } finally {
        if (conn != null) { try { conn.close(); } catch (Exception ignore) {} }
    }
%>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Messaggi - BakingBread</title>
    <link rel="stylesheet" href="<%= ctx %>/css/global.css">
    <link rel="stylesheet" href="<%= ctx %>/css/messages.css">
    <link rel="icon" href="<%= ctx %>/media/favicon.svg">
</head>
<body>
    <jsp:include page="navbar.jsp" />

    <main class="messages-layout">

        <%-- ===== COLONNA SINISTRA: lista conversazioni ===== --%>
        <aside class="conversations-panel">
            <div class="conversations-header">
                <h2>Messaggi</h2>
            </div>

            <% if (conversazioni.length == 0) { %>
                <div class="empty-state" style="padding:20px; text-align:center;">
                    <p class="text-muted">Nessuna conversazione ancora.</p>
                    <a href="network.jsp" class="btn-primary btn-sm">Trova persone</a>
                </div>
            <% } else { %>
                <%-- Ciclo su tutte le conversazioni --%>
                <% for (int i = 0; i < conversazioni.length; i++) { %>
                    <% UtenteCard conv = conversazioni[i]; %>
                    <%-- Evidenzia la conversazione attiva --%>
                    <a href="messaggi.jsp?chat=<%= conv.getIdUtente() %>"
                       class="conversation-item <%= chatConId == conv.getIdUtente() ? "active" : "" %>">

                        <%-- Avatar dell'interlocutore --%>
                        <% if (conv.getAvatarUrl() != null && !conv.getAvatarUrl().isEmpty()) { %>
                            <img src="<%= conv.getAvatarUrl() %>" alt="Avatar" class="avatar-md">
                        <% } else { %>
                            <span class="avatar-md avatar-fallback">
                                <%= conv.getNomeVisualizzato() != null
                                    ? conv.getNomeVisualizzato().substring(0,1).toUpperCase() : "U" %>
                            </span>
                        <% } %>

                        <div class="conversation-preview">
                            <strong><%= conv.getNomeVisualizzato() %></strong>
                            <% if (conv.getUltimoMessaggio() != null && !conv.getUltimoMessaggio().isEmpty()) { %>
                                <%-- Tronca il messaggio a 40 caratteri per l'anteprima --%>
                                <small class="text-muted">
                                    <% String anteprima = conv.getUltimoMessaggio(); %>
                                    <% if (anteprima.length() > 40) { %>
                                        <%= anteprima.substring(0, 40) %>...
                                    <% } else { %>
                                        <%= anteprima %>
                                    <% } %>
                                </small>
                            <% } %>
                        </div>
                    </a>
                <% } %>
            <% } %>
        </aside>

        <%-- ===== COLONNA DESTRA: chat aperta ===== --%>
        <section class="chat-panel">

            <% if (chatConId == 0) { %>
                <%-- Nessuna chat aperta: mostra stato vuoto --%>
                <div class="chat-empty">
                    <p style="font-size:48px; margin:0;">✉</p>
                    <h3>Seleziona una conversazione</h3>
                    <p class="text-muted">Clicca su un utente a sinistra per aprire la chat.</p>
                </div>

            <% } else { %>
                <%-- Intestazione della chat con il nome dell'interlocutore --%>
                <div class="chat-header">
                    <a href="profile.jsp?id=<%= chatConId %>" style="font-weight:700; color:inherit;">
                        <%= nomeInterlocut %>
                    </a>
                </div>

                <%-- Area messaggi con scroll --%>
                <div class="chat-messages" id="chatMessages">

                    <% if (messaggiChat.length == 0) { %>
                        <div class="chat-empty-inline">
                            <p class="text-muted">Nessun messaggio ancora. Scrivi il primo!</p>
                        </div>
                    <% } else { %>
                        <%-- Ciclo messaggi: bolle a destra se inviati, a sinistra se ricevuti --%>
                        <% for (int i = 0; i < messaggiChat.length; i++) { %>
                            <% MessaggioItem m = messaggiChat[i]; %>
                            <%-- Determina se il messaggio è stato inviato da me --%>
                            <% boolean isMio = (m.getMittenteId() == idUtenteLoggato); %>

                            <div class="message-bubble <%= isMio ? "bubble-out" : "bubble-in" %>">
                                <p><%= m.getTesto() %></p>
                                <% if (m.getData() != null) { %>
                                    <small class="bubble-time">
                                        <%= m.getData().toString().substring(11, 16) %> <%-- Mostra solo HH:MM --%>
                                    </small>
                                <% } %>
                            </div>
                        <% } %>
                    <% } %>
                </div>

                <%-- Form invio messaggio --%>
                <div class="chat-input-area">
                    <form method="POST"
                          action="messaggi.jsp"
                          class="chat-input-form">
                        <input type="hidden" name="destinatario_id" value="<%= chatConId %>">
                        <textarea name="testo"
                                  rows="2"
                                  placeholder="Scrivi un messaggio..."
                                  required
                                  maxlength="2000"
                                  onkeydown="inviaConInvio(event, this.form)"></textarea>
                        <button type="submit" class="btn-primary">Invia</button>
                    </form>
                </div>
            <% } %>

        </section>
    </main>

    <script>
        // Scrolla automaticamente la finestra chat in fondo (messaggio più recente)
        var chatDiv = document.getElementById("chatMessages");
        if (chatDiv) {
            chatDiv.scrollTop = chatDiv.scrollHeight; // Porta lo scroll all'ultimo messaggio
        }

        // Permette di inviare il messaggio premendo Invio (senza Shift)
        function inviaConInvio(event, form) {
            if (event.key === "Enter" && !event.shiftKey) {
                event.preventDefault(); // Impedisce il ritorno a capo
                form.submit();          // Invia il form
            }
        }
    </script>
</body>
</html>
