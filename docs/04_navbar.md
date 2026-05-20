# 04 – `navbar.jsp` — Spiegazione riga per riga

## Scopo del file
Componente riutilizzabile della barra di navigazione. Viene incluso in tutte le altre pagine tramite `<jsp:include page="navbar.jsp" />`. Mostra il logo, la barra di ricerca, i link di navigazione e il menu utente con contatore messaggi non letti.

---

## Come viene inclusa

In ogni altra JSP si trova:
```jsp
<jsp:include page="navbar.jsp" />
```
Questo taglia e incolla il contenuto di `navbar.jsp` nella posizione del tag. La navbar esegue il suo codice Java e produce l'HTML che viene inserito nella pagina chiamante.

---

## Analisi riga per riga

### Direttive

```jsp
<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, com.bakingbread.util.UrlUtils" %>
```

Importa `UrlUtils` (classe di utilità del progetto per gestire URL relativi e assoluti).

---

### Lettura dati dalla sessione

```jsp
<%
    String ctx = request.getContextPath();
    Integer idUtenteLoggato = (Integer) session.getAttribute("id_utente");
    String nomeUtenteLoggato = (String) session.getAttribute("nome_utente");
    String usernameLoggato = (String) session.getAttribute("username");
    String avatarLoggato = (String) session.getAttribute("avatar_url");
    int messaggiNonLetti = 0;
```

- `request.getContextPath()` → restituisce il path base dell'app (es. `/BakingBread` o `""` se deploy in root). Usato per costruire URL corretti.
- Legge dalla sessione i dati dell'utente loggato. `avatar_url` è un attributo opzionale salvato nella sessione.
- `messaggiNonLetti` inizializzato a 0 (nessun badge di notifica di default).

---

### Query database (solo se utente loggato)

```jsp
    if (idUtenteLoggato != null) {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/bakingbread?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true", "root", "");
```

Il blocco database viene eseguito solo se l'utente è autenticato. Apre la connessione al DB.

```jsp
            PreparedStatement ps = conn.prepareStatement("SELECT avatar_url, nome_visualizzato, username FROM Utente WHERE id_utente = ?");
            ps.setInt(1, idUtenteLoggato);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                if (avatarLoggato == null || avatarLoggato.isEmpty()) avatarLoggato = rs.getString("avatar_url");
                if (nomeUtenteLoggato == null || nomeUtenteLoggato.isEmpty()) nomeUtenteLoggato = rs.getString("nome_visualizzato");
                if (usernameLoggato == null || usernameLoggato.isEmpty()) usernameLoggato = rs.getString("username");
            }
```

Recupera i dati aggiornati dal database. Usa i valori del DB solo come fallback: se la sessione ha già un valore valido, lo mantiene. Questo è importante perché un utente potrebbe aver aggiornato il profilo (cambiato avatar/nome) in un'altra sessione, e la navbar mostrerebbe dati aggiornati.

```jsp
            ps = conn.prepareStatement("SELECT COUNT(*) FROM Messaggio WHERE destinatario_id = ? AND letto = FALSE");
            ps.setInt(1, idUtenteLoggato);
            rs = ps.executeQuery();
            if (rs.next()) messaggiNonLetti = rs.getInt(1);
```

Conta i messaggi non letti dell'utente. `COUNT(*)` restituisce sempre una riga (anche se = 0). `rs.getInt(1)` recupera il primo (e unico) campo della riga risultante.

```jsp
            rs.close();
            ps.close();
            conn.close();
        } catch (Exception ignore) {}
    }
```

Chiude le risorse. Gli errori vengono ignorati silenziosamente: se la navbar non riesce a caricare il contatore messaggi, la pagina continua a funzionare (degradazione elegante).

---

### Risoluzione URL avatar

```jsp
    avatarLoggato = UrlUtils.resolve(ctx, avatarLoggato);
```

Converte l'URL dell'avatar (che può essere relativo come `/uploads/avatars/...` o assoluto come `https://...`) in un URL usabile nell'HTML. Vedi la spiegazione di `UrlUtils.java` per i dettagli.

---

### Calcolo iniziale del nome (fallback)

```jsp
    String avatarInitial = "U";
    if (nomeUtenteLoggato != null && !nomeUtenteLoggato.isEmpty()) {
        avatarInitial = nomeUtenteLoggato.substring(0, 1).toUpperCase();
    } else if (usernameLoggato != null && !usernameLoggato.isEmpty()) {
        avatarInitial = usernameLoggato.substring(0, 1).toUpperCase();
    }
%>
```

Calcola la lettera iniziale da mostrare nel avatar circolare quando l'utente non ha caricato una foto. Priorità:
1. Prima lettera del nome visualizzato
2. Prima lettera dello username
3. "U" come fallback finale

---

### HTML della navbar

```html
<nav class="navbar">
    <div class="container navbar-inner">
```

Struttura semantica HTML5: `<nav>` è l'elemento semantico per la navigazione.

```html
<a href="<%= ctx %>/home.jsp" class="navbar-brand">
    <span class="brand-mark" aria-hidden="true">
        <img src="<%= ctx %>/media/favicon.svg" alt="Logo">
    </span>
    BakingBread
</a>
```

Logo/brand name della app, link alla home. `aria-hidden="true"` nasconde l'immagine ai lettori di schermo (è decorativa, il testo "BakingBread" già la descrive). `<%= ctx %>` inserisce il context path per URL corretti.

```html
<div class="navbar-search">
    <form action="<%= ctx %>/home.jsp" method="get" class="navbar-search-form">
        <input type="search" name="q" placeholder="Cerca ricette..." 
               value="<%= request.getParameter("q") != null ? request.getParameter("q") : "" %>">
        <button type="submit" class="btn-primary btn-sm">Cerca</button>
    </form>
</div>
```

Form di ricerca che invia a `home.jsp` con parametro `q`. Usa metodo GET (non POST) perché la ricerca è una lettura, non una modifica. Il `value` mantiene il testo di ricerca precedente se si è già sulla pagina home.jsp con una ricerca attiva.

---

### Menu navigazione condizionale

```html
<ul class="navbar-nav">
    <li><a href="<%= ctx %>/home.jsp">Home</a></li>
    <% if (idUtenteLoggato != null) { %>
        <li><a href="<%= ctx %>/network.jsp">Rete</a></li>
        <li><a href="<%= ctx %>/crea_ricetta.jsp">Crea</a></li>
        <li><a href="<%= ctx %>/messaggi.jsp" class="nav-message-link">
            Messaggi 
            <% if (messaggiNonLetti > 0) { %>
                <span class="badge badge-primary"><%= messaggiNonLetti %></span>
            <% } %>
        </a></li>
```

La navbar mostra menu diversi a seconda dello stato di autenticazione:
- **Utente loggato**: Rete, Crea, Messaggi (con badge contatore), profilo
- **Ospite**: solo Accedi e Registrati

Il badge `<span class="badge">` con il numero di messaggi non letti appare solo se `messaggiNonLetti > 0`.

```html
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
```

Dropdown menu utente:
- L'avatar è un link al profilo dell'utente
- Se c'è un'immagine avatar, mostra `<img>`, altrimenti mostra un cerchio con la lettera iniziale
- Il pulsante `▾` apre il dropdown tramite JavaScript (`toggleDropdown`)
- Il dropdown contiene link a profilo, collezioni, impostazioni e logout

```html
    <% } else { %>
        <li><a href="<%= ctx %>/login.jsp">Accedi</a></li>
        <li><a href="<%= ctx %>/register.jsp" class="btn-primary btn-sm">Registrati</a></li>
    <% } %>
```

Per gli ospiti (non loggati): solo link Accedi e Registrati. Il pulsante "Registrati" ha classe `btn-primary` per distinguersi visivamente.

---

## Perché la navbar interroga il database ad ogni richiesta?

La navbar fa una query al DB ogni volta che viene inclusa (cioè ad ogni richiesta a qualsiasi pagina). Questo garantisce che i dati siano sempre aggiornati (messaggi non letti, avatar, nome). In un'applicazione ad alto traffico si userebbe una cache (Redis, Ehcache), ma per questo progetto è appropriato.
