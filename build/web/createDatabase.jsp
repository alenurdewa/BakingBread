<%@ page import="java.sql.*,java.io.*" %>
<%@ page contentType="text/html;charset=UTF-8" %>
<html>
<head><title>Creazione Database BakingBread</title></head>
<body>
<h2>Creazione Database BakingBread...</h2>

<%
String USER = "root";
String PASSWORD = "";
String DSN = "jdbc:mysql://localhost:3306/?useSSL=false&serverTimezone=UTC";
String sqlFile = application.getRealPath("/WEB-INF/sql/bakingbread.sql");

Connection conn = null;
Statement stmt = null;

try {
    Class.forName("com.mysql.cj.jdbc.Driver");
    conn = DriverManager.getConnection(DSN, USER, PASSWORD);
    stmt = conn.createStatement();

    BufferedReader br = new BufferedReader(new FileReader(sqlFile));
    StringBuilder sb = new StringBuilder();
    String line;
    while ((line = br.readLine()) != null) {
        line = line.trim();
        if (line.isEmpty() || line.startsWith("--")) continue; // ignora commenti e linee vuote
        sb.append(line).append(" ");
        if (line.endsWith(";")) { // fine statement SQL
            stmt.execute(sb.toString());
            sb.setLength(0); // reset buffer
        }
    }
    br.close();

    out.println("<h3 style='color:green;'>Database e tabelle create con successo ✅</h3>");

} catch(Exception e){
    out.println("<p style='color:red;'>Errore: " + e.getMessage() + "</p>");
} finally {
    if(stmt != null) stmt.close();
    if(conn != null) conn.close();
}
%>
</body>
</html>