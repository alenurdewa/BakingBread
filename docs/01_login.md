# 01 – `login.jsp` — Spiegazione riga per riga

## Scopo del file
Gestisce sia la **visualizzazione** del form di login sia la **logica di autenticazione** quando il form viene inviato. Supporta anche il login automatico tramite cookie ("Ricordami").

---

## Struttura generale

```
login.jsp
├── [Blocco Java - SCRIPTLET]
│   ├── Anti-cache headers
│   ├── Controllo se già loggato → redirect home
│   ├── Lettura cookie "remember_token" → auto-login
│   └── Gestione POST (login manuale)
│       ├── Validazione input
│       ├── Query database per trovare utente
│       ├── Verifica password (SHA-256 + salt)
│       ├── Creazione sessione
│       └── Gestione "Ricordami" (cookie + DB)
└── [HTML]
    ├── Form login (username, password, checkbox ricordami)
    └── JavaScript inline (mostra/nascondi password)
```

---

## Analisi riga per riga

### Direttive iniziali

```jsp
<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, java.security.*, java.util.*" %>
```

**Riga 1**: Direttiva di pagina. Dice a Tomcat che questa JSP produce HTML in codifica UTF-8 (supporta caratteri speciali italiani: à, è, ì, ò, ù).

**Riga 2**: Importa tre pacchetti Java:
- `java.sql.*` → `Connection`, `PreparedStatement`, `ResultSet`, `DriverManager` per il database
- `java.security.*` → `MessageDigest` (per SHA-256), `SecureRandom` (per generare token casuali)
- `java.util.*` → `Calendar`, `Date`, `Cookie`

---

### Blocco scriptlet principale `<% ... %>`

```jsp
<%
    response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);
```

**Anti-cache**: questi tre header HTTP istruiscono il browser a non memorizzare questa pagina. Critico per le pagine di autenticazione: se il browser mettesse in cache la pagina di login (o peggio una sessione autenticata), potrebbe mostrare dati errati dopo il logout.
- `no-store` → non salvare nemmeno temporaneamente
- `no-cache` → non usare la copia in cache senza rivalidare col server
- `must-revalidate` → deve sempre chiedere al server
- `Expires: 0` → indica che la risorsa è già scaduta

```jsp
    String errorMsg = "";
    String successMsg = "";
```

Variabili stringa inizializzate vuote. Verranno popolate in caso di errore o successo e poi mostrate nell'HTML.

```jsp
    Integer idUtenteLoggato = (Integer) session.getAttribute("id_utente");
    if (idUtenteLoggato != null) {
        response.sendRedirect("home.jsp");
        return;
    }
```

Legge dalla sessione l'ID dell'utente. `session.getAttribute()` restituisce un `Object`, quindi è necessario il cast a `Integer`. Se l'utente è già loggato (l'attributo esiste), non ha senso mostrargli il form di login: lo reindirizza subito a `home.jsp`. Il `return` ferma immediatamente l'esecuzione: senza di esso, tutto il resto del codice verrebbe eseguito ugualmente.

```jsp
    String dbUrl = "jdbc:mysql://localhost:3306/bakingbread?useSSL=false";
    String dbUser = "root";
    String dbPass = "";
```

Parametri di connessione al database:
- `jdbc:mysql://` → protocollo JDBC per MySQL
- `localhost:3306` → MySQL gira sulla stessa macchina, porta standard 3306
- `bakingbread` → nome del database
- `useSSL=false` → disabilita SSL (sicuro solo in sviluppo locale)
- `root` / `""` → credenziali MySQL di default per sviluppo locale

---

### Gestione cookie "Ricordami"

```jsp
    Cookie[] cookies = request.getCookies();
    String rememberToken = null;
    if (cookies != null) {
        for (Cookie c : cookies) {
            if ("remember_token".equals(c.getName())) {
                rememberToken = c.getValue();
                break;
            }
        }
    }
```

Recupera tutti i cookie inviati dal browser con la richiesta. HTTP permette al browser di inviare tutti i cookie del dominio insieme ad ogni richiesta. Scorre l'array finché trova il cookie chiamato `"remember_token"`. Se trovato, salva il suo valore (un token casuale di 64 caratteri esadecimali) in `rememberToken`. Il `break` esce dal ciclo appena trovato il cookie.

```jsp
    if (rememberToken != null && "POST".equalsIgnoreCase(request.getMethod()) == false) {
```

Controlla due condizioni:
1. Il cookie esiste (`rememberToken != null`)
2. La richiesta non è un POST (il login automatico va fatto solo su GET, non quando l'utente sta attivamente inviando un form)

`"POST".equalsIgnoreCase(...)` usa `equalsIgnoreCase` invece di `equals` perché il metodo HTTP potrebbe essere `post`, `POST` o `Post`. L'`== false` alla fine nega la condizione.

```jsp
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
```

`Class.forName("com.mysql.cj.jdbc.Driver")` carica il driver JDBC MySQL in memoria. È necessario prima di qualsiasi operazione di database. `com.mysql.cj.jdbc.Driver` è il nome della classe del driver MySQL Connector/J versione 8+.

```jsp
            PreparedStatement ps = conn.prepareStatement(
                "SELECT st.id_utente, u.username, u.nome_visualizzato FROM SessioneToken st " +
                "JOIN Utente u ON st.id_utente = u.id_utente " +
                "WHERE st.token = ? AND st.scade_il > NOW() AND u.attivo = TRUE");
            ps.setString(1, rememberToken);
            ResultSet rs = ps.executeQuery();
```

Cerca nella tabella `SessioneToken` un token che:
- Corrisponde esattamente al cookie `st.token = ?`
- Non è ancora scaduto `st.scade_il > NOW()`
- Appartiene a un utente attivo `u.attivo = TRUE`

Usa un JOIN con la tabella `Utente` per ottenere username e nome direttamente. `ps.setString(1, rememberToken)` sostituisce il primo `?` con il valore del cookie.

```jsp
            if (rs.next()) {
                session.setAttribute("id_utente", rs.getInt("id_utente"));
                session.setAttribute("nome_utente", rs.getString("nome_visualizzato"));
                session.setAttribute("username", rs.getString("username"));
                
                ps = conn.prepareStatement("UPDATE Utente SET ultimo_accesso = NOW() WHERE id_utente = ?");
                ps.setInt(1, rs.getInt("id_utente"));
                ps.executeUpdate();
                
                response.sendRedirect("home.jsp");
                return;
            }
```

Se il token è valido (`rs.next()` restituisce `true`):
1. Crea la sessione con i dati dell'utente (stessa cosa del login manuale)
2. Aggiorna `ultimo_accesso` nel database con il timestamp corrente
3. Reindirizza a `home.jsp` (l'utente è ora loggato senza aver inserito le credenziali)
4. `return` ferma l'esecuzione del resto della pagina

---

### Gestione POST (login manuale)

```jsp
    if ("POST".equalsIgnoreCase(request.getMethod())) {
```

Controlla se la richiesta è di tipo POST. Il form di login usa `method="POST"`, quindi questo blocco viene eseguito solo quando l'utente clicca "Accedi".

```jsp
        String username = request.getParameter("username");
        String password = request.getParameter("password");
        String rememberMe = request.getParameter("ricordami");
```

Legge i parametri del form:
- `username` → valore del campo `<input name="username">`
- `password` → valore del campo `<input name="password">`
- `rememberMe` → se la checkbox "Ricordami" è spuntata, il parametro esiste con valore `"on"`; se non spuntata, `getParameter()` restituisce `null`

```jsp
        if (username == null || username.trim().isEmpty()) {
            errorMsg = "Inserisci il nome utente.";
        } else if (password == null || password.isEmpty()) {
            errorMsg = "Inserisci la password.";
        } else {
```

Validazione lato server. Anche se il browser fa validazione HTML5 (`required`), il server deve sempre rivalidare perché le richieste HTTP possono essere costruite manualmente (senza browser). `.trim()` rimuove gli spazi bianchi iniziali/finali.

```jsp
                PreparedStatement ps = conn.prepareStatement(
                    "SELECT id_utente, username, nome_visualizzato, password_hash FROM Utente " +
                    "WHERE username = ? AND attivo = TRUE");
                ps.setString(1, username.trim());
                ResultSet rs = ps.executeQuery();
```

Query per cercare l'utente per username. Nota: non cerca anche per password nella query SQL (sarebbe errato con l'hashing). Cerca solo per username e controlla `attivo = TRUE` per escludere account disabilitati.

```jsp
                if (rs.next()) {
                    String storedHash = rs.getString("password_hash");
                    int idUtente = rs.getInt("id_utente");
                    String nomeVisualizzato = rs.getString("nome_visualizzato");
                    String dbUsername = rs.getString("username");
```

Se l'utente esiste, recupera i suoi dati. `storedHash` contiene il valore salvato nel database, che ha la struttura: `[salt in hex 32 chars][hash SHA-256 in hex 64 chars]` = 96 caratteri totali.

---

### Verifica password con SHA-256 + Salt

```jsp
                     boolean passwordValida = false;
                     try {
                         String storedSaltHex = storedHash.substring(0, 32);
                         String storedHashHex = storedHash.substring(32);
```

Separa il salt dall'hash:
- I primi 32 caratteri (`substring(0, 32)`) sono il salt in formato esadecimale (rappresenta 16 byte)
- I restanti 64 caratteri (`substring(32)`) sono l'hash SHA-256 in esadecimale (rappresenta 32 byte)

```jsp
                         byte[] salt = new byte[16];
                         for (int i = 0; i < 32; i += 2) {
                             salt[i/2] = (byte) ((Character.digit(storedSaltHex.charAt(i), 16) << 4) 
                                                + Character.digit(storedSaltHex.charAt(i+1), 16));
                         }
```

Converte la stringa esadecimale del salt in un array di byte. Ogni byte è rappresentato da due caratteri hex (es. `"a3"` → byte `0xA3 = 163`). `Character.digit(c, 16)` converte un carattere hex nel suo valore numerico. `<< 4` sposta di 4 bit a sinistra (equivale a moltiplicare per 16, necessario per il nibble alto).

```jsp
                         MessageDigest md = MessageDigest.getInstance("SHA-256");
                         md.update(salt);
                         byte[] hash = md.digest(password.getBytes("UTF-8"));
```

Calcola SHA-256 sulla password inserita dall'utente, usando lo stesso salt del database:
1. `MessageDigest.getInstance("SHA-256")` crea un oggetto per calcolare SHA-256
2. `md.update(salt)` aggiunge il salt all'input dell'hash
3. `md.digest(password.getBytes("UTF-8"))` aggiunge la password e calcola l'hash finale

Il punto chiave: si usa lo **stesso salt** che fu usato quando l'utente si è registrato. Questo è fondamentale per l'hashing con salt: senza il salt, hash uguali indicherebbero password uguali (vulnerabile a rainbow table attack).

```jsp
                         StringBuilder hexString = new StringBuilder();
                         for (byte b : hash) {
                             String hex = Integer.toHexString(0xff & b);
                             if (hex.length() == 1) hexString.append('0');
                             hexString.append(hex);
                         }
                         
                         passwordValida = storedHashHex.equals(hexString.toString());
```

Converte l'array di byte dell'hash calcolato in stringa esadecimale e la confronta con l'hash memorizzato nel database. `0xff & b` converte il byte signed Java in un intero unsigned (i byte Java sono signed: vanno da -128 a 127). `if (hex.length() == 1) hexString.append('0')` aggiunge uno zero iniziale per i byte con valore < 16 (es. `0x0a` → `"0a"` non `"a"`).

```jsp
                     } catch (Exception hashEx) {
                         passwordValida = password.equals(storedHash);
                     }
```

Fallback di retrocompatibilità: se il calcolo dell'hash fallisce (per qualsiasi motivo), confronta la password direttamente con lo stored hash. Questo gestisce il caso (teorico) di account creati con un vecchio sistema senza hashing.

---

### Creazione sessione dopo login riuscito

```jsp
                    if (passwordValida) {
                        session.setAttribute("id_utente", idUtente);
                        session.setAttribute("nome_utente", nomeVisualizzato);
                        session.setAttribute("username", dbUsername);
                        session.setAttribute("login_time", new java.util.Date());
```

Salva nella sessione HTTP i dati dell'utente autenticato. Questi dati sono accessibili da qualsiasi JSP tramite `session.getAttribute(...)`.

```jsp
                        ps = conn.prepareStatement("UPDATE Utente SET ultimo_accesso = NOW() WHERE id_utente = ?");
                        ps.setInt(1, idUtente);
                        ps.executeUpdate();
```

Aggiorna il timestamp dell'ultimo accesso nel database. `NOW()` è una funzione MySQL che restituisce il datetime corrente.

---

### Gestione "Ricordami" (token persistente)

```jsp
                        if ("on".equals(rememberMe)) {
                            SecureRandom random = new SecureRandom();
                            byte[] tokenBytes = new byte[32];
                            random.nextBytes(tokenBytes);
                            StringBuilder tokenBuilder = new StringBuilder();
                            for (byte b : tokenBytes) {
                                String hex = Integer.toHexString(0xff & b);
                                if (hex.length() == 1) tokenBuilder.append('0');
                                tokenBuilder.append(hex);
                            }
                            String token = tokenBuilder.toString();
```

Se l'utente ha spuntato "Ricordami", genera un **token casuale sicuro**:
1. `SecureRandom` è un generatore di numeri pseudocasuali crittograficamente sicuro (ben diverso da `Math.random()`)
2. Genera 32 byte casuali (256 bit di entropia)
3. Li converte in 64 caratteri esadecimali → il token finale

```jsp
                            Calendar cal = Calendar.getInstance();
                            cal.add(Calendar.DAY_OF_MONTH, 30);
                            java.util.Date scadenza = cal.getTime();
```

Calcola la data di scadenza del token: oggi + 30 giorni.

```jsp
                            ps = conn.prepareStatement(
                                "INSERT INTO SessioneToken (id_utente, token, user_agent, ip_address, scade_il) " +
                                "VALUES (?, ?, ?, ?, ?)");
                            ps.setInt(1, idUtente);
                            ps.setString(2, token);
                            ps.setString(3, request.getHeader("User-Agent"));
                            ps.setString(4, request.getRemoteAddr());
                            ps.setTimestamp(5, new java.sql.Timestamp(scadenza.getTime()));
                            ps.executeUpdate();
```

Salva il token nel database con:
- `user_agent` → identificativo del browser (`Mozilla/5.0...`) — utile per sicurezza
- `ip_address` → indirizzo IP dell'utente — utile per sicurezza/audit
- `scade_il` → quando il token smette di essere valido

```jsp
                            Cookie rememberCookie = new Cookie("remember_token", token);
                            rememberCookie.setMaxAge(30 * 24 * 60 * 60);
                            rememberCookie.setPath("/");
                            rememberCookie.setHttpOnly(true);
                            rememberCookie.setSecure(request.isSecure());
                            response.addCookie(rememberCookie);
```

Crea e invia il cookie al browser:
- `setMaxAge(30 * 24 * 60 * 60)` → durata: 30 giorni in secondi (2.592.000 secondi)
- `setPath("/")` → valido per tutto il sito
- `setHttpOnly(true)` → il cookie non è accessibile via JavaScript (protezione XSS)
- `setSecure(request.isSecure())` → il cookie viene inviato solo su HTTPS se il sito usa HTTPS

---

### Sezione HTML

```html
<form method="POST" action="login.jsp" accept-charset="UTF-8">
```

Il form invia i dati a `login.jsp` stessa (la stessa pagina gestisce sia GET che POST). `accept-charset="UTF-8"` assicura che i caratteri speciali vengano inviati correttamente.

```html
<input type="text" id="username" name="username" required 
       autocomplete="username" maxlength="50"
       value="<%= request.getParameter("username") != null ? request.getParameter("username") : "" %>">
```

Il campo username. L'attributo `value` è pre-compilato con il valore precedentemente inserito: se l'utente sbaglia la password, il suo username non viene cancellato. Usa un'espressione JSP ternaria: se il parametro esiste lo usa, altrimenti usa stringa vuota.

```html
<% if (!errorMsg.isEmpty()) { %>
    <div class="alert alert-error animate-entrance">
        ...
        <%= errorMsg %>
    </div>
<% } %>
```

Mostra il messaggio di errore solo se non è vuoto. La classe CSS `animate-entrance` aggiunge un'animazione di comparsa. `<%= errorMsg %>` stampa il testo dell'errore.

---

### JavaScript inline – Toggle password

```javascript
function togglePassword() {
    var pwd = document.getElementById('password');
    var icon = document.getElementById('eyeIcon');
    if (pwd.type === 'password') {
        pwd.type = 'text';
        icon.innerHTML = '...'; // icona "occhio barrato"
    } else {
        pwd.type = 'password';
        icon.innerHTML = '...'; // icona "occhio"
    }
}
```

Funzione JavaScript che alterna il tipo del campo password tra `password` (caratteri nascosti) e `text` (caratteri visibili). Cambia anche l'icona SVG del pulsante.

---

## Flusso completo login.jsp

```
GET /login.jsp
├── Utente già loggato? → redirect home.jsp
├── Cookie remember_token valido nel DB? → crea sessione → redirect home.jsp
└── Mostra form HTML

POST /login.jsp
├── Validazione input (username e password non vuoti)
├── Query DB: cerca utente per username
├── Utente non trovato? → errorMsg = "credenziali errate"
├── Utente trovato:
│   ├── Ricostruisce hash SHA-256 con salt dal DB
│   ├── Hash corrisponde? → login OK
│   │   ├── Crea sessione (id_utente, nome, username)
│   │   ├── Aggiorna ultimo_accesso nel DB
│   │   ├── Ricordami spuntato? → genera token → salva in DB → invia cookie
│   │   └── Redirect home.jsp
│   └── Hash non corrisponde → errorMsg = "credenziali errate"
└── Rimostra form con errorMsg
```
