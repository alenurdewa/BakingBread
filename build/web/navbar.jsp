<%@ page contentType="text/html;charset=UTF-8" %>
<nav class="navbar">
    <div class="navbar-container">
        <a href="home.jsp" class="navbar-brand">BakingBread</a>
        <div class="navbar-search">
            <input type="text" placeholder="Cerca ricette, ingredienti...">
        </div>
        <div class="navbar-menu">
            <% if (session.getAttribute("id_utente") != null) { %>
                <a href="crea_ricetta.jsp" class="nav-link">Crea Ricetta</a>
                <a href="profile.jsp" class="nav-link">Profilo</a>
                <a href="logout.jsp" class="nav-link text-danger">Logout</a>
            <% } else { %>
                <a href="login.jsp" class="nav-link">Accedi</a>
                <a href="register.jsp" class="nav-link">Registrati</a>
            <% } %>
        </div>
    </div>
</nav>