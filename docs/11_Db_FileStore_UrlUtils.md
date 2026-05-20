# 11 – Classi di utilità: `Db.java`, `FileStore.java`, `UrlUtils.java`

---

# `Db.java` — Spiegazione riga per riga

## Scopo del file
Classe helper centralizzata per aprire connessioni al database MySQL. Invece di ripetere `Class.forName(...)` e `DriverManager.getConnection(...)` in ogni Servlet, si chiama un unico metodo statico `Db.getConnection()`.

---

## Analisi riga per riga

```java
package com.bakingbread.util;
```

Package `util` (utilities): classi di supporto riutilizzabili in tutto il progetto.

```java
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
```

Importa le sole classi JDBC necessarie per aprire una connessione (non le classi per query o result set, che appartengono a chi usa la connessione).

```java
public final class Db {
```

`final class` → questa classe non può essere estesa (non ha sottoclassi). Scelta di design: una classe utility non ha senso come base di ereditarietà.

```java
    private static final String URL = "jdbc:mysql://localhost:3306/bakingbread?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true";
    private static final String USER = "root";
    private static final String PASS = "";
```

Costanti `private static final`:
- `private` → non accessibili dall'esterno
- `static` → appartengono alla classe, non alle istanze
- `final` → il valore non cambia mai dopo l'assegnazione (immutabili)

La stringa di connessione include:
- `useSSL=false` → disabilita SSL (solo per sviluppo locale)
- `serverTimezone=UTC` → evita problemi di conversione timezone tra Java e MySQL
- `allowPublicKeyRetrieval=true` → necessario per MySQL 8+ senza SSL per l'autenticazione

**Nota di sicurezza**: in produzione le credenziali non andrebbero hardcoded nel codice sorgente. Si userebbero variabili d'ambiente, file di configurazione esterni o un database di secrets.

```java
    private Db() {}
```

**Costruttore privato**: impedisce l'istanziazione con `new Db()`. Poiché tutti i metodi sono statici, non ha senso creare oggetti di questa classe. Questo è il pattern **Utility Class**.

```java
    public static Connection getConnection() throws SQLException, ClassNotFoundException {
        Class.forName("com.mysql.cj.jdbc.Driver");
        return DriverManager.getConnection(URL, USER, PASS);
    }
```

Unico metodo pubblico. `throws SQLException, ClassNotFoundException` → i chiamanti devono gestire queste eccezioni (checked exceptions in Java).

`Class.forName("com.mysql.cj.jdbc.Driver")` → carica dinamicamente il driver JDBC MySQL in memoria. Nelle versioni recenti di Java (9+) con JDBC 4.0+, questo è tecnicamente superfluo (il driver si registra automaticamente), ma è buona pratica mantenerlo per chiarezza e compatibilità.

`DriverManager.getConnection(URL, USER, PASS)` → apre una nuova connessione al database. **Ogni chiamata crea una nuova connessione**. In produzione si userebbe un connection pool (HikariCP, c3p0) per riutilizzare connessioni e non aprirne una per ogni richiesta.

---

## Perché usare questa classe?

**Prima** (codice ripetuto in ogni Servlet):
```java
Class.forName("com.mysql.cj.jdbc.Driver");
Connection conn = DriverManager.getConnection(
    "jdbc:mysql://localhost:3306/bakingbread?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true",
    "root", ""
);
```

**Dopo** (con Db.java):
```java
Connection conn = Db.getConnection();
```

Vantaggio: se cambia la password o l'URL del database, si modifica un solo file.

---

---

# `FileStore.java` — Spiegazione riga per riga

## Scopo del file
Classe helper per salvare file caricati dal browser (avatar, immagini ricette) sul filesystem del server in modo sicuro.

---

## Analisi riga per riga

```java
public final class FileStore {
    private FileStore() {}
```

Stessa struttura di `Db`: classe finale non istanziabile con costruttore privato.

---

### Firma del metodo

```java
    public static String savePart(Part part, ServletContext context, String folderName, String prefix) throws IOException {
```

Parametri:
- `Part part` → la parte multipart del form (il file caricato)
- `ServletContext context` → contesto del servlet (serve per trovare il percorso fisico sul server)
- `String folderName` → sottocartella di destinazione (`"avatars"` o `"recipes"`)
- `String prefix` → prefisso per il nome del file (es. `"avatar_42"`, `"ricetta_5"`)

Ritorna la path relativa del file salvato (es. `"/uploads/avatars/avatar_42_1234567890_foto.jpg"`).

---

### Validazione input

```java
        if (part == null || part.getSize() <= 0) {
            return null;
        }

        String submitted = part.getSubmittedFileName();
        if (submitted == null || submitted.trim().isEmpty()) {
            return null;
        }
```

Protezione contro:
- `part == null` → nessun file caricato
- `part.getSize() <= 0` → file vuoto (0 byte)
- `submitted == null` → nessun nome file (improbabile ma possibile)

Se una di queste condizioni si verifica, ritorna `null` (il chiamante usa l'immagine attuale).

---

### Sanitizzazione del nome file

```java
        String sanitized = submitted.replaceAll("[\\\\/]+", "_")
                                    .replaceAll("[^a-zA-Z0-9._-]", "_");
        String storedName = prefix + "_" + System.currentTimeMillis() + "_" + sanitized;
```

**Sanitizzazione del nome file** — operazione di sicurezza critica:

1. `replaceAll("[\\\\/]+", "_")` → sostituisce slash (`/`) e backslash (`\`) con underscore. Un nome come `"../../etc/passwd"` diventerebbe `"......etc_passwd"` → **path traversal prevention**
2. `replaceAll("[^a-zA-Z0-9._-]", "_")` → sostituisce qualsiasi carattere che non sia alfanumerico, punto, underscore o trattino → elimina spazi, caratteri speciali, caratteri Unicode pericolosi

`System.currentTimeMillis()` → timestamp in millisecondi (es. `1714000000000`). Aggiunge unicità al nome file: anche se due utenti caricano un file con lo stesso nome, non si sovrascrivono.

Esempio finale: `"avatar_42_1714000000000_mia_foto.jpg"` — garantisce unicità e sicurezza.

---

### Determinazione del percorso fisico

```java
        String uploadBase = context.getRealPath("/uploads");
        if (uploadBase == null) {
            uploadBase = context.getRealPath("/");
        }
        if (uploadBase == null) {
            throw new IOException("Impossibile risolvere il percorso degli upload.");
        }
```

`context.getRealPath("/uploads")` → converte il path web relativo `/uploads` nel path assoluto sul filesystem (es. `"/var/lib/tomcat/webapps/BakingBread/uploads"`). Può ritornare `null` in alcuni ambienti Tomcat (es. quando l'app è deployata come WAR senza decompressione). Il fallback usa la root della web app.

```java
        File targetDir = new File(uploadBase, folderName);
        if (!targetDir.exists() && !targetDir.mkdirs()) {
            throw new IOException("Impossibile creare la cartella upload: " + targetDir.getAbsolutePath());
        }
```

`new File(uploadBase, folderName)` → costruisce il path della cartella destinazione (es. `/var/.../uploads/avatars`). `!targetDir.exists() && !targetDir.mkdirs()` → se la cartella non esiste, prova a crearla (incluse eventuali cartelle genitori). Se la creazione fallisce (permessi), lancia eccezione.

---

### Scrittura del file

```java
        File targetFile = new File(targetDir, storedName);
        try (InputStream in = part.getInputStream(); FileOutputStream out = new FileOutputStream(targetFile)) {
            byte[] buffer = new byte[8192];
            int read;
            while ((read = in.read(buffer)) != -1) {
                out.write(buffer, 0, read);
            }
        }
```

Copia il file dall'input stream del form all'output stream sul disco. Buffer di 8192 byte (8 KB) → equilibrio efficiente tra uso di memoria e numero di operazioni I/O. `in.read(buffer)` → legge fino a 8 KB alla volta; ritorna -1 quando il file è finito. `out.write(buffer, 0, read)` → scrive solo i byte effettivamente letti (importante: l'ultimo chunk potrebbe essere più piccolo del buffer).

```java
        return "/uploads/" + folderName + "/" + storedName;
```

Ritorna il path relativo del file, che viene poi anteposto al `contextPath` dai chiamanti per costruire l'URL completo accessibile dal browser.

---

---

# `UrlUtils.java` — Spiegazione riga per riga

## Scopo del file
Classe helper per normalizzare gli URL delle immagini. Gestisce tre casi: URL già assoluti, path relative dell'app, e path che iniziano con `/` senza il context path.

---

## Analisi riga per riga

```java
public final class UrlUtils {
    private UrlUtils() {}

    public static String resolve(String contextPath, String rawUrl) {
        if (rawUrl == null) {
            return "";
        }
        String value = rawUrl.trim();
        if (value.isEmpty()) {
            return "";
        }
```

Gestisce i casi null/vuoto restituendo stringa vuota invece di null (più sicuro da usare nell'HTML).

```java
        if (value.startsWith("http://") || value.startsWith("https://") 
                || value.startsWith("data:") || value.startsWith("blob:")) {
            return value;
        }
```

Se l'URL è già assoluto (include il protocollo), lo ritorna immutato. Gestisce:
- `http://...` e `https://...` → URL web normali
- `data:image/...` → immagini embedded in base64
- `blob:...` → URL di oggetti blob (creati via JS)

```java
        if (contextPath == null) {
            contextPath = "";
        }
        if (!contextPath.isEmpty() && value.startsWith(contextPath + "/")) {
            return value;
        }
```

Se il path inizia già con il contextPath (es. `/BakingBread/uploads/...`), lo ritorna come è senza duplicare il prefisso.

```java
        if (value.startsWith("/")) {
            return contextPath + value;
        }
        return contextPath + "/" + value;
    }
}
```

- Path che inizia con `/` (es. `/uploads/avatars/...`) → prepende il contextPath
- Path senza `/` iniziale (es. `uploads/avatars/...`) → prepende contextPath + `/`

**Perché serve questa classe?** Il problema: le immagini vengono salvate nel DB come `/uploads/avatars/file.jpg` ma se l'applicazione è deployata sotto un contesto (es. `/BakingBread`), l'URL corretto nel browser è `/BakingBread/uploads/avatars/file.jpg`. `UrlUtils.resolve(ctx, url)` aggiunge automaticamente il prefisso corretto.

### Tabella esempi

| Input `rawUrl` | `contextPath` | Output |
|---|---|---|
| `null` | qualsiasi | `""` |
| `""` | qualsiasi | `""` |
| `"https://example.com/img.jpg"` | `/BakingBread` | `"https://example.com/img.jpg"` |
| `"/uploads/avatars/img.jpg"` | `/BakingBread` | `"/BakingBread/uploads/avatars/img.jpg"` |
| `"/BakingBread/uploads/img.jpg"` | `/BakingBread` | `"/BakingBread/uploads/img.jpg"` (no duplice) |
| `"uploads/img.jpg"` | `/BakingBread` | `"/BakingBread/uploads/img.jpg"` |
| `"/uploads/img.jpg"` | `""` (root) | `"/uploads/img.jpg"` |
