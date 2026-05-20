# 02 – `register.jsp` — Spiegazione riga per riga

## Scopo del file
Gestisce la registrazione di nuovi utenti. Mostra il form di registrazione e, quando inviato via POST, valida i dati, genera un hash sicuro della password e inserisce il nuovo utente nel database.

---

## Struttura generale

```
register.jsp
├── [Blocco Java - SCRIPTLET]
│   ├── Anti-cache headers
│   ├── Controllo se già loggato → redirect home
│   ├── Parametri DB
│   └── Gestione POST
│       ├── Lettura parametri form
│       ├── Validazione (username, email, password, conferma)
│       ├── Controllo unicità username/email nel DB
│       ├── Generazione salt casuale (16 byte)
│       ├── Calcolo hash SHA-256 della password + salt
│       └── INSERT INTO Utente
└── [HTML]
    ├── Form registrazione
    └── JavaScript (toggle visibilità password)
```

---

## Analisi riga per riga

### Direttive

```jsp
<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.sql.*, java.security.*, java.util.*" %>
```

- `java.sql.*` → classi per il database
- `java.security.*` → `MessageDigest` (SHA-256), `SecureRandom` (generatore casuale sicuro)
- `java.util.*` → classi di utilità Java

---

### Anti-cache e controllo sessione

```jsp
    response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);
```

Impedisce al browser di memorizzare in cache la pagina di registrazione. Vedi introduzione per i dettagli.

```jsp
    String errorMsg = "";
    String successMsg = "";
    
    Integer idUtenteLoggato = (Integer) session.getAttribute("id_utente");
    if (idUtenteLoggato != null) {
        response.sendRedirect("home.jsp");
        return;
    }
```

Se l'utente è già autenticato, non ha senso registrarsi di nuovo: viene rimandato alla home.

---

### Parametri di connessione al database

```jsp
    String dbUrl = "jdbc:mysql://localhost:3306/bakingbread?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true";
    String dbUser = "root";
    String dbPass = "";
```

Rispetto a `login.jsp`, questa stringa di connessione ha due parametri aggiuntivi:
- `serverTimezone=UTC` → risolve problemi di timezone con alcune versioni del driver MySQL
- `allowPublicKeyRetrieval=true` → necessario per autenticazione con MySQL 8+ quando non si usa SSL

---

### Blocco POST

```jsp
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String username = request.getParameter("username");
        String email = request.getParameter("email");
        String password = request.getParameter("password");
        String confermaPassword = request.getParameter("conferma_password");
```

Legge i quattro campi del form: username, email, password e conferma password.

---

### Validazione a cascata (else-if chain)

```jsp
        if (username == null || username.trim().isEmpty()) {
            errorMsg = "Inserisci il nome utente.";
        } else if (username.length() < 3 || username.length() > 50) {
            errorMsg = "Il nome utente deve essere tra 3 e 50 caratteri.";
        } else if (!username.matches("^[a-zA-Z0-9_]+$")) {
            errorMsg = "Il nome utente può contenere solo lettere, numeri e underscore.";
        } else if (email == null || email.trim().isEmpty()) {
            errorMsg = "Inserisci l'indirizzo email.";
        } else if (!email.matches("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+$")) {
            errorMsg = "Inserisci un indirizzo email valido.";
        } else if (password == null || password.length() < 8) {
            errorMsg = "La password deve essere di almeno 8 caratteri.";
        } else if (!password.equals(confermaPassword)) {
            errorMsg = "Le password non corrispondono.";
        } else {
```

Catena di validazioni lato server:

1. **username non vuoto** → controllo base
2. **username tra 3 e 50 caratteri** → lunghezza ragionevole
3. **username solo caratteri permessi**: `^[a-zA-Z0-9_]+$` è un'espressione regolare (regex):
   - `^` → inizio stringa
   - `[a-zA-Z0-9_]` → qualsiasi lettera (maiuscola o minuscola), cifra o underscore
   - `+` → uno o più caratteri
   - `$` → fine stringa
   - `!username.matches(...)` → nega: se NON corrisponde → errore
4. **email non vuota** → controllo base
5. **email formato valido**: regex semplificata per email
6. **password almeno 8 caratteri** → sicurezza minima
7. **password e conferma uguali** → `.equals()` confronta i contenuti (non i riferimenti)

---

### Logica di registrazione (blocco else)

```jsp
            Connection conn = null;
            PreparedStatement ps = null;
            ResultSet rs = null;
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
```

Dichiarate fuori dal try per essere accessibili nel finally. `Class.forName` carica il driver MySQL, `DriverManager.getConnection` apre la connessione al database.

---

### Controllo unicità username e email

```jsp
                ps = conn.prepareStatement("SELECT id_utente FROM Utente WHERE username = ? OR email = ?");
                ps.setString(1, username.trim());
                ps.setString(2, email.trim().toLowerCase());
                rs = ps.executeQuery();
                
                if (rs.next()) {
                    errorMsg = "Nome utente o email già in uso.";
                } else {
```

Prima di inserire, controlla se esiste già un utente con lo stesso username **oppure** la stessa email. La condizione `OR` significa che basta uno dei due per bloccare la registrazione. `email.trim().toLowerCase()` normalizza l'email (rende "Mario@GMAIL.com" uguale a "mario@gmail.com").

---

### Generazione Salt casuale

```jsp
                    SecureRandom random = new SecureRandom();
                    byte[] salt = new byte[16];
                    random.nextBytes(salt);
                    
                    StringBuilder saltHex = new StringBuilder();
                    for (byte b : salt) {
                        String hex = Integer.toHexString(0xff & b);
                        if (hex.length() == 1) saltHex.append('0');
                        saltHex.append(hex);
                    }
```

**Perché il salt?** Senza salt, due utenti con la stessa password avrebbero lo stesso hash. Il salt è un valore casuale unico per ogni utente che viene "mischiato" con la password prima di fare l'hash. In questo modo, anche se due utenti hanno la stessa password, i loro hash saranno diversi.

- `SecureRandom` → generatore crittograficamente sicuro (NON usare `Math.random()` per la sicurezza)
- `new byte[16]` → 16 byte = 128 bit di entropia per il salt
- `random.nextBytes(salt)` → riempie l'array con byte casuali
- Il ciclo converte i byte in stringa esadecimale (32 caratteri)
- `0xff & b` converte il byte signed Java (-128..127) in intero unsigned (0..255) prima della conversione hex
- Il padding con `'0'` assicura che ogni byte produca esattamente 2 caratteri (es. `0x0a` → `"0a"`)

---

### Calcolo Hash SHA-256

```jsp
                    MessageDigest md = MessageDigest.getInstance("SHA-256");
                    md.update(salt);
                    byte[] hash = md.digest(password.getBytes("UTF-8"));
                    
                    StringBuilder hashHex = new StringBuilder();
                    for (byte b : hash) {
                        String hex = Integer.toHexString(0xff & b);
                        if (hex.length() == 1) hashHex.append('0');
                        hashHex.append(hex);
                    }
                    
                    String passwordHash = saltHex.toString() + hashHex.toString();
```

1. `MessageDigest.getInstance("SHA-256")` → crea l'engine di hashing SHA-256
2. `md.update(salt)` → aggiunge il salt come input
3. `md.digest(password.getBytes("UTF-8"))` → aggiunge la password e calcola l'hash finale (32 byte = 256 bit)
4. La conversione hex produce 64 caratteri per l'hash
5. **Struttura finale**: `passwordHash` = salt (32 chars) + hash (64 chars) = **96 caratteri** totali

Questa stringa di 96 caratteri viene salvata nel campo `password_hash VARCHAR(128)` del database.

**Perché SHA-256 invece di bcrypt?** SHA-256 è più veloce ma meno sicuro di bcrypt/Argon2 per le password. In produzione si userebbero algoritmi più lenti appositamente. Per un progetto didattico, SHA-256 + salt è accettabile.

---

### Inserimento nel database

```jsp
                    ps.close(); 
                    ps = conn.prepareStatement(
                        "INSERT INTO Utente (username, email, password_hash, nome_visualizzato, attivo) " +
                        "VALUES (?, ?, ?, ?, TRUE)");
                    ps.setString(1, username.trim());
                    ps.setString(2, email.trim().toLowerCase());
                    ps.setString(3, passwordHash);
                    ps.setString(4, username.trim());
                    
                    if (ps.executeUpdate() > 0) {
                        successMsg = "Account creato con successo! Ora puoi <a href='login.jsp'>accedere</a>.";
                    }
```

- `ps.close()` → chiude il PreparedStatement precedente prima di crearne uno nuovo
- `nome_visualizzato` viene impostato uguale a `username` come valore di default
- `attivo = TRUE` → l'account è attivo subito (senza verifica email)
- `ps.executeUpdate()` → ritorna il numero di righe inserite; se > 0 l'inserimento è riuscito
- `successMsg` contiene HTML (il link `<a href>`) — nota: non è escaped, ma il messaggio è hardcoded (non input utente) quindi è sicuro

---

### Gestione eccezioni

```jsp
            } catch (ClassNotFoundException e) {
                errorMsg = "Errore critico: Driver JDBC non trovato. Controlla WEB-INF/lib.";
            } catch (SQLException e) {
                errorMsg = "Errore Database: " + e.getMessage();
            } catch (Exception e) {
                errorMsg = "Errore imprevisto: " + e.getMessage();
            } finally {
                if (rs != null) try { rs.close(); } catch (Exception e) {}
                if (ps != null) try { ps.close(); } catch (Exception e) {}
                if (conn != null) try { conn.close(); } catch (Exception e) {}
            }
```

Tre catch distinti per errori specifici:
- `ClassNotFoundException` → il file JAR del driver MySQL non è in `WEB-INF/lib/`
- `SQLException` → errori del database (connessione rifiutata, query errata, vincolo violato)
- `Exception` → qualsiasi altro errore imprevisto

Il blocco `finally` **chiude sempre** le risorse, anche se c'è un'eccezione. Ogni `close()` è in un try-catch separato per evitare che un'eccezione durante la chiusura di `rs` impedisca la chiusura di `ps` e `conn`. Questo pattern evita i **resource leak** (connessioni al database che rimangono aperte).

---

### HTML – Form di registrazione

```html
<form method="POST" action="register.jsp" accept-charset="UTF-8">
    <div class="form-group">
        <label for="username">Nome utente</label>
        <input type="text" id="username" name="username" required 
               autocomplete="username" maxlength="50" pattern="[a-zA-Z0-9_]+"
               value="<%= (request.getParameter("username") != null) ? request.getParameter("username") : "" %>">
        <small class="text-muted" style="font-size:11px;">Solo lettere, numeri e underscore (_)</small>
    </div>
```

- `required` → validazione HTML5 client-side (il server rivalida comunque)
- `autocomplete="username"` → suggerisce al browser/gestore password il tipo di campo
- `pattern="[a-zA-Z0-9_]+"` → validazione HTML5 con regex (stessa logica del server)
- `value="<%= ... %>"` → ripopola il campo se il form viene rinviato dopo un errore (l'utente non deve riscrivere il suo username)

```html
<button type="button" class="password-toggle" onclick="togglePassword('password')">
    <svg id="eyeIcon1" ...>...</svg>
</button>
```

Pulsante per mostrare/nascondere la password. Non è `type="submit"` (altrimenti invierebbe il form). Chiama `togglePassword('password')` con l'ID del campo come argomento.

```html
<% if (!errorMsg.isEmpty()) { %>
    <div class="alert alert-error">
        ...
        <%= errorMsg %>
    </div>
<% } %>

<% if (!successMsg.isEmpty()) { %>
    <div class="alert alert-success">
        ...
        <%= successMsg %>
    </div>
<% } %>
```

Mostra il blocco di errore o successo solo se la variabile non è vuota. Vengono mostrati entrambi i blocchi condizionalmente: in pratica solo uno alla volta sarà non-vuoto.

---

### JavaScript per toggle password

```javascript
function togglePassword(inputId) {
    var input = document.getElementById(inputId);
    if (input.type === 'password') {
        input.type = 'text';
    } else {
        input.type = 'password';
    }
}
```

Funzione generica che riceve l'ID del campo da alternare. Può essere chiamata su entrambi i campi password (password e conferma_password) con lo stesso codice.

---

## Flusso completo register.jsp

```
GET /register.jsp
├── Utente già loggato? → redirect home.jsp
└── Mostra form HTML vuoto

POST /register.jsp
├── Legge parametri: username, email, password, conferma_password
├── Validazione in cascata:
│   ├── username vuoto? → errore
│   ├── username lunghezza 3-50? → errore
│   ├── username solo [a-zA-Z0-9_]? → errore
│   ├── email vuota? → errore
│   ├── email formato valido? → errore
│   ├── password < 8 caratteri? → errore
│   └── password ≠ conferma? → errore
├── Se validazione OK:
│   ├── Apre connessione DB
│   ├── Cerca username O email già esistenti
│   │   ├── Trovati? → errorMsg = "già in uso"
│   │   └── Non trovati:
│   │       ├── Genera 16 byte salt casuali (SecureRandom)
│   │       ├── Calcola SHA-256(salt + password)
│   │       ├── Concatena salt_hex + hash_hex (96 chars)
│   │       ├── INSERT INTO Utente(username, email, password_hash, ...)
│   │       └── successMsg = "Account creato!"
│   └── Finally: chiude sempre rs, ps, conn
└── Rimostra form con errorMsg o successMsg
```

---

## Differenza tra questo approccio e quello "professionale"

In produzione si userebbero:
- **BCrypt** o **Argon2** invece di SHA-256 (sono volutamente lenti, più resistenti agli attacchi brute-force)
- **Verifica email** prima di attivare l'account
- **Rate limiting** (limite di tentativi di registrazione per IP)
- **CAPTCHA** per prevenire registrazioni automatiche
- Un layer di servizi separato dalla JSP (architettura MVC più pulita)
