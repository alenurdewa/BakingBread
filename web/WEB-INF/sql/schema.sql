-- ============================================================
-- FILE: schema.sql
-- SCOPO: Crea il database "bakingbread" con tutte le tabelle.
-- Da eseguire UNA SOLA VOLTA tramite createDatabase.jsp.
-- MOTORE: MySQL / MariaDB con InnoDB e charset UTF-8.
-- ============================================================

-- Elimina il database se già esiste (per ricreare da zero)
DROP DATABASE IF EXISTS bakingbread;

-- Crea il database con supporto caratteri unicode completo (emoji incluse)
CREATE DATABASE bakingbread
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- Seleziona il database appena creato
USE bakingbread;

-- ============================================================
-- TABELLA: Utente
-- Memorizza i dati di ogni utente registrato.
-- password_hash = SALT(32 hex) + SHA256(64 hex) = 96 caratteri
-- ============================================================
CREATE TABLE Utente (
    id_utente        INT          AUTO_INCREMENT PRIMARY KEY,
    username         VARCHAR(50)  NOT NULL UNIQUE,         -- Nome utente univoco
    email            VARCHAR(100) NOT NULL UNIQUE,         -- Email univoca
    password_hash    VARCHAR(128) NOT NULL,                -- Salt+Hash SHA-256
    nome_visualizzato VARCHAR(100) NOT NULL,               -- Nome mostrato nell'interfaccia
    avatar_url       VARCHAR(255),                         -- URL foto profilo
    bio              TEXT,                                 -- Descrizione breve
    ruolo            ENUM('admin','utente') DEFAULT 'utente',
    attivo           BOOLEAN DEFAULT TRUE,                 -- FALSE = account disabilitato
    ultimo_accesso   DATETIME,                             -- Data ultimo login
    creato_il        DATETIME DEFAULT CURRENT_TIMESTAMP,
    aggiornato_il    DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_username (username),
    INDEX idx_email    (email)
) ENGINE=InnoDB;

-- ============================================================
-- TABELLA: Ricetta
-- Memorizza ogni ricetta con i suoi metadati.
-- ============================================================
CREATE TABLE Ricetta (
    id_ricetta             INT           AUTO_INCREMENT PRIMARY KEY,
    id_utente              INT           NOT NULL,          -- FK → Utente (autore)
    titolo                 VARCHAR(200)  NOT NULL,
    descrizione            TEXT,
    categoria              VARCHAR(50),                     -- antipasto, primo, dolce...
    tempo_preparazione_min INT           DEFAULT 0,         -- Minuti di preparazione
    tempo_cottura_min      INT           DEFAULT 0,         -- Minuti di cottura
    porzioni               INT           DEFAULT 4,
    difficolta             ENUM('facile','media','difficile') DEFAULT 'facile',
    immagine_url           VARCHAR(255),                    -- URL immagine di copertina
    pubblicata             BOOLEAN       DEFAULT TRUE,      -- FALSE = bozza privata
    creato_il              DATETIME      DEFAULT CURRENT_TIMESTAMP,
    aggiornato_il          DATETIME      DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_utente) REFERENCES Utente(id_utente) ON DELETE CASCADE,
    INDEX idx_ricetta_autore   (id_utente),
    INDEX idx_ricetta_categoria(categoria),
    INDEX idx_ricetta_data     (creato_il DESC)
) ENGINE=InnoDB;

-- ============================================================
-- TABELLA: Ingrediente
-- Anagrafica degli ingredienti (evita duplicati per nome).
-- ============================================================
CREATE TABLE Ingrediente (
    id_ingrediente INT          AUTO_INCREMENT PRIMARY KEY,
    nome           VARCHAR(100) NOT NULL UNIQUE,   -- "Farina 00", "Uova", ecc.
    categoria      VARCHAR(50),                    -- "latticini", "cereali", ecc.
    creato_il      DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_ingrediente_nome (nome)
) ENGINE=InnoDB;

-- ============================================================
-- TABELLA: RicettaIngrediente
-- Tabella di collegamento: ogni riga = un ingrediente in una ricetta.
-- quantita è VARCHAR perché può contenere "2-3", "q.b.", "1 cucchiaio"
-- ============================================================
CREATE TABLE RicettaIngrediente (
    id                      INT         AUTO_INCREMENT PRIMARY KEY,
    id_ricetta              INT         NOT NULL,   -- FK → Ricetta
    id_ingrediente          INT         NOT NULL,   -- FK → Ingrediente
    quantita                VARCHAR(50),            -- "200", "q.b.", "2-3"
    unita_misura            VARCHAR(30),            -- "g", "ml", "cucchiai"
    ordine_visualizzazione  INT         DEFAULT 1,  -- Ordine di comparsa nella ricetta
    FOREIGN KEY (id_ricetta)    REFERENCES Ricetta(id_ricetta)       ON DELETE CASCADE,
    FOREIGN KEY (id_ingrediente) REFERENCES Ingrediente(id_ingrediente) ON DELETE CASCADE,
    INDEX idx_ri_ricetta    (id_ricetta),
    INDEX idx_ri_ingrediente(id_ingrediente)
) ENGINE=InnoDB;

-- ============================================================
-- TABELLA: RicettaPassaggio
-- I passaggi di preparazione di una ricetta, in ordine numerico.
-- ============================================================
CREATE TABLE RicettaPassaggio (
    id_passaggio     INT  AUTO_INCREMENT PRIMARY KEY,
    id_ricetta       INT  NOT NULL,              -- FK → Ricetta
    numero_passaggio INT  NOT NULL,              -- 1, 2, 3... (ordine)
    descrizione      TEXT NOT NULL,              -- Testo del passaggio
    FOREIGN KEY (id_ricetta) REFERENCES Ricetta(id_ricetta) ON DELETE CASCADE,
    UNIQUE KEY uk_ricetta_passaggio (id_ricetta, numero_passaggio),
    INDEX idx_passaggio_ricetta (id_ricetta)
) ENGINE=InnoDB;

-- ============================================================
-- TABELLA: Commento
-- Commenti sulle ricette, con supporto risposte annidate.
-- id_parent = NULL → commento principale
-- id_parent = N    → risposta al commento N
-- ============================================================
CREATE TABLE Commento (
    id_commento  INT  AUTO_INCREMENT PRIMARY KEY,
    id_ricetta   INT  NOT NULL,                  -- FK → Ricetta
    id_utente    INT  NOT NULL,                  -- FK → Utente (autore commento)
    id_parent    INT  NULL,                      -- FK → Commento padre (NULL se principale)
    testo        TEXT NOT NULL,
    creato_il    DATETIME DEFAULT CURRENT_TIMESTAMP,
    aggiornato_il DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_ricetta) REFERENCES Ricetta(id_ricetta)   ON DELETE CASCADE,
    FOREIGN KEY (id_utente)  REFERENCES Utente(id_utente)     ON DELETE CASCADE,
    FOREIGN KEY (id_parent)  REFERENCES Commento(id_commento) ON DELETE CASCADE,
    INDEX idx_commento_ricetta(id_ricetta),
    INDEX idx_commento_utente (id_utente)
) ENGINE=InnoDB;

-- ============================================================
-- TABELLA: MiPiace
-- Memorizza i "Mi piace" degli utenti sulle ricette.
-- UNIQUE KEY evita che un utente metta like due volte.
-- ============================================================
CREATE TABLE MiPiace (
    id_like    INT      AUTO_INCREMENT PRIMARY KEY,
    id_ricetta INT      NOT NULL,             -- FK → Ricetta
    id_utente  INT      NOT NULL,             -- FK → Utente
    creato_il  DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_ricetta) REFERENCES Ricetta(id_ricetta) ON DELETE CASCADE,
    FOREIGN KEY (id_utente)  REFERENCES Utente(id_utente)  ON DELETE CASCADE,
    UNIQUE KEY uk_like_utente (id_utente, id_ricetta),  -- Un like per utente per ricetta
    INDEX idx_like_ricetta (id_ricetta)
) ENGINE=InnoDB;

-- ============================================================
-- TABELLA: RicettaSalvata
-- Ricette "salvate" dagli utenti (tipo segnalibro).
-- ============================================================
CREATE TABLE RicettaSalvata (
    id_utente  INT      NOT NULL,             -- FK → Utente
    id_ricetta INT      NOT NULL,             -- FK → Ricetta
    salvato_il DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_utente, id_ricetta),      -- Chiave composta: un salvataggio per coppia
    FOREIGN KEY (id_utente)  REFERENCES Utente(id_utente)  ON DELETE CASCADE,
    FOREIGN KEY (id_ricetta) REFERENCES Ricetta(id_ricetta) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- TABELLA: Seguito
-- Relazioni social: chi segue chi.
-- follower_id → segue → followed_id
-- ============================================================
CREATE TABLE Seguito (
    follower_id INT      NOT NULL,            -- Chi segue
    followed_id INT      NOT NULL,            -- Chi viene seguito
    creato_il   DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (follower_id, followed_id),   -- Un utente non può seguire due volte lo stesso
    FOREIGN KEY (follower_id) REFERENCES Utente(id_utente) ON DELETE CASCADE,
    FOREIGN KEY (followed_id) REFERENCES Utente(id_utente) ON DELETE CASCADE,
    INDEX idx_seguiti_follower (follower_id),
    INDEX idx_seguiti_followed (followed_id)
) ENGINE=InnoDB;

-- ============================================================
-- TABELLA: Messaggio
-- Messaggi privati tra utenti (chat one-to-one).
-- letto = FALSE → messaggio non ancora letto dal destinatario
-- ============================================================
CREATE TABLE Messaggio (
    id_messaggio    INT      AUTO_INCREMENT PRIMARY KEY,
    mittente_id     INT      NOT NULL,        -- FK → Utente (chi invia)
    destinatario_id INT      NOT NULL,        -- FK → Utente (chi riceve)
    testo           TEXT     NOT NULL,
    letto           BOOLEAN  DEFAULT FALSE,   -- FALSE = non ancora letto
    creato_il       DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (mittente_id)     REFERENCES Utente(id_utente) ON DELETE CASCADE,
    FOREIGN KEY (destinatario_id) REFERENCES Utente(id_utente) ON DELETE CASCADE,
    INDEX idx_messaggio_mittente     (mittente_id),
    INDEX idx_messaggio_destinatario (destinatario_id)
) ENGINE=InnoDB;
