# 14 – `web.xml` e Architettura del Progetto

---

# `web.xml` — Spiegazione riga per riga

## Scopo del file
Il **descrittore di deployment** (`web.xml`) è il file di configurazione principale di un'applicazione web Java EE. Si trova in `WEB-INF/web.xml` e dice a Tomcat come deve comportarsi l'applicazione: quali Servlet registrare, quali URL gestiscono, timeout di sessione, pagine di errore.

---

## Analisi riga per riga

```xml
<?xml version="1.0" encoding="UTF-8"?>
<web-app xmlns="http://xmlns.jcp.org/xml/ns/javaee"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/javaee 
                             http://xmlns.jcp.org/xml/ns/javaee/web-app_3_1.xsd"
         version="3.1">
```

- `version="3.1"` → versione della specifica Servlet (3.1 = Java EE 7). Determina quali funzionalità sono disponibili.
- `xmlns` → namespace XML. Necessario per la validazione dello schema.

---

### Display name e welcome file

```xml
    <display-name>BakingBread</display-name>
    <welcome-file-list>
        <welcome-file>home.jsp</welcome-file>
    </welcome-file-list>
```

- `display-name` → nome dell'applicazione mostrato nella console di amministrazione di Tomcat.
- `welcome-file-list` → quando l'utente accede all'URL radice dell'app (es. `http://localhost:8080/BakingBread/`), Tomcat cerca e mostra questo file automaticamente. Equivale all'`index.html` in Apache.

---

### Servlet JSP (Jasper)

```xml
    <servlet>
        <servlet-name>jsp</servlet-name>
        <servlet-class>org.apache.jasper.servlet.JspServlet</servlet-class>
        <init-param><param-name>fork</param-name><param-value>false</param-value></init-param>
        <init-param><param-name>xpoweredBy</param-name><param-value>false</param-value></init-param>
        <load-on-startup>3</load-on-startup>
    </servlet>
    <servlet-mapping><servlet-name>jsp</servlet-name><url-pattern>*.jsp</url-pattern></servlet-mapping>
    <servlet-mapping><servlet-name>jsp</servlet-name><url-pattern>*.jspx</url-pattern></servlet-mapping>
```

Questa è la Servlet JSP di Tomcat (Jasper). Già inclusa in Tomcat ma esplicitata qui per i parametri aggiuntivi:
- `fork=false` → compila le JSP nel processo JVM corrente (non in un processo separato). Più efficiente.
- `xpoweredBy=false` → non aggiunge l'header HTTP `X-Powered-By: JSP/2.3` nelle risposte. Buona pratica di sicurezza: non rivela la tecnologia server.
- `load-on-startup=3` → carica questa Servlet al 3° posto all'avvio del server (prima che arrivi una richiesta). Il numero indica la priorità; le Servlet con numero minore si caricano prima.

Il mapping `*.jsp` e `*.jspx` → qualsiasi URL che termina con `.jsp` o `.jspx` viene gestito da questa Servlet.

---

### Registrazione Servlet personalizzate

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

Registra `RecipeSaveServlet` all'URL `/recipe/save`. La struttura è la stessa per tutte e quattro le Servlet:

| Servlet | URL Pattern |
|---------|-------------|
| `RecipeSaveServlet` | `/recipe/save` |
| `ProfileUpdateServlet` | `/profile/update` |
| `CommentServlet` | `/recipe/comment` |
| `FollowServlet` | `/profile/follow` |

**Nota**: le Servlet sono anche annotate con `@WebServlet` nel codice Java. Quando entrambi sono presenti, `web.xml` ha la precedenza secondo la specifica Servlet 3.0+.

---

### Configurazione sessione

```xml
    <session-config>
        <session-timeout>30</session-timeout>
    </session-config>
```

Timeout della sessione HTTP in **minuti**. Dopo 30 minuti di inattività, la sessione viene invalidata automaticamente dal server. Se l'utente torna dopo 30 minuti, troverà una sessione vuota e dovrà riloggare (o il cookie "ricordami" creerà automaticamente una nuova sessione).

---

### Pagine di errore

```xml
    <error-page>
        <error-code>404</error-code>
        <location>/home.jsp</location>
    </error-page>
    <error-page>
        <error-code>500</error-code>
        <location>/home.jsp</location>
    </error-page>
```

Configura il comportamento per gli errori HTTP:
- **404 (Not Found)** → URL non trovato → reindirizza a `home.jsp`
- **500 (Internal Server Error)** → errore del server (eccezione non gestita) → reindirizza a `home.jsp`

In produzione si avrebbero pagine di errore dedicate e più informative per l'utente. Redirigere a `home.jsp` per tutti gli errori è semplice ma non ideale (non informa l'utente dell'errore specifico).

---

---

# Architettura complessiva del progetto

## Diagramma architetturale

```
┌─────────────────────────────────────────────────────────────┐
│                         BROWSER                             │
│  HTTP GET/POST ────────────────────────────────────────     │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                    APACHE TOMCAT                             │
│                                                             │
│  ┌─────────────────┐    ┌───────────────────────────────┐   │
│  │  JSP Pages      │    │  Servlet Classes              │   │
│  │  (Vista + Logic)│    │  (Solo Action/Logic)          │   │
│  ├─────────────────┤    ├───────────────────────────────┤   │
│  │ home.jsp        │    │ RecipeSaveServlet             │   │
│  │ login.jsp       │    │   ↕ /recipe/save              │   │
│  │ register.jsp    │    │ ProfileUpdateServlet          │   │
│  │ profile.jsp     │    │   ↕ /profile/update           │   │
│  │ crea_ricetta.jsp│    │ CommentServlet                │   │
│  │ dettaglio_*.jsp │    │   ↕ /recipe/comment           │   │
│  │ messaggi.jsp    │    │ FollowServlet                 │   │
│  │ network.jsp     │    │   ↕ /profile/follow           │   │
│  │ ...             │    └───────────────────────────────┘   │
│  └────────┬────────┘              │                         │
│           │                       │                         │
│           ▼                       ▼                         │
│  ┌─────────────────────────────────────────────────┐        │
│  │           Utility Classes                        │        │
│  │  Db.java · FileStore.java · UrlUtils.java        │        │
│  └──────────────────────┬──────────────────────────┘        │
└─────────────────────────┼────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                    MySQL Database                            │
│                                                             │
│  Utente · Ricetta · Passaggio · Ingrediente                 │
│  RicettaIngrediente · Commento · Valutazione                │
│  MiPiace · Seguito · Messaggio · Collezione                 │
│  SessioneToken · RicettaSalvata                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Pattern MVC parziale

BakingBread implementa un **MVC ibrido**:

| Layer | Componente | Responsabilità |
|-------|-----------|----------------|
| **Model** | Tabelle MySQL | Dati persistenti |
| **View** | JSP (parte HTML) | Presentazione |
| **Controller** | JSP (parte Java) + Servlet | Logica di business |

Le JSP violano una separazione MVC pura (mescolano vista e logica), ma questo è il pattern classico "JSP Model 1" usato in progetti didattici e applicazioni semplici. Per applicazioni più grandi si userebbe Spring MVC o Jakarta EE con JSP solo come view.

---

## Flussi principali

### Flusso GET (lettura dati)
```
Browser → GET /home.jsp
         → Tomcat esegue home.jsp
         → home.jsp apre connessione DB
         → Query SELECT
         → Genera HTML con i dati
         → Chiude connessione DB
         → Risponde con HTML completo
```

### Flusso POST → Redirect → GET (modifica dati)
```
Browser → POST /recipe/save (form data + file)
         → Tomcat chiama RecipeSaveServlet.doPost()
         → Valida dati, salva file, salva DB (transazione)
         → Risponde con HTTP 302 Redirect → /dettaglio_ricetta.jsp?id=X
         → Browser esegue GET /dettaglio_ricetta.jsp?id=X
         → JSP carica e mostra la ricetta salvata
```

---

## File di configurazione del progetto

| File | Posizione | Scopo |
|------|-----------|-------|
| `web.xml` | `WEB-INF/web.xml` | Configurazione Servlet, URL mapping, sessioni, errori |
| `context.xml` | `META-INF/context.xml` | Configurazione del contesto Tomcat (JNDI, datasource) |
| `schema.sql` | `WEB-INF/sql/schema.sql` | Schema del database |
| `build.xml` | `BakingBread/build.xml` | Script Ant per build/deploy |
| `project.properties` | `nbproject/project.properties` | Configurazione NetBeans IDE |
| `MANIFEST.MF` | `src/conf/MANIFEST.MF` | Manifest del JAR/WAR |
