PRAGMA foreign_keys = ON;

-- Tabella utenti
CREATE TABLE IF NOT EXISTS utenti (
  id_utente INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT NOT NULL UNIQUE,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  nome_visualizzato TEXT,
  avatar TEXT,
  bio TEXT,
  ruolo TEXT DEFAULT 'user', -- user | admin
  creato_il DATETIME DEFAULT (datetime('now')),
  aggiornato_il DATETIME
);

-- Tabella ricette
CREATE TABLE IF NOT EXISTS ricette (
  id_ricetta INTEGER PRIMARY KEY AUTOINCREMENT,
  id_utente INTEGER NOT NULL, -- autore
  titolo TEXT NOT NULL,
  descrizione TEXT,
  categoria TEXT,
  tempo_preparazione_min INTEGER,
  dieta TEXT DEFAULT 'none', -- es: vegan, gluten_free
  porzioni INTEGER DEFAULT 1,
  pubblicata INTEGER DEFAULT 1, -- 0=false,1=true
  creato_il DATETIME DEFAULT (datetime('now')),
  aggiornato_il DATETIME,
  FOREIGN KEY (id_utente) REFERENCES utenti(id_utente) ON DELETE CASCADE
);

-- Foto riutilizzabili (cover o step)
CREATE TABLE IF NOT EXISTS foto (
  id_foto INTEGER PRIMARY KEY AUTOINCREMENT,
  id_ricetta INTEGER,
  percorso TEXT NOT NULL, -- path o url
  tipo TEXT DEFAULT 'cover', -- cover | step | altro
  descrizione TEXT,
  creato_il DATETIME DEFAULT (datetime('now')),
  FOREIGN KEY (id_ricetta) REFERENCES ricette(id_ricetta) ON DELETE CASCADE
);

-- Passaggi (step)
CREATE TABLE IF NOT EXISTS passaggi (
  id_passaggio INTEGER PRIMARY KEY AUTOINCREMENT,
  id_ricetta INTEGER NOT NULL,
  ordine INTEGER NOT NULL,
  descrizione TEXT NOT NULL,
  id_foto INTEGER,
  creato_il DATETIME DEFAULT (datetime('now')),
  FOREIGN KEY (id_ricetta) REFERENCES ricette(id_ricetta) ON DELETE CASCADE,
  FOREIGN KEY (id_foto) REFERENCES foto(id_foto) ON DELETE SET NULL,
  UNIQUE (id_ricetta, ordine)
);

-- Ingredienti
CREATE TABLE IF NOT EXISTS ingredienti (
  id_ingrediente INTEGER PRIMARY KEY AUTOINCREMENT,
  nome TEXT NOT NULL UNIQUE,
  creato_il DATETIME DEFAULT (datetime('now'))
);

-- Associazione ricetta-ingrediente (many-to-many)
CREATE TABLE IF NOT EXISTS ricetta_ingrediente (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  id_ricetta INTEGER NOT NULL,
  id_ingrediente INTEGER NOT NULL,
  quantita TEXT,
  unita TEXT,
  alternativa INTEGER DEFAULT 0,
  note TEXT,
  FOREIGN KEY (id_ricetta) REFERENCES ricette(id_ricetta) ON DELETE CASCADE,
  FOREIGN KEY (id_ingrediente) REFERENCES ingredienti(id_ingrediente) ON DELETE CASCADE
);

-- Commenti (con reply semplice)
CREATE TABLE IF NOT EXISTS commenti (
  id_commento INTEGER PRIMARY KEY AUTOINCREMENT,
  id_ricetta INTEGER NOT NULL,
  id_utente INTEGER NOT NULL,
  parent_commento INTEGER,
  testo TEXT NOT NULL,
  creato_il DATETIME DEFAULT (datetime('now')),
  aggiornato_il DATETIME,
  FOREIGN KEY (id_ricetta) REFERENCES ricette(id_ricetta) ON DELETE CASCADE,
  FOREIGN KEY (id_utente) REFERENCES utenti(id_utente) ON DELETE CASCADE,
  FOREIGN KEY (parent_commento) REFERENCES commenti(id_commento) ON DELETE SET NULL
);

-- Valutazioni (1..5) - vincolo: un utente una valutazione per ricetta
CREATE TABLE IF NOT EXISTS valutazioni (
  id_valutazione INTEGER PRIMARY KEY AUTOINCREMENT,
  id_ricetta INTEGER NOT NULL,
  id_utente INTEGER NOT NULL,
  stelle INTEGER NOT NULL CHECK (stelle BETWEEN 1 AND 5),
  creato_il DATETIME DEFAULT (datetime('now')),
  FOREIGN KEY (id_ricetta) REFERENCES ricette(id_ricetta) ON DELETE CASCADE,
  FOREIGN KEY (id_utente) REFERENCES utenti(id_utente) ON DELETE CASCADE,
  UNIQUE (id_utente, id_ricetta)
);

-- Mi piace (like) - toggle
CREATE TABLE IF NOT EXISTS mi_piace (
  id_like INTEGER PRIMARY KEY AUTOINCREMENT,
  id_ricetta INTEGER NOT NULL,
  id_utente INTEGER NOT NULL,
  creato_il DATETIME DEFAULT (datetime('now')),
  FOREIGN KEY (id_ricetta) REFERENCES ricette(id_ricetta) ON DELETE CASCADE,
  FOREIGN KEY (id_utente) REFERENCES utenti(id_utente) ON DELETE CASCADE,
  UNIQUE (id_utente, id_ricetta)
);

-- Collezioni personali
CREATE TABLE IF NOT EXISTS collezioni (
  id_collezione INTEGER PRIMARY KEY AUTOINCREMENT,
  id_utente INTEGER NOT NULL,
  nome TEXT NOT NULL,
  descrizione TEXT,
  creato_il DATETIME DEFAULT (datetime('now')),
  FOREIGN KEY (id_utente) REFERENCES utenti(id_utente) ON DELETE CASCADE
);

-- Collezione - ricetta
CREATE TABLE IF NOT EXISTS collezione_ricetta (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  id_collezione INTEGER NOT NULL,
  id_ricetta INTEGER NOT NULL,
  aggiunto_il DATETIME DEFAULT (datetime('now')),
  FOREIGN KEY (id_collezione) REFERENCES collezioni(id_collezione) ON DELETE CASCADE,
  FOREIGN KEY (id_ricetta) REFERENCES ricette(id_ricetta) ON DELETE CASCADE
);

-- Seguiti (follow) utente <-> utente
CREATE TABLE IF NOT EXISTS seguiti (
  follower_id INTEGER NOT NULL,
  followed_id INTEGER NOT NULL,
  creato_il DATETIME DEFAULT (datetime('now')),
  PRIMARY KEY (follower_id, followed_id),
  FOREIGN KEY (follower_id) REFERENCES utenti(id_utente) ON DELETE CASCADE,
  FOREIGN KEY (followed_id) REFERENCES utenti(id_utente) ON DELETE CASCADE
);

-- Messaggi diretti semplici
CREATE TABLE IF NOT EXISTS messaggi (
  id_messaggio INTEGER PRIMARY KEY AUTOINCREMENT,
  mittente_id INTEGER NOT NULL,
  destinatario_id INTEGER NOT NULL,
  testo TEXT NOT NULL,
  creato_il DATETIME DEFAULT (datetime('now')),
  letto INTEGER DEFAULT 0,
  FOREIGN KEY (mittente_id) REFERENCES utenti(id_utente) ON DELETE CASCADE,
  FOREIGN KEY (destinatario_id) REFERENCES utenti(id_utente) ON DELETE CASCADE
);

-- Sondaggi semplici collegati a ricetta
CREATE TABLE IF NOT EXISTS sondaggi (
  id_sondaggio INTEGER PRIMARY KEY AUTOINCREMENT,
  id_ricetta INTEGER NOT NULL,
  domanda TEXT NOT NULL,
  creato_il DATETIME DEFAULT (datetime('now')),
  FOREIGN KEY (id_ricetta) REFERENCES ricette(id_ricetta) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS opzioni_sondaggio (
  id_opzione INTEGER PRIMARY KEY AUTOINCREMENT,
  id_sondaggio INTEGER NOT NULL,
  testo TEXT NOT NULL,
  FOREIGN KEY (id_sondaggio) REFERENCES sondaggi(id_sondaggio) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS voto_sondaggio (
  id_voto INTEGER PRIMARY KEY AUTOINCREMENT,
  id_opzione INTEGER NOT NULL,
  id_utente INTEGER NOT NULL,
  creato_il DATETIME DEFAULT (datetime('now')),
  FOREIGN KEY (id_opzione) REFERENCES opzioni_sondaggio(id_opzione) ON DELETE CASCADE,
  FOREIGN KEY (id_utente) REFERENCES utenti(id_utente) ON DELETE CASCADE,
  UNIQUE (id_opzione, id_utente)
);

-- Sessioni per "remember me"
CREATE TABLE IF NOT EXISTS sessioni_utente (
  token TEXT PRIMARY KEY,
  id_utente INTEGER NOT NULL,
  user_agent TEXT,
  ip TEXT,
  creato_il DATETIME DEFAULT (datetime('now')),
  scade_il DATETIME,
  FOREIGN KEY (id_utente) REFERENCES utenti(id_utente) ON DELETE CASCADE
);

-- Index utili
CREATE INDEX IF NOT EXISTS idx_ricette_autore ON ricette(id_utente);
CREATE INDEX IF NOT EXISTS idx_passaggi_ricetta ON passaggi(id_ricetta);
CREATE INDEX IF NOT EXISTS idx_ric_ing_ricetta ON ricetta_ingrediente(id_ricetta);
CREATE INDEX IF NOT EXISTS idx_commenti_ricetta ON commenti(id_ricetta);
