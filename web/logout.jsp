<%@ page contentType="text/html;charset=UTF-8" %>
<%--
    ============================================================
    FILE: logout.jsp
    SCOPO: Disconnette l'utente eliminando la sua sessione.
    - Invalida la sessione (cancella tutti i dati di sessione)
    - Reindirizza immediatamente alla pagina di login
    Non mostra nessuna HTML: è una pagina puramente "di azione".
    ============================================================
--%>
<%
    // Recupera la sessione corrente SENZA crearne una nuova
    // (false = non creare sessione se non esiste già)
    javax.servlet.http.HttpSession sessione = request.getSession(false);

    // Se esiste una sessione attiva, la distrugge completamente
    // Questo cancella tutti gli attributi (id_utente, username, ecc.)
    if (sessione != null) {
        sessione.invalidate(); // Invalida la sessione: l'utente non è più loggato
    }

    // Reindirizza il browser alla pagina di login
    response.sendRedirect("login.jsp");
%>
