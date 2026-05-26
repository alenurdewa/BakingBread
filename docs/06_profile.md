# profile.jsp

## Descrizione
Mostra il profilo pubblico di un utente. Può visualizzare il proprio profilo o quello di un altro utente. Gestisce il follow/unfollow tramite form POST.

## Funzionamento passo per passo

### 1. Determina quale profilo mostrare
```java
int idProfiloTarget = idUtenteLoggato; // Default: profilo proprio
String idParam = request.getParameter("id");
if (idParam != null) { idProfiloTarget = Integer.parseInt(idParam); }
boolean isAltruiProfilo = (idProfiloTarget != idUtenteLoggato);
```

### 2. POST — Follow / Unfollow
Se la richiesta è POST, legge il parametro `azione`:
- `"segui"` → `INSERT IGNORE INTO Seguito (follower_id, followed_id)`
- `"smetti"` → `DELETE FROM Seguito WHERE follower_id = ? AND followed_id = ?`

Dopo l'operazione reindirizza al profilo (pattern POST-REDIRECT-GET).

### 3. Caricamento dati profilo
Esegue queste query in sequenza:
1. `SELECT nome_visualizzato, username, bio, avatar_url FROM Utente WHERE id_utente = ?`
2. `SELECT COUNT(*) FROM Seguito WHERE followed_id = ?` → numFollower
3. `SELECT COUNT(*) FROM Seguito WHERE follower_id = ?` → numSeguiti
4. `SELECT 1 FROM Seguito WHERE follower_id = ? AND followed_id = ?` → seguoGiaTarget
5. `SELECT COUNT(*) FROM Ricetta WHERE id_utente = ? AND pubblicata = TRUE` → numRicette
6. `SELECT id_ricetta, titolo, immagine_url, categoria, difficolta FROM Ricetta ...` → array ricette

### 4. Renderizzazione condizionale
Il template HTML mostra:
- Se `isAltruiProfilo = true`: pulsanti "Segui" / "Stai seguendo" + link "Messaggio"
- Se `isAltruiProfilo = false`: link "Modifica profilo"

## Parametri GET
| Parametro | Descrizione |
|-----------|-------------|
| `id` | ID dell'utente di cui vedere il profilo (opzionale) |

## Parametri POST
| Campo | Descrizione |
|-------|-------------|
| `azione` | `"segui"` o `"smetti"` |

## Gestione sessione
Solo lettura: legge `id_utente` per confrontarlo con il profilo visualizzato.

## Interazione con classi Java
- **`Db.getConnection()`**
- **`RicettaCard`** — per le ricette nella griglia del profilo
- **`UrlUtils.risolvi()`** — per URL avatar e immagini ricette
