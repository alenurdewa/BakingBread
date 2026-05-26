<%@ page contentType="text/html;charset=UTF-8" %>
<%--
    ============================================================
    FILE: modifica_ricetta.jsp
    SCOPO: Pagina di reindirizzamento.
    Riceve ?id=N e rimanda a crea_ricetta.jsp?modifica=N.
    ============================================================
--%>
<%
    // Legge l'ID della ricetta da modificare
    String id = request.getParameter("id");

    // Verifica che sia un valore numerico prima di usarlo
    if (id != null && !id.trim().isEmpty()) {
        try {
            // Tenta la conversione a intero per verificare che sia un numero
            Integer.parseInt(id.trim());
            // Reindirizza alla pagina di creazione/modifica
            response.sendRedirect("crea_ricetta.jsp?modifica=" + id.trim());
        } catch (NumberFormatException e) {
            // ID non numerico: va alla home
            response.sendRedirect("home.jsp");
        }
    } else {
        // ID mancante: va alla home
        response.sendRedirect("home.jsp");
    }
%>
