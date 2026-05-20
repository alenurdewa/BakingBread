# 13 – `schema.sql` — Spiegazione riga per riga

## Scopo del file
Script SQL che crea il database `bakingbread` da zero con tutte le tabelle, indici, vincoli, viste e relazioni. Va eseguito una volta sola (tramite `createDatabase.jsp` o direttamente in MySQL).

---

## Concetti SQL fondamentali usati

Prima di analizzare riga per riga, ecco i concetti chiave:

- **PRIMARY KEY**: identificatore univoco di ogni riga. MySQL crea automaticamente un indice su di essa.
- **FOREIGN KEY**: campo che fa riferimento alla PRIMARY KEY di un'altra tabella. Garantisce l'integrità referenziale (non puoi inserire un commento con `id_ricetta` che non esiste).
- **INDEX**: struttura dati aggiuntiva che velocizza le query di ricerca su una colonna.
- **UNIQUE KEY**: vincolo che impedisce valori duplicati in una colonna (come PRIMARY KEY ma può essere NULL e ci possono essere più UNIQUE KEY per tabella).
- **ON DELETE CASCADE**: quando si elimina una riga, elimina automaticamente tutte le righe correlate nelle tabelle figlie.
- **ENGINE=InnoDB**: motore di storage MySQL che supporta transazioni e foreign key (MyISAM, l'alternativa, non le supporta).

---

## Analisi riga per riga

### Setup iniziale

```sql
DROP DATABASE IF EXISTS bakingbread;
CREATE DATABASE bakingbread CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE bakingbread;
```

- `DROP DATABASE IF EXISTS` → elimina il database se esiste già (reset completo). Utile per lo sviluppo.
- `CHARACTER SET utf8mb4` → codifica Unicode completa. `utf8mb4` è il "vero" UTF-8 di MySQL che supporta anche emoji (4 byte per carattere). `utf8` in MySQL è in realtà UTF-8 troncato a 3 byte e non supporta emoji.
- `COLLATE utf8mb4_unicode_ci` → regole di confronto: `unicode` usa le regole Unicode standard, `ci` = case-insensitive (la ricerca "Mario" trova anche "mario").
- `USE bakingbread` → seleziona questo database per tutti i comandi successivi.

---

### Tabella `Utente`

```sql
CREATE TABLE Utente (
    id_utente INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(128) NOT NULL,
    nome_visualizzato VARCHAR(100) NOT NULL,
    avatar_url VARCHAR(255),
    bio TEXT,
    ruolo ENUM('admin', 'utente') DEFAULT 'utente',
    attivo BOOLEAN DEFAULT TRUE,
    ultimo_accesso DATETIME,
    creato_il DATETIME DEFAULT CURRENT_TIMESTAMP,
    aggiornato_il DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_username (username),
    INDEX idx_email (email)
) ENGINE=InnoDB;
```

- `INT AUTO_INCREMENT PRIMARY KEY` → ID intero autoincrementale. MySQL assegna automaticamente il valore successivo a ogni INSERT.
- `VARCHAR(50) NOT NULL UNIQUE` → stringa di max 50 caratteri, obbligatoria, unica nella tabella.
- `VARCHAR(128)` per `password_hash` → 32 (salt hex) + 64 (SHA-256 hex) = 96 caratteri; il campo ha margine extra.
- `TEXT` per `bio` → testo di lunghezza arbitraria (fino a 65.535 byte). `VARCHAR` ha un limite fisso.
- `ENUM('admin', 'utente')` → il campo può contenere solo uno di questi valori. MySQL gestisce la validazione automaticamente.
- `DEFAULT CURRENT_TIMESTAMP` per `creato_il` → MySQL inserisce automaticamente il timestamp corrente.
- `ON UPDATE CURRENT_TIMESTAMP` per `aggiornato_il` → MySQL aggiorna automaticamente questo campo ad ogni UPDATE della riga.
- `INDEX idx_username (username)` → indice esplicito su username per velocizzare le query `WHERE username = ?`. Sebbene `UNIQUE` crei già un indice, esplicitarlo con un nome è buona pratica documentativa.

---

### Tabella `Ricetta`

```sql
CREATE TABLE Ricetta (
    id_ricetta INT AUTO_INCREMENT PRIMARY KEY,
    id_utente INT NOT NULL,
    titolo VARCHAR(200) NOT NULL,
    descrizione TEXT,
    categoria VARCHAR(50),
    tempo_preparazione_min INT,
    tempo_cottura_min INT,
    porzioni INT DEFAULT 4,
    difficolta ENUM('facile', 'media', 'difficile') DEFAULT 'facile',
    dieta VARCHAR(50),
    immagine_url VARCHAR(255),
    pubblicata BOOLEAN DEFAULT TRUE,
    creato_il DATETIME DEFAULT CURRENT_TIMESTAMP,
    aggiornato_il DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_utente) REFERENCES Utente(id_utente) ON DELETE CASCADE,
    INDEX idx_ricetta_autore (id_utente),
    INDEX idx_ricetta_categoria (categoria),
    INDEX idx_ricetta_data (creato_il DESC)
) ENGINE=InnoDB;
```

- `FOREIGN KEY (id_utente) REFERENCES Utente(id_utente) ON DELETE CASCADE` → se un utente viene eliminato, tutte le sue ricette vengono eliminate automaticamente. Senza `CASCADE`, MySQL rifiuterebbe l'eliminazione dell'utente se ha ricette.
- `INDEX idx_ricetta_data (creato_il DESC)` → indice in ordine decrescente perché la query in `home.jsp` usa `ORDER BY r.creato_il DESC`. Un indice ordinato come la query è molto più efficiente.
- `immagine_url VARCHAR(255)` → può essere null (ricetta senza immagine). 255 è la lunghezza massima comune per gli URL.

---

### Tabella `Passaggio`

```sql
CREATE TABLE Passaggio (
    id_passaggio INT AUTO_INCREMENT PRIMARY KEY,
    id_ricetta INT NOT NULL,
    ordine INT NOT NULL,
    descrizione TEXT NOT NULL,
    immagine_url VARCHAR(255),
    FOREIGN KEY (id_ricetta) REFERENCES Ricetta(id_ricetta) ON DELETE CASCADE,
    UNIQUE KEY uk_ricetta_ordine (id_ricetta, ordine),
    INDEX idx_passaggio_ricetta (id_ricetta)
) ENGINE=InnoDB;
```

- `UNIQUE KEY uk_ricetta_ordine (id_ricetta, ordine)` → vincolo composito: la coppia (ricetta, numero d'ordine) deve essere unica. Non possono esserci due passaggi con lo stesso numero d'ordine nella stessa ricetta.

---

### Tabella `Ingrediente`

```sql
CREATE TABLE Ingrediente (
    id_ingrediente INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE,
    categoria VARCHAR(50),
    unita_default VARCHAR(20) DEFAULT 'g',
    creato_il DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_ingrediente_nome (nome)
) ENGINE=InnoDB;
```

Tabella di **anagrafica normalizzata** degli ingredienti. Lo stesso ingrediente (es. "Farina 00") non viene duplicato per ogni ricetta che lo usa. La relazione ricetta-ingrediente è nella tabella `RicettaIngrediente`.

---

### Tabella `RicettaIngrediente` (tabella pivot)

```sql
CREATE TABLE RicettaIngrediente (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_ricetta INT NOT NULL,
    id_ingrediente INT NOT NULL,
    quantita DECIMAL(8,2),
    unita_misura VARCHAR(20),
    ordine_visualizzazione INT,
    note TEXT,
    FOREIGN KEY (id_ricetta) REFERENCES Ricetta(id_ricetta) ON DELETE CASCADE,
    FOREIGN KEY (id_ingrediente) REFERENCES Ingrediente(id_ingrediente) ON DELETE CASCADE,
    INDEX idx_ri_ricetta (id_ricetta),
    INDEX idx_ri_ingrediente (id_ingrediente)
) ENGINE=InnoDB;
```

Questa è una **tabella di relazione molti-a-molti**: una ricetta ha molti ingredienti, un ingrediente appare in molte ricette. La tabella contiene anche dati propri della relazione (quantità, unità, ordine) che non appartengono né alla ricetta né all'ingrediente.

- `DECIMAL(8,2)` per `quantita` → numero decimale con 8 cifre totali e 2 decimali (es. 123456.78). Usare `DECIMAL` invece di `FLOAT/DOUBLE` per valori monetari o misure evita problemi di precisione in virgola mobile.

---

### Tabella `Commento`

```sql
CREATE TABLE Commento (
    id_commento INT AUTO_INCREMENT PRIMARY KEY,
    id_ricetta INT NOT NULL,
    id_utente INT NOT NULL,
    parent_commento INT,
    ...
    FOREIGN KEY (parent_commento) REFERENCES Commento(id_commento) ON DELETE CASCADE,
    ...
) ENGINE=InnoDB;
```

- `parent_commento INT` → nullable. Se NULL: commento top-level; se ha un valore: è una risposta al commento con quell'ID.
- `FOREIGN KEY (parent_commento) REFERENCES Commento(id_commento)` → **self-referential foreign key**: la tabella fa riferimento a se stessa. Permette strutture ad albero (commenti annidati). Con `ON DELETE CASCADE`, eliminare un commento elimina automaticamente tutte le sue risposte.

---

### Tabella `Valutazione`

```sql
CREATE TABLE Valutazione (
    ...
    stelle INT NOT NULL CHECK (stelle >= 1 AND stelle <= 5),
    ...
    UNIQUE KEY uk_valutazione_utente (id_utente, id_ricetta),
    ...
) ENGINE=InnoDB;
```

- `CHECK (stelle >= 1 AND stelle <= 5)` → vincolo di controllo: MySQL 8+ lo applica; versioni precedenti lo ignorano silenziosamente.
- `UNIQUE KEY uk_valutazione_utente (id_utente, id_ricetta)` → ogni utente può votare una ricetta **una sola volta**.

---

### Tabella `MiPiace`

```sql
CREATE TABLE MiPiace (
    id_like INT AUTO_INCREMENT PRIMARY KEY,
    id_ricetta INT NOT NULL,
    id_utente INT NOT NULL,
    creato_il DATETIME DEFAULT CURRENT_TIMESTAMP,
    ...
    UNIQUE KEY uk_like_utente (id_utente, id_ricetta),
    ...
) ENGINE=InnoDB;
```

`UNIQUE KEY uk_like_utente` → come per le valutazioni, un utente può mettere like a una ricetta una sola volta. Usato con `INSERT IGNORE` nel codice Java per un'operazione idempotente.

---

### Tabella `Seguito`

```sql
CREATE TABLE Seguito (
    follower_id INT NOT NULL,
    followed_id INT NOT NULL,
    creato_il DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (follower_id, followed_id),
    FOREIGN KEY (follower_id) REFERENCES Utente(id_utente) ON DELETE CASCADE,
    FOREIGN KEY (followed_id) REFERENCES Utente(id_utente) ON DELETE CASCADE,
    INDEX idx_seguiti_follower (follower_id),
    INDEX idx_seguiti_followed (followed_id)
) ENGINE=InnoDB;
```

- `PRIMARY KEY (follower_id, followed_id)` → **chiave primaria composita**: la combinazione dei due ID è l'identificatore univoco. Non esiste un campo `id` separato. Questo previene automaticamente che lo stesso utente segua lo stesso altro utente due volte.
- Due FOREIGN KEY che puntano entrambe a `Utente` (self-referential many-to-many).

---

### Tabella `Messaggio`

```sql
CREATE TABLE Messaggio (
    id_messaggio INT AUTO_INCREMENT PRIMARY KEY,
    mittente_id INT NOT NULL,
    destinatario_id INT NOT NULL,
    testo TEXT NOT NULL,
    letto BOOLEAN DEFAULT FALSE,
    creato_il DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (mittente_id) REFERENCES Utente(id_utente) ON DELETE CASCADE,
    FOREIGN KEY (destinatario_id) REFERENCES Utente(id_utente) ON DELETE CASCADE,
    INDEX idx_messaggio_mittente (mittente_id),
    INDEX idx_messaggio_destinatario (destinatario_id)
) ENGINE=InnoDB;
```

- `letto BOOLEAN DEFAULT FALSE` → flag per i messaggi non letti (usato per il badge nella navbar).
- Due foreign key a `Utente` (mittente e destinatario).

---

### Tabella `SessioneToken`

```sql
CREATE TABLE SessioneToken (
    id_token INT AUTO_INCREMENT PRIMARY KEY,
    id_utente INT NOT NULL,
    token VARCHAR(64) NOT NULL UNIQUE,
    user_agent VARCHAR(255),
    ip_address VARCHAR(45),
    creato_il DATETIME DEFAULT CURRENT_TIMESTAMP,
    scade_il DATETIME NOT NULL,
    FOREIGN KEY (id_utente) REFERENCES Utente(id_utente) ON DELETE CASCADE,
    INDEX idx_token_valore (token),
    INDEX idx_token_scadenza (scade_il)
) ENGINE=InnoDB;
```

Tabella per i token "Ricordami". 
- `token VARCHAR(64) NOT NULL UNIQUE` → 64 caratteri hex (32 byte = 256 bit di entropia).
- `ip_address VARCHAR(45)` → 45 caratteri perché un indirizzo IPv6 può essere lungo fino a 39 caratteri, ma con la notazione mapped IPv4 può arrivare a 45 (`::ffff:255.255.255.255`).
- `INDEX idx_token_scadenza (scade_il)` → indice sulla scadenza per query come `WHERE scade_il > NOW()`.

---

### Tabella `RicettaSalvata`

```sql
CREATE TABLE RicettaSalvata (
    id_utente INT NOT NULL,
    id_ricetta INT NOT NULL,
    salvato_il DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_utente, id_ricetta),
    FOREIGN KEY (id_utente) REFERENCES Utente(id_utente) ON DELETE CASCADE,
    FOREIGN KEY (id_ricetta) REFERENCES Ricetta(id_ricetta) ON DELETE CASCADE
) ENGINE=InnoDB;
```

Simile a `Seguito`: chiave primaria composita che garantisce unicità. Nota: il campo si chiama `salvato_il` nella definizione della tabella, ma nel codice Java si usa `salvata_il`. Questo è un bug di inconsistenza nei nomi che potrebbe causare errori in alcune query.

---

### Viste (VIEW)

```sql
CREATE VIEW VistaMediaValutazioni AS
SELECT 
    r.id_ricetta,
    AVG(v.stelle) AS media_voti,
    COUNT(v.id_valutazione) AS num_valutazioni
FROM Ricetta r
LEFT JOIN Valutazione v ON r.id_ricetta = v.id_ricetta
GROUP BY r.id_ricetta;
```

Una **VIEW** è una query SQL salvata con un nome. Si usa come una tabella virtuale. `LEFT JOIN` include anche le ricette senza valutazioni (con `AVG = NULL`). `GROUP BY r.id_ricetta` aggrega i voti per ricetta.

Queste viste sono create nel schema ma non vengono usate nel codice Java (le query vengono scritte inline nel JSP). Potrebbero essere usate in futuro.

---

## Diagramma delle relazioni (ER semplificato)

```
Utente ──────────────────── Ricetta
  │ 1..* segue 1..*           │ 1..*
  │ (Seguito)                  │
  │ 1..* messaggi 1..*        ├── Passaggio
  │ (Messaggio)                │
  │ 1..* salva 1..*           ├── RicettaIngrediente ── Ingrediente
  │ (RicettaSalvata)           │
  │                            ├── Commento (auto-ref)
  │                            │     └── Commento (risposte)
  │                            ├── Valutazione
  │                            └── MiPiace
  │
  └── SessioneToken
```
