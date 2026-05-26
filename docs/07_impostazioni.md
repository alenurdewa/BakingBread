# impostazioni.jsp

## Descrizione
Permette all'utente loggato di modificare il proprio profilo: nome, email, bio, foto avatar e password.

## Funzionamento passo per passo

### GET — Carica i dati attuali
Query:
```sql
SELECT nome_visualizzato, email, bio, avatar_url FROM Utente WHERE id_utente = ?
```
I valori vengono precompilati nei campi del form.

### POST — Salva le modifiche

1. **Validazione**: nome e email non vuoti.
2. **Gestione avatar**:
   - Prova `request.getPart("avatar_file")` → chiama `FileStore.salva()` → ottiene il percorso
   - Se non c'è file caricato, usa il valore del campo `avatar_url` (URL testuale)
3. **Controllo email duplicata**:
   ```sql
   SELECT id_utente FROM Utente WHERE email = ? AND id_utente != ?
   ```
4. **Aggiornamento DB**:
   - Se c'è un nuovo avatar: `UPDATE Utente SET nome_visualizzato=?, email=?, bio=?, avatar_url=?`
   - Altrimenti: `UPDATE Utente SET nome_visualizzato=?, email=?, bio=?`
5. **Cambio password** (opzionale): se i campi `nuova_password` e `conferma_password` non sono vuoti, rigenera salt+hash e aggiorna.
6. **Aggiorna la sessione**: `session.setAttribute("nome_utente", nuovoNome)` e `session.setAttribute("avatar_url", ...)`.

## Parametri POST (multipart/form-data)
| Campo | Tipo | Descrizione |
|-------|------|-------------|
| `nome_visualizzato` | text | Nome da mostrare nell'interfaccia |
| `email` | email | Indirizzo email |
| `bio` | textarea | Descrizione breve |
| `avatar_file` | file | Immagine profilo da caricare |
| `avatar_url` | url | URL immagine alternativo |
| `nuova_password` | password | Nuova password (opzionale) |
| `conferma_password` | password | Conferma nuova password |

## Gestione sessione
Aggiorna `nome_utente` e `avatar_url` in sessione dopo il salvataggio.

## Interazione con classi Java
- **`Db.getConnection()`**
- **`FileStore.salva(part, application, "avatars", "avatar_N")`** — salva l'immagine su disco
- **`UrlUtils.risolvi()`** — per mostrare l'avatar corrente

## File collegati
- `profile.js` — anteprima avatar prima del caricamento
- `css/settings.css`
