# register.jsp

## Descrizione
Pagina di registrazione di un nuovo utente. Raccoglie username, email e password, valida i dati, genera l'hash della password e salva il nuovo utente nel database.

## Funzionamento passo per passo

### 1. Controllo sessione
Se l'utente è già loggato viene reindirizzato a `home.jsp`.

### 2. GET — Mostra il form
Viene mostrato il form con quattro campi: `username`, `email`, `password`, `conferma_password`.

### 3. POST — Elabora la registrazione
1. Legge tutti i parametri dal form.
2. Valida in sequenza con `if-else`:
   - username non vuoto, tra 3 e 50 caratteri, solo lettere/numeri/underscore
   - email non vuota e nel formato corretto (`x@y.z`)
   - password almeno 8 caratteri
   - le due password coincidono
3. Se la validazione passa, controlla nel DB che username ed email non siano già usati.
4. Genera un salt di 16 byte casuali con `SecureRandom`.
5. Calcola SHA-256 del salt + password.
6. Converte salt e hash in stringa esadecimale e li concatena.
7. Inserisce il nuovo utente nel DB con `INSERT INTO Utente`.
8. Recupera l'ID auto-generato con `getGeneratedKeys()`.
9. Crea la sessione e reindirizza a `home.jsp`.

## Parametri ricevuti (POST)
| Campo | Tipo | Obbligatorio | Validazione |
|-------|------|:---:|-------------|
| `username` | String | ✓ | 3-50 char, solo `[a-zA-Z0-9_]` |
| `email` | String | ✓ | Formato `x@y.z` |
| `password` | String | ✓ | Min 8 caratteri |
| `conferma_password` | String | ✓ | Deve coincidere con password |

## Algoritmo di hashing password
```
SecureRandom → 16 byte casuali (salt)
salt → stringa hex a 32 caratteri (saltHex)
SHA-256(salt + password) → 32 byte → stringa hex a 64 caratteri (hashHex)
password_hash salvato nel DB = saltHex + hashHex (96 caratteri totali)
```

## Gestione sessione
Se la registrazione va a buon fine:
```java
session.setAttribute("id_utente",   nuovoId);
session.setAttribute("username",    username.trim());
session.setAttribute("nome_utente", username.trim());
session.setAttribute("avatar_url",  null);
```

## Interazione con classi Java
- **`Db.getConnection()`** — connessione al database

## File collegati
- `register.js` — toggle password + validazione client-side
- `css/auth.css` — stili del form
