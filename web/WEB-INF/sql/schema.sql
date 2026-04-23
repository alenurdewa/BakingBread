-- Schema SQL BakingBread - Normalizzato 3NF
-- Database: bakingbread
-- Motore: InnoDB (MySQL/MariaDB)

DROP DATABASE IF EXISTS bakingbread;
CREATE DATABASE bakingbread CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE bakingbread;

-- ============================================
-- TABELLA UTENTI
-- Gestione utenti con ruoli e stato
-- ============================================
CREATE TABLE Utente (
    id_utente INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    -- MODIFICA: Alzato a 128 per contenere Salt (32) + Hash SHA-256 (64)
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

-- ============================================
-- TABELLA RICETTE
-- Ricette create dagli utenti
-- ============================================
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

-- ============================================
-- TABELLA PASSAGGI
-- Passaggi di preparazione per ogni ricetta
-- ============================================
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

-- ============================================
-- TABELLA INGREDIENTI
-- Anagrafica ingredienti (normalizzata)
-- ============================================
CREATE TABLE Ingrediente (
    id_ingrediente INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE,
    categoria VARCHAR(50),
    unita_default VARCHAR(20) DEFAULT 'g',
    creato_il DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_ingrediente_nome (nome)
) ENGINE=InnoDB;

-- ============================================
-- TABELLA RICETTA_INGREDIENTE
-- Relazione ricetta-ingrediente con quantita
-- ============================================
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

-- ============================================
-- TABELLA COMMENTI
-- Commenti alle ricette (risposte nidificate)
-- ============================================
CREATE TABLE Commento (
    id_commento INT AUTO_INCREMENT PRIMARY KEY,
    id_ricetta INT NOT NULL,
    id_utente INT NOT NULL,
    parent_commento INT,
    testo TEXT NOT NULL,
    creato_il DATETIME DEFAULT CURRENT_TIMESTAMP,
    aggiornato_il DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_ricetta) REFERENCES Ricetta(id_ricetta) ON DELETE CASCADE,
    FOREIGN KEY (id_utente) REFERENCES Utente(id_utente) ON DELETE CASCADE,
    FOREIGN KEY (parent_commento) REFERENCES Commento(id_commento) ON DELETE CASCADE,
    INDEX idx_commento_ricetta (id_ricetta),
    INDEX idx_commento_utente (id_utente)
) ENGINE=InnoDB;

-- ============================================
-- TABELLA VALUTAZIONI
-- Valutazioni in stelle (1-5) per ricette
-- ============================================
CREATE TABLE Valutazione (
    id_valutazione INT AUTO_INCREMENT PRIMARY KEY,
    id_ricetta INT NOT NULL,
    id_utente INT NOT NULL,
    stelle INT NOT NULL CHECK (stelle >= 1 AND stelle <= 5),
    creato_il DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_ricetta) REFERENCES Ricetta(id_ricetta) ON DELETE CASCADE,
    FOREIGN KEY (id_utente) REFERENCES Utente(id_utente) ON DELETE CASCADE,
    UNIQUE KEY uk_valutazione_utente (id_utente, id_ricetta),
    INDEX idx_valutazione_ricetta (id_ricetta)
) ENGINE=InnoDB;

-- ============================================
-- TABELLA MI_PIACE
-- Toggle like per ricette
-- ============================================
CREATE TABLE MiPiace (
    id_like INT AUTO_INCREMENT PRIMARY KEY,
    id_ricetta INT NOT NULL,
    id_utente INT NOT NULL,
    creato_il DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_ricetta) REFERENCES Ricetta(id_ricetta) ON DELETE CASCADE,
    FOREIGN KEY (id_utente) REFERENCES Utente(id_utente) ON DELETE CASCADE,
    UNIQUE KEY uk_like_utente (id_utente, id_ricetta),
    INDEX idx_like_ricetta (id_ricetta)
) ENGINE=InnoDB;

-- ============================================
-- TABELLA SEGUITI
-- follower -> followed (relazioni sociali)
-- ============================================
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

-- ============================================
-- TABELLA MESSAGGI
-- Messaggi privati tra utenti
-- ============================================
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

-- ============================================
-- TABELLA COLLEZIONI
-- Collezioni personali di ricette
-- ============================================
CREATE TABLE Collezione (
    id_collezione INT AUTO_INCREMENT PRIMARY KEY,
    id_utente INT NOT NULL,
    nome VARCHAR(100) NOT NULL,
    descrizione TEXT,
    privata BOOLEAN DEFAULT FALSE,
    creato_il DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_utente) REFERENCES Utente(id_utente) ON DELETE CASCADE,
    INDEX idx_collezione_utente (id_utente)
) ENGINE=InnoDB;

-- ============================================
-- TABELLA COLLEZIONE_RICETTA
-- Ricette all'interno di collezioni
-- ============================================
CREATE TABLE CollezioneRicetta (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_collezione INT NOT NULL,
    id_ricetta INT NOT NULL,
    aggiunto_il DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_collezione) REFERENCES Collezione(id_collezione) ON DELETE CASCADE,
    FOREIGN KEY (id_ricetta) REFERENCES Ricetta(id_ricetta) ON DELETE CASCADE,
    UNIQUE KEY uk_collezione_ricetta (id_collezione, id_ricetta)
) ENGINE=InnoDB;

-- ============================================
-- TABELLA SONDAGGI
-- Sondaggi su ricette
-- ============================================
CREATE TABLE Sondaggio (
    id_sondaggio INT AUTO_INCREMENT PRIMARY KEY,
    id_ricetta INT NOT NULL,
    id_utente INT NOT NULL,
    domanda TEXT NOT NULL,
    attivo BOOLEAN DEFAULT TRUE,
    creato_il DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_ricetta) REFERENCES Ricetta(id_ricetta) ON DELETE CASCADE,
    FOREIGN KEY (id_utente) REFERENCES Utente(id_utente) ON DELETE CASCADE,
    INDEX idx_sondaggio_ricetta (id_ricetta)
) ENGINE=InnoDB;

CREATE TABLE OpzioneSondaggio (
    id_opzione INT AUTO_INCREMENT PRIMARY KEY,
    id_sondaggio INT NOT NULL,
    testo TEXT NOT NULL,
    FOREIGN KEY (id_sondaggio) REFERENCES Sondaggio(id_sondaggio) ON DELETE CASCADE,
    INDEX idx_opzione_sondaggio (id_sondaggio)
) ENGINE=InnoDB;

CREATE TABLE VotoSondaggio (
    id_voto INT AUTO_INCREMENT PRIMARY KEY,
    id_opzione INT NOT NULL,
    id_utente INT NOT NULL,
    creato_il DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_opzione) REFERENCES OpzioneSondaggio(id_opzione) ON DELETE CASCADE,
    FOREIGN KEY (id_utente) REFERENCES Utente(id_utente) ON DELETE CASCADE,
    UNIQUE KEY uk_voto_utente (id_utente, id_opzione)
) ENGINE=InnoDB;

-- ============================================
-- TABELLA SESSIONI_TOKEN
-- Token per login persistente (Remember Me)
-- ============================================
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

-- ============================================
-- TABELLA RICETTE_SALVATE
-- Ricette salvate/preferite dagli utenti
-- ============================================
CREATE TABLE RicettaSalvata (
    id_utente INT NOT NULL,
    id_ricetta INT NOT NULL,
    salvato_il DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_utente, id_ricetta),
    FOREIGN KEY (id_utente) REFERENCES Utente(id_utente) ON DELETE CASCADE,
    FOREIGN KEY (id_ricetta) REFERENCES Ricetta(id_ricetta) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- VISTA MEDIA VALUTAZIONI
-- Media voti per ricetta
-- ============================================
CREATE VIEW VistaMediaValutazioni AS
SELECT 
    r.id_ricetta,
    AVG(v.stelle) AS media_voti,
    COUNT(v.id_valutazione) AS num_valutazioni
FROM Ricetta r
LEFT JOIN Valutazione v ON r.id_ricetta = v.id_ricetta
GROUP BY r.id_ricetta;

-- ============================================
-- VISTA CONTEGGIO LIKE
-- Conteggio like per ricetta
-- ============================================
CREATE VIEW VistaConteggioLike AS
SELECT 
    r.id_ricetta,
    COUNT(mp.id_like) AS num_like
FROM Ricetta r
LEFT JOIN MiPiace mp ON r.id_ricetta = mp.id_ricetta
GROUP BY r.id_ricetta;