# 00 – Introduzione a JSP, Servlet e all'architettura del progetto BakingBread

---

## Cos'è una JSP (JavaServer Pages)?

Una **JSP** (JavaServer Pages) è un file di testo con estensione `.jsp` che il server web (in questo caso **Apache Tomcat**) trasforma automaticamente in una **Servlet Java** e poi esegue per produrre una risposta HTTP (quasi sempre una pagina HTML).

In pratica: scrivi un file che sembra HTML, ma puoi inserire dentro blocchi di **codice Java** che vengono eseguiti lato server prima che la pagina venga inviata al browser. Il browser non vede mai il codice Java: riceve solo l'HTML finale.

### Analogia semplice
Immagina un template di lettera con dei buchi (`[nome]`, `[data]`). La JSP è quel template: il server riempie i buchi con dati reali (dal database, dalla sessione…) e poi spedisce la lettera completa al browser.

---

## Cos'è una Servlet?

Una **Servlet** è una classe Java pura (estende `HttpServlet`) che riceve le richieste HTTP (GET o POST) e produce risposte. Non contiene HTML: è solo logica Java.

Nel progetto BakingBread le Servlet si occupano delle operazioni che **modificano dati** (salvare una ricetta, aggiornare il profilo, inserire un commento, seguire un utente), mentre le JSP si occupano di **mostrare** i dati.

---

## Come funziona il ciclo richiesta-risposta

```
Browser                      Tomcat (Server)
  │                               │
  │── GET /home.jsp ────────────► │
  │                               │ 1. Tomcat trova home.jsp
  │                               │ 2. La converte in Servlet Java (la prima volta)
  │                               │ 3. Esegue il codice Java dentro <% ... %>
  │                               │ 4. Interroga il database MySQL
  │                               │ 5. Costruisce l'HTML con i risultati
  │◄── HTML completo ─────────── │
  │                               │
  │── POST /recipe/save ────────► │
  │                               │ 1. Tomcat trova RecipeSaveServlet
  │                               │ 2. Chiama doPost()
  │                               │ 3. Salva la ricetta nel database
  │◄── Redirect a /dettaglio... ─ │
```

---

## Struttura del progetto BakingBread

```
BakingBread/
├── web/                          ← file accessibili dal browser
│   ├── *.jsp                     ← pagine JSP (viste)
│   ├── css/                      ← fogli di stile CSS
│   ├── js/                       ← file JavaScript lato client
│   ├── media/                    ← SVG, favicon
│   ├── uploads/                  ← immagini caricate dagli utenti
│   ├── META-INF/context.xml      ← configurazione contesto Tomcat
│   └── WEB-INF/
│       ├── web.xml               ← descrittore dell'applicazione
│       ├── lib/                  ← librerie JAR (driver MySQL)
│       └── sql/schema.sql        ← schema del database
└── src/java/com/bakingbread/
    ├── util/
    │   ├── Db.java               ← helper connessione database
    │   ├── FileStore.java        ← salvataggio file su disco
    │   └── UrlUtils.java         ← risoluzione URL relativi/assoluti
    └── web/
        ├── RecipeSaveServlet.java
        ├── CommentServlet.java
        ├── FollowServlet.java
        └── ProfileUpdateServlet.java
```

---

## Sintassi JSP – Guida completa

### 1. Direttive `<%@ ... %>`

Le **direttive** configurano come la JSP viene compilata. Si scrivono in cima al file.

```jsp
<%@ page contentType="text/html;charset=UTF-8" %>
```
- `page` → tipo di direttiva (riguarda la pagina corrente)
- `contentType="text/html;charset=UTF-8"` → dice al browser che la risposta è HTML in UTF-8

```jsp
<%@ page import="java.sql.*, java.util.*" %>
```
- `import` → importa classi Java (come `import` in un file .java normale)
- `java.sql.*` → importa tutto il pacchetto JDBC (Connection, PreparedStatement, ResultSet…)
- `java.util.*` → importa ArrayList, HashMap, Date, ecc.

---

### 2. Scriptlet `<% ... %>`

Un blocco di **codice Java** eseguito ogni volta che la pagina viene richiesta.

```jsp
<%
    String nome = "Mario";
    int eta = 30;
    if (eta >= 18) {
        out.println("Maggiorenne");
    }
%>
```

- Tutto quello che sta dentro `<% %>` è Java puro
- La variabile speciale `out` è uno `PrintWriter` che scrive nell'HTML di output
- Le variabili dichiarate qui dentro sopravvivono solo per la durata della richiesta corrente

**Regola importante**: dentro gli scriptlet puoi aprire blocchi `if`, `for`, `while` e poi chiuderli in un altro scriptlet separato, mettendo HTML nel mezzo:

```jsp
<% if (utente != null) { %>
    <p>Ciao, <%= utente %>!</p>
<% } else { %>
    <p>Ospite</p>
<% } %>
```

---

### 3. Espressioni `<%= ... %>`

Stampa il valore di un'espressione Java direttamente nell'HTML. È equivalente a `out.print(...)`.

```jsp
<p>Ciao, <%= nomeUtente %></p>
<p>Hai <%= numRicette %> ricette.</p>
```

**Attenzione**: non mettere il punto e virgola `;` dentro `<%= %>`.

---

### 4. Dichiarazioni `<%! ... %>`

Dichiara **metodi** o **variabili di classe** che appartengono alla Servlet generata. Vengono eseguiti una volta sola alla creazione della Servlet (non ad ogni richiesta).

```jsp
<%!
    private String esc(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;")
                    .replace("<", "&lt;")
                    .replace(">", "&gt;")
                    .replace("\"", "&quot;");
    }
%>
```

Questo dichiara un metodo `esc()` riutilizzabile in tutta la pagina per fare **HTML escaping** (protezione XSS).

---

### 5. Azioni JSP `<jsp:...>`

Le azioni JSP sono tag speciali che eseguono operazioni predefinite.

```jsp
<jsp:include page="navbar.jsp" />
```

Questo include il contenuto di `navbar.jsp` nella pagina corrente, come se il codice di navbar fosse scritto lì. È il meccanismo usato in BakingBread per la barra di navigazione condivisa.

---

### 6. Expression Language (EL) `${ ... }`

Sintassi semplificata per accedere a variabili senza scriptlet:

```jsp
${pageContext.request.contextPath}
```

- `pageContext` → oggetto che rappresenta il contesto della pagina
- `request` → la richiesta HTTP corrente
- `contextPath` → il percorso base dell'applicazione (es. `/BakingBread`)

Questo viene usato nei tag `<link>` e `<script>` per costruire URL corretti:

```html
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/global.css">
```

---

## Oggetti impliciti JSP

Nelle JSP sono sempre disponibili questi oggetti "magici" senza doverli dichiarare:

| Oggetto | Tipo Java | Cosa contiene |
|---------|-----------|---------------|
| `request` | `HttpServletRequest` | Dati della richiesta HTTP (parametri, header, cookie) |
| `response` | `HttpServletResponse` | Risposta da inviare al browser (header, redirect) |
| `session` | `HttpSession` | Dati della sessione utente (persiste tra più richieste) |
| `application` | `ServletContext` | Dati globali dell'applicazione (percorsi file, ecc.) |
| `out` | `JspWriter` | Stream di output per scrivere HTML |
| `pageContext` | `PageContext` | Accesso a tutti gli altri oggetti impliciti |

---

## La sessione HTTP

La **sessione** è un meccanismo che permette al server di ricordare l'utente tra una richiesta e l'altra. Il browser riceve un cookie chiamato `JSESSIONID` che identifica la sua sessione.

```jsp
// Leggere un valore dalla sessione
Integer idUtente = (Integer) session.getAttribute("id_utente");

// Scrivere nella sessione
session.setAttribute("id_utente", 42);

// Eliminare la sessione (logout)
session.invalidate();
```

In BakingBread, quando un utente fa login, il server salva nella sessione:
- `id_utente` → ID numerico dell'utente
- `nome_utente` → nome visualizzato
- `username` → username
- `avatar_url` → URL dell'avatar

Ogni JSP protetta controlla all'inizio se `session.getAttribute("id_utente")` è non-null.

---

## JDBC – Connessione al database

**JDBC** (Java Database Connectivity) è l'API standard Java per comunicare con database relazionali.

### Pattern tipico usato in BakingBread

```java
// 1. Carica il driver MySQL
Class.forName("com.mysql.cj.jdbc.Driver");

// 2. Apri connessione
Connection conn = DriverManager.getConnection(
    "jdbc:mysql://localhost:3306/bakingbread?useSSL=false", 
    "root", ""
);

// 3. Prepara la query (parametri con ? per sicurezza)
PreparedStatement ps = conn.prepareStatement(
    "SELECT * FROM Utente WHERE username = ?"
);
ps.setString(1, "mario"); // sostituisce il primo ?

// 4. Esegui la query
ResultSet rs = ps.executeQuery();

// 5. Leggi i risultati
while (rs.next()) {
    String nome = rs.getString("nome_visualizzato");
    int id = rs.getInt("id_utente");
}

// 6. Chiudi sempre le risorse
rs.close();
ps.close();
conn.close();
```

### Perché PreparedStatement?
Usare `PreparedStatement` con i `?` invece di concatenare stringhe previene le **SQL Injection**: un attacco in cui un utente malintenzionato inserisce SQL nel campo username o password per manipolare il database.

---

## Pattern di sicurezza comune nelle JSP

Ogni JSP protetta inizia con questo blocco:

```jsp
<%
    // Controlla se l'utente è loggato
    Integer idUtenteLoggato = (Integer) session.getAttribute("id_utente");
    if (idUtenteLoggato == null) {
        response.sendRedirect("login.jsp"); // reindirizza al login
        return; // FONDAMENTALE: ferma l'esecuzione del resto della pagina
    }
%>
```

Il `return` è cruciale: senza di esso, il codice continuerebbe ad eseguire anche dopo il redirect.

---

## Disabilitare la cache

```jsp
response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
response.setHeader("Pragma", "no-cache");
response.setDateHeader("Expires", 0);
```

Questi tre header HTTP istruiscono il browser a **non memorizzare in cache** la pagina. Questo è importante per pagine dinamiche come la home o il profilo: senza questi header, il browser potrebbe mostrare una versione vecchia della pagina dopo il logout o dopo modifiche ai dati.

---

## Come vengono registrate le Servlet (web.xml)

Il file `WEB-INF/web.xml` è il **descrittore dell'applicazione**. Dice a Tomcat quale URL corrisponde a quale Servlet:

```xml
<servlet>
    <servlet-name>RecipeSaveServlet</servlet-name>
    <servlet-class>com.bakingbread.web.RecipeSaveServlet</servlet-class>
</servlet>
<servlet-mapping>
    <servlet-name>RecipeSaveServlet</servlet-name>
    <url-pattern>/recipe/save</url-pattern>
</servlet-mapping>
```

Questo significa: quando arriva una richiesta a `/recipe/save`, Tomcat chiama `RecipeSaveServlet`.

---

## Flusso completo di BakingBread

```
Utente visita /home.jsp
    → home.jsp esegue query SQL sul database
    → Mostra le ricette come HTML

Utente clicca "Mi Piace" su una ricetta
    → Browser invia POST a home.jsp con parametri azione=mi piace, tipo=aggiungi, id=5
    → home.jsp esegue INSERT INTO MiPiace
    → Redirect a home.jsp (pattern Post-Redirect-Get)

Utente pubblica una ricetta
    → Browser invia POST a /recipe/save
    → RecipeSaveServlet.doPost() salva ricetta, ingredienti, passaggi in transazione
    → Redirect a /dettaglio_ricetta.jsp?id=...

Utente segue un altro utente
    → Browser invia POST a /profile/follow
    → FollowServlet.doPost() inserisce in tabella Seguito
    → Redirect alla pagina precedente
```

---

## Pattern Post-Redirect-Get (PRG)

Quasi tutte le operazioni in BakingBread seguono questo pattern:

1. **POST**: il browser invia un form con dati
2. Il server elabora i dati (salva nel DB)
3. **Redirect**: il server risponde con un redirect (codice HTTP 302)
4. **GET**: il browser esegue una nuova richiesta GET sulla pagina di destinazione

Questo evita il problema del "ricaricamento del form" (se l'utente preme F5 dopo aver inviato un form, senza PRG il browser rimanderebbe lo stesso POST, duplicando i dati).
