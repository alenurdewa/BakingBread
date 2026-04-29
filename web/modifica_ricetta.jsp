<%@ page contentType="text/html;charset=UTF-8" %>
<%
    String ctx = request.getContextPath();
    String id = request.getParameter("id");
    if (id == null || id.trim().isEmpty()) {
        response.sendRedirect(ctx + "/crea_ricetta.jsp");
        return;
    }
    response.sendRedirect(ctx + "/crea_ricetta.jsp?modifica=" + id);
%>
