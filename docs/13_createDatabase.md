# createDatabase.jsp

## Descrizione
Pagina di utilità per inizializzare il database. Legge il file `schema.sql` e lo esegue statement per statement. Da usare **una sola volta** durante il setup iniziale del progetto.

## Funzionamento passo per passo

1. Apre una connessione al DB tramite `Db.getConnection()`.
2. Legge il percorso fisico di `schema.sql`:
   ```java
   String percorso = application.getRealPath("/WEB-INF/sql/schema.sql");
   ```
3. Legge il file riga per riga con `BufferedReader`.
4. Salta righe vuote e commenti (righe che iniziano con `--`).
5. Accumula le righe in un `StringBuilder` fino al punto e virgola `;`.
6. Quando trova il `;`, esegue l'istruzione SQL con `Statement.execute()`.
7. Registra il risultato (OK o WARN) in un array `String[] logMsg`.
8. Mostra tutti i messaggi di log a schermo con colori diversi.

## Output visivo
- ✓ Verde: istruzione eseguita con successo
- ⚠ Arancione: warning (es. tabella già esistente)
- ✕ Rosso: errore grave

## Parametri
Nessuno. Non riceve parametri.

## Note di sicurezza
Questa pagina **non richiede autenticazione** per semplicità didattica. In un progetto reale andrebbe protetta o rimossa dopo l'uso.

## Interazione con classi Java
- **`Db.getConnection()`** — connessione al database
