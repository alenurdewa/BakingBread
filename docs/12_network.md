# network.jsp

## Descrizione
Gestisce le relazioni sociali: mostra la lista dei seguiti e dei follower di un utente, con pulsanti per seguire/smettere di seguire.

## Funzionamento passo per passo

### 1. Parametri letti dall'URL
```
?id=N      → profilo di cui vedere il network (default: utente loggato)
?tab=X     → "seguiti" o "follower" (default: "seguiti")
?segui=N   → segue l'utente N, poi redirect
?smetti=N  → smette di seguire l'utente N, poi redirect
```

### 2. Gestione follow/unfollow (GET con parametro)
```java
// Segui
INSERT IGNORE INTO Seguito (follower_id, followed_id) VALUES (?, ?)

// Smetti
DELETE FROM Seguito WHERE follower_id = ? AND followed_id = ?
```
Dopo l'azione: redirect a `network.jsp?id=N&tab=X`.

### 3. Caricamento lista utenti
La query cambia in base alla tab attiva:
- **tab=seguiti**: `JOIN Seguito ON followed_id = u.id_utente WHERE follower_id = ?`
- **tab=follower**: `JOIN Seguito ON follower_id = u.id_utente WHERE followed_id = ?`

La subquery `(SELECT COUNT(*) FROM Seguito WHERE follower_id = ? AND followed_id = u.id_utente) AS seguo` determina se l'utente loggato segue già ciascun utente della lista.

Pattern conta → crea array → riempi:
```java
UtenteCard[] utenti = new UtenteCard[numUtenti];
```

### 4. Renderizzazione
Per ogni utente: avatar, nome, username. Se `u.getIdUtente() != idUtenteLoggato` mostra il pulsante segui/smetti.

## Parametri GET
| Parametro | Descrizione |
|-----------|-------------|
| `id` | Profilo di cui vedere il network |
| `tab` | `"seguiti"` o `"follower"` |
| `segui` | ID utente da seguire |
| `smetti` | ID utente da smettere di seguire |

## Interazione con classi Java
- **`Db.getConnection()`**
- **`UtenteCard`** — bean per ogni utente nella lista
- **`UrlUtils.risolvi()`** — per gli avatar
