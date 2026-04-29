<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, com.bakingbread.util.UrlUtils" %>
<%
    String ctx = request.getContextPath();
    Integer idUtenteLoggato = (Integer) session.getAttribute("id_utente");
    String nomeUtenteLoggato = (String) session.getAttribute("nome_utente");
    String usernameLoggato = (String) session.getAttribute("username");
    String avatarLoggato = (String) session.getAttribute("avatar_url");
    int messaggiNonLetti = 0;

    if (idUtenteLoggato != null) {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/bakingbread?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true", "root", "");
            PreparedStatement ps = conn.prepareStatement("SELECT avatar_url, nome_visualizzato, username FROM Utente WHERE id_utente = ?");
            ps.setInt(1, idUtenteLoggato);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                if (avatarLoggato == null || avatarLoggato.isEmpty()) avatarLoggato = rs.getString("avatar_url");
                if (nomeUtenteLoggato == null || nomeUtenteLoggato.isEmpty()) nomeUtenteLoggato = rs.getString("nome_visualizzato");
                if (usernameLoggato == null || usernameLoggato.isEmpty()) usernameLoggato = rs.getString("username");
            }
            rs.close();
            ps.close();
            ps = conn.prepareStatement("SELECT COUNT(*) FROM Messaggio WHERE destinatario_id = ? AND letto = FALSE");
            ps.setInt(1, idUtenteLoggato);
            rs = ps.executeQuery();
            if (rs.next()) messaggiNonLetti = rs.getInt(1);
            rs.close();
            ps.close();
            conn.close();
        } catch (Exception ignore) {}
    }

    avatarLoggato = UrlUtils.resolve(ctx, avatarLoggato);

    String avatarInitial = "U";
    if (nomeUtenteLoggato != null && !nomeUtenteLoggato.isEmpty()) {
        avatarInitial = nomeUtenteLoggato.substring(0, 1).toUpperCase();
    } else if (usernameLoggato != null && !usernameLoggato.isEmpty()) {
        avatarInitial = usernameLoggato.substring(0, 1).toUpperCase();
    }
%>
<nav class="navbar">
    <div class="container navbar-inner">
<a href="<%= ctx %>/home.jsp" class="navbar-brand">
    <span class="brand-mark" aria-hidden="true">
        <img src="<%= ctx %>/media/favicon.svg" alt="Logo">
    </span>
    BakingBread
</a>

        <div class="navbar-search">
            <form action="<%= ctx %>/home.jsp" method="get" class="navbar-search-form">
                <input type="search" name="q" placeholder="Cerca ricette..." value="<%= request.getParameter("q") != null ? request.getParameter("q") : "" %>">
                <button type="submit" class="btn-primary btn-sm">Cerca</button>
            </form>
        </div>

        <ul class="navbar-nav">
            <li><a href="<%= ctx %>/home.jsp">Home</a></li>
            <% if (idUtenteLoggato != null) { %>
                <li><a href="<%= ctx %>/network.jsp">Rete</a></li>
                <li><a href="<%= ctx %>/crea_ricetta.jsp">Crea</a></li>
                <li><a href="<%= ctx %>/messaggi.jsp" class="nav-message-link">Messaggi <% if (messaggiNonLetti > 0) { %><span class="badge badge-primary"><%= messaggiNonLetti %></span><% } %></a></li>
                <li class="dropdown">
                    <a href="<%= ctx %>/profile.jsp?id=<%= idUtenteLoggato %>" class="avatar-link">
                        <% if (avatarLoggato != null && !avatarLoggato.trim().isEmpty()) { %>
                            <img src="<%= avatarLoggato %>" alt="Avatar" class="nav-avatar-img">
                        <% } else { %>
                            <span class="nav-avatar-fallback"><%= avatarInitial %></span>
                        <% } %>
                    </a>
                    <button class="dropdown-toggle" type="button" onclick="toggleDropdown(event)" aria-label="Apri menu utente">▾</button>
                    <div class="dropdown-menu">
                        <a href="<%= ctx %>/profile.jsp?id=<%= idUtenteLoggato %>" class="dropdown-item">Il tuo profilo</a>
                        <a href="<%= ctx %>/collezioni.jsp" class="dropdown-item">Le tue collezioni</a>
                        <a href="<%= ctx %>/impostazioni.jsp" class="dropdown-item">Impostazioni</a>
                        <a href="<%= ctx %>/logout.jsp" class="dropdown-item dropdown-item-danger">Esci</a>
                    </div>
                </li>
            <% } else { %>
                <li><a href="<%= ctx %>/login.jsp">Accedi</a></li>
                <li><a href="<%= ctx %>/register.jsp" class="btn-primary btn-sm">Registrati</a></li>
            <% } %>
        </ul>
    </div>
</nav>
