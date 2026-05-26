# home.jsp

## Descrizione
Feed principale dell'applicazione. Mostra le ricette pubblicate da tutti gli utenti, con possibilità di cercare, mettere like e salvare le ricette.

## Funzionamento passo per passo

### 1. Controllo autenticazione
Se `session.getAttribute("id_utente")` è null, reindirizza a `login.jsp`.

### 2. Gestione azioni (like / salva)
Se l'URL contiene i parametri `?azione=...&tipo=...&id=...`, la pagina esegue l'azione sul DB prima di caricare il feed.

**Possibili azioni:**
- `azione=mi piace&tipo=aggiungi` → `INSERT IGNORE INTO MiPiace`
- `azione=mi piace&tipo=rimuovi` → `DELETE FROM MiPiace`
- `azione=salva&tipo=aggiungi`  → `INSERT IGNORE INTO RicettaSalvata`
- `azione=salva&tipo=rimuovi`   → `DELETE FROM RicettaSalvata`

Dopo ogni azione viene fatto un redirect (pattern **POST-REDIRECT-GET**) per evitare che il refresh della pagina ripeta l'azione.

### 3. Caricamento ricette con array
```java
// Prima conta
PreparedStatement psCount = conn.prepareStatement("SELECT COUNT(*) FROM Ricetta WHERE pubblicata = TRUE");
int numRicette = ...;

// Poi crea l'array della dimensione esatta
RicettaCard[] ricette = new RicettaCard[numRicette];

// Poi popola
PreparedStatement ps = conn.prepareStatement("SELECT r.*, u.*, COUNT(mp.*), SUM(liked) ...");
int i = 0;
while (rs.next()) { ricette[i] = new RicettaCard(); ...; i++; }
```

### 4. Supporto ricerca
Se è presente il parametro `?cerca=testo`, la query SQL aggiunge:
```sql
AND (r.titolo LIKE ? OR r.descrizione LIKE ?)
```
Il parametro viene passato come `%testo%` (wildcard SQL).

### 5. Renderizzazione HTML
Un ciclo `for` scorre l'array `ricette[]` e genera una `<article>` per ogni ricetta.

## Parametri GET
| Parametro | Descrizione |
|-----------|-------------|
| `cerca` | Testo da cercare nel titolo o nella descrizione |
| `azione` | `"mi piace"` o `"salva"` |
| `tipo` | `"aggiungi"` o `"rimuovi"` |
| `id` | ID numerico della ricetta su cui agire |

## Gestione sessione
Solo lettura: legge `id_utente` per personalizzare il feed e sapere se l'utente ha già messo like/salvato.

## Interazione con classi Java
- **`Db.getConnection()`** — connessione al DB
- **`RicettaCard`** — bean che contiene i dati di ogni ricetta nel feed
- **`UrlUtils.risolvi(ctx, url)`** — risolve URL immagini

## File collegati
- `home.js` — feedback visivo sui pulsanti
- `css/home.css` — stili delle card ricetta
