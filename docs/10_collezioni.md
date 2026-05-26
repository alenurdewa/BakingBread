# collezioni.jsp

## Descrizione
Mostra la libreria personale dell'utente loggato: tutte le ricette che ha salvato/segnato come preferite tramite il pulsante 📌 nella home.

## Funzionamento passo per passo

### 1. Controllo autenticazione
Se non loggato → redirect a `login.jsp`.

### 2. Caricamento ricette salvate
Pattern conta → crea array → riempi:
```java
// Conta
SELECT COUNT(*) FROM RicettaSalvata WHERE id_utente = ?

// Crea array
RicettaCard[] ricetteSalvate = new RicettaCard[numSalvate];

// Popola con JOIN
SELECT r.*, u.*, COUNT(mp.id_like)
FROM RicettaSalvata rs
JOIN Ricetta r ON rs.id_ricetta = r.id_ricetta
JOIN Utente u ON r.id_utente = u.id_utente
LEFT JOIN MiPiace mp ON r.id_ricetta = mp.id_ricetta
WHERE rs.id_utente = ?
ORDER BY rs.salvato_il DESC
LIMIT 50
```

### 3. Renderizzazione
Mostra le ricette come card (stesso layout della home).
Il pulsante "Rimuovi dai salvati" linka a:
`home.jsp?azione=salva&tipo=rimuovi&id=N`

## Parametri GET
Nessuno. Mostra sempre le ricette dell'utente loggato.

## Interazione con classi Java
- **`Db.getConnection()`**
- **`RicettaCard`** — bean per ogni ricetta nella griglia
- **`UrlUtils.risolvi()`** — per URL immagini
