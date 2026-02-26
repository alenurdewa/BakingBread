<%@ page import="java.sql.*" %>
<%@ page import="java.security.MessageDigest" %>
<%@ page contentType="text/html;charset=UTF-8" %>

<%
    String username = request.getParameter("username");
    String password = request.getParameter("password");

    // Hash SHA-256 semplice
    MessageDigest md = MessageDigest.getInstance("SHA-256");
    byte[] hash = md.digest(password.getBytes("UTF-8"));
    StringBuilder sb = new StringBuilder();
    for(byte b : hash){
        sb.append(String.format("%02x", b));
    }
    String passwordHash = sb.toString();

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {

        Class.forName("com.mysql.cj.jdbc.Driver");

        conn = DriverManager.getConnection(
            "jdbc:mysql://localhost:3306/bakingbread",
            "root",
            ""
        );

        String sql = "SELECT * FROM utenti WHERE (username=? OR email=?) AND password_hash=?";
        ps = conn.prepareStatement(sql);
        ps.setString(1, username);
        ps.setString(2, username);
        ps.setString(3, passwordHash);

        rs = ps.executeQuery();

        if(rs.next()) {

            session.setAttribute("id_utente", rs.getInt("id_utente"));
            session.setAttribute("username", rs.getString("username"));
            session.setAttribute("ruolo", rs.getString("ruolo"));

            response.sendRedirect("home.jsp");

        } else {
            response.sendRedirect("login.jsp?errore=1");
        }

    } catch(Exception e){
        out.println("Errore: " + e.getMessage());
    } finally {
        if(rs!=null) rs.close();
        if(ps!=null) ps.close();
        if(conn!=null) conn.close();
    }
%>