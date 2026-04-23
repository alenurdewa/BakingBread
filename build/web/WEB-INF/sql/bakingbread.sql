-- DATABASE
CREATE DATABASE IF NOT EXISTS bakingbread CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE bakingbread;

-- TABELLA UTENTI
CREATE TABLE IF NOT EXISTS utenti (
    id_utente INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    nome_visualizzato VARCHAR(100),
    avatar VARCHAR(255),
    bio TEXT,
    ruolo VARCHAR(20) DEFAULT 'user',
    creato_il DATETIME DEFAULT CURRENT_TIMESTAMP,
    aggiornato_il DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- TABELLA RICETTE (Ora include direttamente immagine_base64)
CREATE TABLE IF NOT EXISTS ricette (
    id_ricetta INT AUTO_INCREMENT PRIMARY KEY,
    id_utente INT NOT NULL,
    titolo VARCHAR(200) NOT NULL,
    descrizione TEXT,
    categoria VARCHAR(100),
    tempo_preparazione_min INT,
    dieta VARCHAR(50) DEFAULT 'none',
    porzioni INT DEFAULT 1,
    immagine_base64 LONGTEXT, 
    pubblicata BOOLEAN DEFAULT TRUE,
    creato_il DATETIME DEFAULT CURRENT_TIMESTAMP,
    aggiornato_il DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_utente) REFERENCES utenti(id_utente) ON DELETE CASCADE
) ENGINE=InnoDB;

-- TABELLA FOTO
CREATE TABLE IF NOT EXISTS foto (
    id_foto INT AUTO_INCREMENT PRIMARY KEY,
    id_ricetta INT,
    percorso VARCHAR(255) NOT NULL,
    tipo VARCHAR(50) DEFAULT 'cover',
    descrizione TEXT,
    creato_il DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_ricetta) REFERENCES ricette(id_ricetta) ON DELETE CASCADE
) ENGINE=InnoDB;

-- TABELLA PASSAGGI
CREATE TABLE IF NOT EXISTS passaggi (
    id_passaggio INT AUTO_INCREMENT PRIMARY KEY,
    id_ricetta INT NOT NULL,
    ordine INT NOT NULL,
    descrizione TEXT NOT NULL,
    id_foto INT,
    creato_il DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_ricetta) REFERENCES ricette(id_ricetta) ON DELETE CASCADE,
    FOREIGN KEY (id_foto) REFERENCES foto(id_foto) ON DELETE SET NULL,
    UNIQUE (id_ricetta, ordine)
) ENGINE=InnoDB;

-- TABELLA INGREDIENTI
CREATE TABLE IF NOT EXISTS ingredienti (
    id_ingrediente INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE,
    creato_il DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- TABELLA RICETTA_INGREDIENTE
CREATE TABLE IF NOT EXISTS ricetta_ingrediente (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_ricetta INT NOT NULL,
    id_ingrediente INT NOT NULL,
    quantita VARCHAR(50),
    unita VARCHAR(20),
    alternativa BOOLEAN DEFAULT FALSE,
    note TEXT,
    FOREIGN KEY (id_ricetta) REFERENCES ricette(id_ricetta) ON DELETE CASCADE,
    FOREIGN KEY (id_ingrediente) REFERENCES ingredienti(id_ingrediente) ON DELETE CASCADE
) ENGINE=InnoDB;

-- TABELLA COMMENTI
CREATE TABLE IF NOT EXISTS commenti (
    id_commento INT AUTO_INCREMENT PRIMARY KEY,
    id_ricetta INT NOT NULL,
    id_utente INT NOT NULL,
    parent_commento INT,
    testo TEXT NOT NULL,
    creato_il DATETIME DEFAULT CURRENT_TIMESTAMP,
    aggiornato_il DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_ricetta) REFERENCES ricette(id_ricetta) ON DELETE CASCADE,
    FOREIGN KEY (id_utente) REFERENCES utenti(id_utente) ON DELETE CASCADE,
    FOREIGN KEY (parent_commento) REFERENCES commenti(id_commento) ON DELETE SET NULL
) ENGINE=InnoDB;

-- TABELLA VALUTAZIONI
CREATE TABLE IF NOT EXISTS valutazioni (
    id_valutazione INT AUTO_INCREMENT PRIMARY KEY,
    id_ricetta INT NOT NULL,
    id_utente INT NOT NULL,
    stelle INT NOT NULL CHECK (stelle BETWEEN 1 AND 5),
    creato_il DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_ricetta) REFERENCES ricette(id_ricetta) ON DELETE CASCADE,
    FOREIGN KEY (id_utente) REFERENCES utenti(id_utente) ON DELETE CASCADE,
    UNIQUE (id_utente, id_ricetta)
) ENGINE=InnoDB;

-- TABELLA MI_PIACE
CREATE TABLE IF NOT EXISTS mi_piace (
    id_like INT AUTO_INCREMENT PRIMARY KEY,
    id_ricetta INT NOT NULL,
    id_utente INT NOT NULL,
    creato_il DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_ricetta) REFERENCES ricette(id_ricetta) ON DELETE CASCADE,
    FOREIGN KEY (id_utente) REFERENCES utenti(id_utente) ON DELETE CASCADE,
    UNIQUE (id_utente, id_ricetta)
) ENGINE=InnoDB;

-- TABELLA COLLEZIONI
CREATE TABLE IF NOT EXISTS collezioni (
    id_collezione INT AUTO_INCREMENT PRIMARY KEY,
    id_utente INT NOT NULL,
    nome VARCHAR(100) NOT NULL,
    descrizione TEXT,
    creato_il DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_utente) REFERENCES utenti(id_utente) ON DELETE CASCADE
) ENGINE=InnoDB;

-- TABELLA COLLEZIONE_RICETTA
CREATE TABLE IF NOT EXISTS collezione_ricetta (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_collezione INT NOT NULL,
    id_ricetta INT NOT NULL,
    aggiunto_il DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_collezione) REFERENCES collezioni(id_collezione) ON DELETE CASCADE,
    FOREIGN KEY (id_ricetta) REFERENCES ricette(id_ricetta) ON DELETE CASCADE
) ENGINE=InnoDB;

-- TABELLA SEGUITI
CREATE TABLE IF NOT EXISTS seguiti (
    follower_id INT NOT NULL,
    followed_id INT NOT NULL,
    creato_il DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (follower_id, followed_id),
    FOREIGN KEY (follower_id) REFERENCES utenti(id_utente) ON DELETE CASCADE,
    FOREIGN KEY (followed_id) REFERENCES utenti(id_utente) ON DELETE CASCADE
) ENGINE=InnoDB;

-- TABELLA MESSAGGI
CREATE TABLE IF NOT EXISTS messaggi (
    id_messaggio INT AUTO_INCREMENT PRIMARY KEY,
    mittente_id INT NOT NULL,
    destinatario_id INT NOT NULL,
    testo TEXT NOT NULL,
    creato_il DATETIME DEFAULT CURRENT_TIMESTAMP,
    letto BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (mittente_id) REFERENCES utenti(id_utente) ON DELETE CASCADE,
    FOREIGN KEY (destinatario_id) REFERENCES utenti(id_utente) ON DELETE CASCADE
) ENGINE=InnoDB;

-- TABELLA SONDAGGI
CREATE TABLE IF NOT EXISTS sondaggi (
    id_sondaggio INT AUTO_INCREMENT PRIMARY KEY,
    id_ricetta INT NOT NULL,
    domanda TEXT NOT NULL,
    creato_il DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_ricetta) REFERENCES ricette(id_ricetta) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS opzioni_sondaggio (
    id_opzione INT AUTO_INCREMENT PRIMARY KEY,
    id_sondaggio INT NOT NULL,
    testo TEXT NOT NULL,
    FOREIGN KEY (id_sondaggio) REFERENCES sondaggi(id_sondaggio) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS voto_sondaggio (
    id_voto INT AUTO_INCREMENT PRIMARY KEY,
    id_opzione INT NOT NULL,
    id_utente INT NOT NULL,
    creato_il DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_opzione) REFERENCES opzioni_sondaggio(id_opzione) ON DELETE CASCADE,
    FOREIGN KEY (id_utente) REFERENCES utenti(id_utente) ON DELETE CASCADE,
    UNIQUE (id_opzione, id_utente)
) ENGINE=InnoDB;

-- TABELLA SESSIONI_UTENTE
CREATE TABLE IF NOT EXISTS sessioni_utente (
    token VARCHAR(255) PRIMARY KEY,
    id_utente INT NOT NULL,
    user_agent VARCHAR(255),
    ip VARCHAR(50),
    creato_il DATETIME DEFAULT CURRENT_TIMESTAMP,
    scade_il DATETIME,
    FOREIGN KEY (id_utente) REFERENCES utenti(id_utente) ON DELETE CASCADE
) ENGINE=InnoDB;


-- Per gestire l'immagine profilo come testo Base64
ALTER TABLE utenti ADD COLUMN avatar_base64 LONGTEXT;

-- Tabella semplificata e dedicata per i salvataggi delle ricette
CREATE TABLE IF NOT EXISTS ricette_salvate (
    id_utente INT NOT NULL,
    id_ricetta INT NOT NULL,
    salvato_il DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_utente, id_ricetta),
    FOREIGN KEY (id_utente) REFERENCES utenti(id_utente) ON DELETE CASCADE,
    FOREIGN KEY (id_ricetta) REFERENCES ricette(id_ricetta) ON DELETE CASCADE
) ENGINE=InnoDB;

-- INDICI UTILI
CREATE INDEX idx_ricette_autore ON ricette(id_utente);
CREATE INDEX idx_passaggi_ricetta ON passaggi(id_ricetta);
CREATE INDEX idx_ric_ing_ricetta ON ricetta_ingrediente(id_ricetta);
CREATE INDEX idx_commenti_ricetta ON commenti(id_ricetta);