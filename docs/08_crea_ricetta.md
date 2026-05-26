# crea_ricetta.jsp

## Descrizione
Form per la creazione di una nuova ricetta o la modifica di una esistente. Gestisce l'upload dell'immagine di copertina e salva nel DB i dati base, gli ingredienti e i passaggi, usando una **transazione** per garantire l'integrità.

## Modalità operative

| Modalità | Come si attiva | Comportamento |
|----------|---------------|---------------|
| **Crea** | GET senza parametri | Form vuoto |
| **Modifica** | GET con `?modifica=N` | Form precompilato con dati esistenti |
| **Salva** | POST | Inserisce o aggiorna nel DB |

## Funzionamento passo per passo

### GET con `?modifica=N`
1. Verifica che l'utente loggato sia il proprietario della ricetta.
2. Query per i dati base della ricetta.
3. **Caricamento ingredienti**: prima `SELECT COUNT(*)`, poi `SELECT` per riempire l'array `fIngNomi[]`, `fIngQuantita[]`, `fIngUnita[]`.
4. **Caricamento passaggi**: stessa logica conta+riempi → array `fPassaggi[]`.

### POST — Salvo ricetta
1. Legge i parametri. Gli ingredienti e passaggi vengono letti come array tramite `request.getParameterValues()` — restituisce già un `String[]`.
2. Gestisce l'upload immagine con `FileStore.salva()`.
3. Avvia la transazione: `conn.setAutoCommit(false)`.
4. **Se modifica**: aggiorna la riga esistente + elimina vecchi ingredienti/passaggi.
5. **Se crea**: `INSERT INTO Ricetta`, recupera l'ID generato.
6. **Inserimento ingredienti**: per ogni nome non vuoto nell'array:
   - Cerca se esiste in `Ingrediente` con `LOWER(nome) = LOWER(?)`
   - Se non esiste: `INSERT INTO Ingrediente`
   - Collega con `INSERT INTO RicettaIngrediente`
7. **Inserimento passaggi**: `INSERT INTO RicettaPassaggio` per ogni testo non vuoto.
8. `conn.commit()` → reindirizza al dettaglio.
9. In caso di errore: `conn.rollback()`.

## Parametri GET
| Parametro | Descrizione |
|-----------|-------------|
| `modifica` | ID numerico della ricetta da modificare |

## Parametri POST (multipart/form-data)
| Campo | Tipo | Note |
|-------|------|------|
| `titolo` | text | Obbligatorio |
| `descrizione` | textarea | |
| `categoria` | select | |
| `difficolta` | select | facile/media/difficile |
| `tempo_preparazione` | number | Minuti |
| `tempo_cottura` | number | Minuti |
| `porzioni` | number | |
| `immagine_file` | file | Upload immagine |
| `immagine_url` | url | URL alternativo |
| `pubblicata` | checkbox | Visibilità pubblica |
| `ingrediente_nome[]` | text[] | Array nomi ingredienti |
| `ingrediente_quantita[]` | text[] | Array quantità |
| `ingrediente_unita[]` | text[] | Array unità di misura |
| `passaggio_descrizione[]` | textarea[] | Array passaggi |

## Interazione con classi Java
- **`Db.getConnection()`**
- **`FileStore.salva(part, application, "recipes", "recipe_N")`**
- **`Ingrediente`** — bean non usato direttamente qui (logica inline nel JSP)

## File collegati
- `recipe.js` — aggiunge/rimuove righe ingredienti e passaggi
- `css/recipe.css`
