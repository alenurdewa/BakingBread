# dettaglio_ricetta.jsp

## Descrizione
Mostra tutti i dettagli di una singola ricetta: immagine, informazioni, ingredienti, passaggi e commenti. Gestisce anche l'invio di nuovi commenti e risposte.

## Funzionamento passo per passo

### POST — Inserimento commento
Se la richiesta è POST:
1. Legge `testo` e `id_parent` (0 = commento principale, >0 = risposta).
2. Inserisce con:
   ```sql
   INSERT INTO Commento (id_ricetta, id_utente, id_parent, testo) VALUES (?,?,?,?)
   ```
   Se `id_parent == 0`, salva `NULL` nel DB.
3. Reindirizza a `dettaglio_ricetta.jsp?id=N#commenti`.

### GET — Caricamento dati
Tutte le query usano il pattern **conta → crea array → riempi**:

1. **Dati ricetta** (unica query con JOIN e aggregazione per like/salvataggi).
2. **Ingredienti**:
   ```java
   Ingrediente[] ingredienti = new Ingrediente[numIng];
   ```
3. **Passaggi**:
   ```java
   Passaggio[] passaggi = new Passaggio[numPass];
   ```
4. **Commenti** (tutti, principali + risposte in un unico array):
   ```java
   Commento[] commenti = new Commento[numCom];
   ```

### Renderizzazione commenti annidati
I commenti vengono mostrati con un doppio ciclo **O(n²)** — semplice e senza strutture dati complesse:
```java
// Ciclo esterno: solo commenti principali (idParent == 0)
for (int i = 0; i < commenti.length; i++) {
    if (commenti[i].getIdParent() == 0) {
        // mostra commento principale
        // Ciclo interno: cerca le risposte
        for (int j = 0; j < commenti.length; j++) {
            if (commenti[j].getIdParent() == commenti[i].getIdCommento()) {
                // mostra risposta
            }
        }
    }
}
```

## Parametri GET
| Parametro | Obbligatorio | Descrizione |
|-----------|:---:|-------------|
| `id` | ✓ | ID della ricetta da visualizzare |

## Parametri POST
| Campo | Obbligatorio | Descrizione |
|-------|:---:|-------------|
| `testo` | ✓ | Testo del commento |
| `id_parent` | | ID commento padre (0 = principale) |

## Interazione con classi Java
- **`Db.getConnection()`**
- **`Ingrediente`** — bean per ogni ingrediente
- **`Passaggio`** — bean per ogni step
- **`Commento`** — bean per ogni commento/risposta
- **`UrlUtils.risolvi()`** — per URL immagini e avatar

## File collegati
- JavaScript inline nella pagina: `toggleRispostaForm(id)` per mostrare/nascondere i form di risposta
- `css/recipe.css` + `css/messages.css` (per avatar)
