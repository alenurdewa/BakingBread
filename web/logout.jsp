<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%
    response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    Integer idUtente = (Integer) session.getAttribute("id_utente");
    
    if (idUtente != null) {
        try {
            Cookie[] cookies = request.getCookies();
            if (cookies != null) {
                for (Cookie c : cookies) {
                    if ("remember_token".equals(c.getName())) {
                        String token = c.getValue();
                        Class.forName("com.mysql.cj.jdbc.Driver");
                        java.sql.Connection conn = DriverManager.getConnection(
                            "jdbc:mysql://localhost:3306/bakingbread?useSSL=false", "root", "");
                        PreparedStatement ps = conn.prepareStatement(
                            "DELETE FROM SessioneToken WHERE id_utente = ? AND token = ?");
                        ps.setInt(1, idUtente);
                        ps.setString(2, token);
                        ps.executeUpdate();
                        ps.close();
                        conn.close();
                    }
                }
            }
        } catch (Exception e) {
            // ignora errori durante logout
        }
    }
    
    Cookie rememberCookie = new Cookie("remember_token", "");
    rememberCookie.setMaxAge(0);
    rememberCookie.setPath("/");
    rememberCookie.setHttpOnly(true);
    response.addCookie(rememberCookie);
    
    session.invalidate();
    response.sendRedirect("login.jsp");
%>