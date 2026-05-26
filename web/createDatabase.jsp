<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.util.Scanner" %>
<%--
    ============================================================
    FILE: createDatabase.jsp
    ============================================================
--%>
<%
    String[] logMsg = new String[200];
    int logCount    = 0;
    boolean successo = false;

    // CREDENZIALI DI ACCESSO AL SERVER MYSQL
    String dbUrl  = "jdbc:mysql://localhost:3306/"; 
    String dbUser = "root";       
    String dbPass = ""; // Mantenuto vuoto come da precedente configurazione riuscita

    Connection conn = null;
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);

        // 1. Reset e creazione Database
        Statement setupStmt = conn.createStatement();
        setupStmt.execute("CREATE DATABASE IF NOT EXISTS bakingbread");
        setupStmt.execute("USE bakingbread");
        setupStmt.close();
        
        if (logCount < logMsg.length) {
            logMsg[logCount] = "✓ OK: Database 'bakingbread' pronto.";
            logCount++;
        }

        // 2. Lettura dell'INTERO file schema.sql in una stringa
        String percorsoSchema = application.getRealPath("/WEB-INF/sql/schema.sql");
        File fileSchema = new File(percorsoSchema);
        
        // Usiamo lo Scanner per leggere tutto il file in un colpo solo
        String interoContenuto = "";
        try (Scanner scanner = new Scanner(fileSchema, "UTF-8")) {
            interoContenuto = scanner.useDelimiter("\\A").next();
        }

        // 3. Rimuoviamo i commenti SQL multilinea (/* ... */) e a riga singola (-- ...)
        // prima di dividere, per evitare che i punti e virgola nei commenti rompano tutto
        interoContenuto = interoContenuto.replaceAll("(?s)/\\*.*?\\*/", "");
        interoContenuto = interoContenuto.replaceAll("--.*?\r?\n", "\n");

        // 4. Dividiamo le istruzioni usando il punto e virgola come separatore
        String[] istruzioni = interoContenuto.split(";");

        for (String istruzione : istruzioni) {
            String istruzionePulita = istruzione.trim();

            // Eseguiamo solo se l'istruzione non è vuota
            if (!istruzionePulita.isEmpty()) {
                try {
                    Statement stmt = conn.createStatement();
                    stmt.execute(istruzionePulita);
                    stmt.close();

                    if (logCount < logMsg.length) {
                        // Mostra i primi 60 caratteri nel log
                        String anteprima = istruzionePulita.replaceAll("\\s+", " ");
                        logMsg[logCount] = "✓ OK: " + anteprima.substring(0, Math.min(60, anteprima.length())) + "...";
                        logCount++;
                    }
                } catch (SQLException sqlEx) {
                    if (logCount < logMsg.length) {
                        logMsg[logCount] = "⚠ WARN: Errore nell'istruzione [" + istruzionePulita.substring(0, Math.min(30, istruzionePulita.length())) + "...] -> " + sqlEx.getMessage();
                        logCount++;
                    }
                }
            }
        }

        successo = true;

    } catch (Exception e) {
        if (logCount < logMsg.length) {
            logMsg[logCount] = "✕ ERRORE CRITICO: " + e.getMessage();
            logCount++;
        }
    } finally {
        if (conn != null) { try { conn.close(); } catch (Exception ignore) {} }
    }
%>
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Inizializza Database - BakingBread</title>
    <style>
        body       { font-family: monospace; padding: 40px; line-height: 1.5; }
        .log-entry { font-size: 13px; padding: 6px 0; border-bottom: 1px solid #eee; }
        .log-ok    { color: #15803d; }
        .log-warn  { color: #b45309; white-space: pre-wrap; } /* Permette di leggere l'errore intero */
        .log-err   { color: #dc2626; }
    </style>
</head>
<body>
    <h1>Inizializzazione Database</h1>
    <p>
        <% if (successo) { %>
            ✓ Operazione completata. Controlla il log qui sotto.
        <% } else { %>
            ✕ Si è verificato un errore grave.
        <% } %>
    </p>

    <hr>
    <h3>Log esecuzione (<%= logCount %> operazioni):</h3>

    <% for (int i = 0; i < logCount; i++) { %>
        <% String msg = logMsg[i]; %>
        <div class="log-entry 
            <%= msg.startsWith("✓") ? "log-ok" : msg.startsWith("⚠") ? "log-warn" : "log-err" %>">
            <%= msg %>
        </div>
    <% } %>

    <hr>
    <a href="login.jsp" style="margin-top:20px; display:inline-block;">→ Vai al login</a>
</body>
</html>