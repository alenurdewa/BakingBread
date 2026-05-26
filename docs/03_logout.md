# logout.jsp

## Descrizione
Pagina di disconnessione. Non ha interfaccia grafica: esegue solo la logica Java e poi reindirizza l'utente.

## Funzionamento passo per passo

1. Recupera la sessione corrente **senza crearne una nuova** (`request.getSession(false)`).
   Il parametro `false` è importante: se non c'è una sessione attiva, non ne crea una nuova.
2. Se la sessione esiste, chiama `session.invalidate()` che la distrugge completamente.
   Dopo questa chiamata tutti gli attributi (`id_utente`, `username`, ecc.) vengono cancellati.
3. Reindirizza il browser a `login.jsp`.

## Parametri ricevuti
Nessuno. La pagina non legge parametri dall'URL né dal body.

## Gestione sessione
Distrugge la sessione corrente:
```java
HttpSession sessione = request.getSession(false);
if (sessione != null) { sessione.invalidate(); }
```

## Interazione con classi Java
Nessuna. Non accede al database.

## Note
Questa pagina può essere raggiunta tramite il link "Esci" nel menu a tendina della navbar.
