<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%
    Integer idUtenteLoggato = (Integer) session.getAttribute("id_utente");
    String nomeUtenteLoggato = (String) session.getAttribute("nome_utente");
    String usernameLoggato = (String) session.getAttribute("username");
    
    int messaggiNonLetti = 0;
    if (idUtenteLoggato != null) {
        try {
            Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/bakingbread?useSSL=false", "root", "");
            PreparedStatement ps = conn.prepareStatement(
                "SELECT COUNT(*) FROM Messaggio WHERE destinatario_id = ? AND letto = FALSE");
            ps.setInt(1, idUtenteLoggato);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) messaggiNonLetti = rs.getInt(1);
            rs.close();
            ps.close();
            conn.close();
        } catch (Exception e) {
            // ignora errori
        }
    }
%>
<nav class="navbar">
    <div class="container d-flex align-items-center justify-content-between">
        <a href="home.jsp" class="navbar-brand">
            <svg width="32" height="32" viewBox="0 0 32 32" fill="none">
                <path d="M16 2C14 2 12.5 3.5 12 5C11.5 4 10 2 7 2C5 2 3 4 3 6C3 9 6 12 9 14C7 15 6 17 6 19C6 22 8 24 11 24C13 24 15 23 16 21C17 23 19 24 21 24C24 24 26 22 26 19C26 17 25 15 23 14C26 12 29 9 29 6C29 4 27 2 25 2C22 2 20.5 3.5 20 5C19.5 3.5 18 2 16 2Z" fill="#ff5a1f"/>
            </svg>
            BakingBread
        </a>
        
        <div class="navbar-search d-none d-md-block">
            <form action="home.jsp" method="get" style="display:flex;gap:8px;">
                <input type="search" name="q" placeholder="Cerca ricette..." value="<%= request.getParameter("q") != null ? request.getParameter("q") : "" %>">
                <button type="submit" class="btn-primary btn-sm" style="width:auto;padding:10px 16px;">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/>
                    </svg>
                </button>
            </form>
        </div>
        
        <ul class="navbar-nav d-flex align-items-center">
            <li><a href="home.jsp">Home</a></li>
            <% if (idUtenteLoggato != null) { %>
                <li><a href="network.jsp">rete</a></li>
                <li><a href="crea_ricetta.jsp">Crea</a></li>
                <li>
                    <a href="messaggi.jsp" class="d-flex align-items-center gap-1">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
                        </svg>
                        <% if (messaggiNonLetti > 0) { %>
                            <span class="badge badge-primary"><%= messaggiNonLetti %></span>
                        <% } %>
                    </a>
                </li>
                <li class="dropdown">
                    <a href="#" class="d-flex align-items-center gap-2" onclick="toggleDropdown(event)">
                        <div class="post-avatar avatar-sm" style="width:36px;height:36px;font-size:14px;">
                            <%= usernameLoggato != null ? usernameLoggato.substring(0,1).toUpperCase() : "U" %>
                        </div>
                    </a>
                    <div class="dropdown-menu">
                        <a href="profile.jsp?id=<%= idUtenteLoggato %>" class="dropdown-item">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:8px;">
                                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/>
                            </svg>
                            Il tuo Profilo
                        </a>
                        <a href="collezioni.jsp" class="dropdown-item">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:8px;">
                                <path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z"/>
                            </svg>
                            Le tue Collezioni
                        </a>
                        <a href="impostazioni.jsp" class="dropdown-item">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:8px;">
                                <circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/>
                            </svg>
                            Impostazioni
                        </a>
                        <hr style="margin:8px 0;border-color:var(--border-color);">
                        <a href="logout.jsp" class="dropdown-item" style="color:var(--danger-color);">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="margin-right:8px;">
                                <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/>
                            </svg>
                            Esci
                        </a>
                    </div>
                </li>
            <% } else { %>
                <li><a href="login.jsp">Accedi</a></li>
                <li><a href="register.jsp" class="btn-primary btn-sm" style="width:auto;padding:8px 16px;">Registrati</a></li>
            <% } %>
        </ul>
    </div>
</nav>
<script>
function toggleDropdown(event) {
    event.preventDefault();
    event.stopPropagation();
    var dropdown = event.currentTarget.closest('.dropdown');
    dropdown.querySelector('.dropdown-menu').classList.toggle('show');
}
document.addEventListener('click', function(e) {
    document.querySelectorAll('.dropdown-menu.show').forEach(function(menu) {
        menu.classList.remove('show');
    });
});
</script>