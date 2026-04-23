<%@ page contentType="text/html;charset=UTF-8" %>
<%
    session.invalidate(); // Distrugge la sessione attuale
    response.sendRedirect("home.jsp"); // Torna alla home come utente non loggato
%>