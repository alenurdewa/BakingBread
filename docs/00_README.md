# BakingBread — Documentazione Progetto

## Panoramica
BakingBread è una piattaforma web di condivisione ricette di cucina, costruita con **Java JSP** puro (nessun Servlet, nessun framework).

## Stack tecnologico
| Componente | Tecnologia |
|------------|-----------|
| Linguaggio backend | Java 11+ |
| Pagine web | JSP (JavaServer Pages) |
| Database | MySQL 8+ / MariaDB |
| Server | Apache Tomcat 9+ |
| CSS | Vanilla CSS con variabili custom |
| JavaScript | Vanilla JS (nessun framework) |

## Struttura del progetto
```
BakingBread-refactored/
├── src/java/com/bakingbread/
│   ├── model/          → Bean di dati (POJO con getter/setter)
│   │   ├── Ingrediente.java
│   │   ├── Passaggio.java
│   │   ├── Commento.java
│   │   ├── RicettaCard.java
│   │   ├── UtenteCard.java
│   │   └── MessaggioItem.java
│   └── util/           → Classi di utilità
│       ├── Db.java           (connessione database)
│       ├── FileStore.java    (upload file su disco)
│       └── UrlUtils.java     (risoluzione URL)
├── web/
│   ├── WEB-INF/
│   │   ├── web.xml           (configurazione Tomcat)
│   │   ├── lib/              (mysql-connector.jar)
│   │   └── sql/schema.sql    (schema database)
│   ├── css/                  (fogli di stile)
│   ├── js/                   (script JavaScript)
│   ├── media/                (svg, icone)
│   ├── uploads/              (cartella file caricati)
│   └── *.jsp                 (pagine dell'applicazione)
└── docs/                     (questa documentazione)
```

## Pagine JSP
| File | Descrizione |
|------|-------------|
| `login.jsp` | Accesso utente |
| `register.jsp` | Registrazione nuovo utente |
| `logout.jsp` | Disconnessione |
| `navbar.jsp` | Barra di navigazione (inclusa nelle altre) |
| `home.jsp` | Feed ricette con like e salvataggio |
| `profile.jsp` | Profilo utente con follow/unfollow |
| `impostazioni.jsp` | Modifica profilo e password |
| `crea_ricetta.jsp` | Creazione e modifica ricette |
| `dettaglio_ricetta.jsp` | Dettaglio ricetta e commenti |
| `collezioni.jsp` | Ricette salvate |
| `messaggi.jsp` | Chat privata tra utenti |
| `network.jsp` | Gestione follower/seguiti |
| `createDatabase.jsp` | Inizializzazione DB (solo setup) |
| `modifica_ricetta.jsp` | Redirect a crea_ricetta.jsp |

## Setup iniziale
1. Importare il progetto in NetBeans o IntelliJ.
2. Configurare la connessione MySQL in `Db.java` (host, user, password).
3. Avviare Tomcat.
4. Aprire `http://localhost:8080/BakingBread/createDatabase.jsp` per creare il DB.
5. Navigare a `http://localhost:8080/BakingBread/register.jsp` per il primo account.

## Convenzioni di codice
- **Nessun Servlet**: tutta la logica è nelle pagine JSP.
- **Solo array**: niente `List`, `ArrayList`, `Map`, `HashMap`.
- **Nessun operatore ternario**: solo `if-else` espliciti.
- **Commenti su ogni riga**: il codice è pensato per essere letto da studenti.
- **Pattern Array**: conta con `SELECT COUNT(*)`, crea array, poi popola.
