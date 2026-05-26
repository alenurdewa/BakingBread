# messaggi.jsp

## Descrizione
Sistema di messaggistica privata tra utenti. Layout a due colonne: lista conversazioni (sinistra) e area chat (destra).

## Funzionamento passo per passo

### POST — Invia messaggio
```java
INSERT INTO Messaggio (mittente_id, destinatario_id, testo) VALUES (?, ?, ?)
```
Dopo l'invio reindirizza a `messaggi.jsp?chat=N` per pulire il POST.

### GET — Caricamento
**1. Lista conversazioni** — trova tutti gli utenti con cui l'utente ha scambiato messaggi:
```sql
SELECT u.id_utente, u.nome_visualizzato, u.avatar_url,
  (SELECT testo FROM Messaggio WHERE ... ORDER BY creato_il DESC LIMIT 1) AS ultimo_msg
FROM Utente u WHERE u.id_utente IN (
  SELECT DISTINCT CASE WHEN mittente_id=? THEN destinatario_id ELSE mittente_id END
  FROM Messaggio WHERE mittente_id=? OR destinatario_id=?
)
```

**2. Chat nuova** — se `?chat=N` punta a un utente non ancora in lista, viene aggiunto in cima spostando gli altri con un ciclo `for`:
```java
for (int k = conversazioni.length - 1; k > 0; k--) {
    conversazioni[k] = conversazioni[k - 1];
}
conversazioni[0] = ucNuovo;
```

**3. Messaggi della chat aperta**:
```sql
SELECT id_messaggio, mittente_id, testo, creato_il
FROM Messaggio
WHERE (mittente_id=? AND destinatario_id=?) OR (mittente_id=? AND destinatario_id=?)
ORDER BY creato_il ASC
```

**4. Segna come letti**:
```sql
UPDATE Messaggio SET letto=TRUE
WHERE mittente_id=? AND destinatario_id=? AND letto=FALSE
```

### Renderizzazione bolle
Ogni messaggio è una `<div class="message-bubble bubble-out/bubble-in">` in base a `mittenteId == idUtenteLoggato`.

## Parametri GET
| Parametro | Descrizione |
|-----------|-------------|
| `chat` | ID dell'utente con cui aprire/continuare la chat |

## Parametri POST
| Campo | Descrizione |
|-------|-------------|
| `testo` | Testo del messaggio |
| `destinatario_id` | ID dell'utente destinatario |

## Interazione con classi Java
- **`Db.getConnection()`**
- **`UtenteCard`** — bean per ogni conversazione nella sidebar
- **`MessaggioItem`** — bean per ogni messaggio nella chat
- **`UrlUtils.risolvi()`** — per gli avatar

## JavaScript inline
- `chatDiv.scrollTop = chatDiv.scrollHeight` — scorre in fondo alla chat
- `inviaConInvio(event, form)` — invia con Invio senza Shift

## File collegati
- `css/messages.css`
