# 12 – File JavaScript — Spiegazione riga per riga

## Panoramica

Il JavaScript in BakingBread è volutamente minimale: la logica principale è lato server (JSP/Servlet). Il JS gestisce solo l'interattività dell'interfaccia utente (animazioni, preview immagini, dropdown, toggle). Non usa framework (niente jQuery, React, Vue).

---

# `main.js` — Logica globale

## Scopo del file
Funzioni usate in tutte le pagine. Incluso in quasi tutti i JSP con:
```html
<script src="${pageContext.request.contextPath}/js/main.js"></script>
```

---

## Analisi riga per riga

```javascript
function toggleDropdown(event) {
    event.preventDefault();
    event.stopPropagation();
    var dropdown = event.currentTarget.closest('.dropdown');
    if (!dropdown) return;
    dropdown.classList.toggle('open');
}
```

Gestisce l'apertura/chiusura del menu dropdown nella navbar.

- `event.preventDefault()` → impedisce il comportamento default del click sul link (navigare all'URL `href`)
- `event.stopPropagation()` → impedisce la propagazione dell'evento verso gli elementi parent. **Cruciale**: senza questo, il click raggiungerebbe il `document` e il listener sotto (che chiude tutti i dropdown) si attiverebbe immediatamente dopo l'apertura, richiudendo subito il menu
- `event.currentTarget` → l'elemento su cui è stato registrato l'event listener (il pulsante `▾`)
- `.closest('.dropdown')` → risale il DOM cercando l'antenato più vicino con classe `.dropdown`. Evita di dover conoscere la struttura esatta del DOM
- `classList.toggle('open')` → aggiunge la classe `open` se non c'è, la rimuove se c'è (toggle). La classe `open` è definita nel CSS e rende visibile il menu

```javascript
document.addEventListener('click', function () {
    document.querySelectorAll('.dropdown.open').forEach(function (menu) {
        menu.classList.remove('open');
    });
});
```

Chiude tutti i dropdown aperti quando l'utente clicca **ovunque** nel documento. Questo è il pattern standard per i dropdown: cliccare fuori li chiude. `querySelectorAll('.dropdown.open')` seleziona tutti gli elementi con entrambe le classi `dropdown` E `open`. `forEach` itera su tutti e rimuove la classe `open`.

**Perché funziona con `stopPropagation` nel pulsante?** Quando si clicca sul pulsante del dropdown, l'evento: 1) apre il dropdown (`toggle`), 2) viene fermato da `stopPropagation` e NON arriva al document. Quando si clicca altrove, l'evento arriva al document e chiude tutti i dropdown aperti.

---

# `recipe.js` — Interattività form ricetta

## Scopo del file
Gestisce la lista dinamica di ingredienti e passaggi nel form `crea_ricetta.jsp`.

---

## Analisi riga per riga

```javascript
function rimuoviRiga(button) {
    const row = button.closest('.row-item, .step-row');
    if (!row) return;
    const container = row.parentElement;
    if (container.children.length > 1) {
        row.remove();
    }
}
```

Rimuove una riga ingrediente o passaggio quando si clicca "×".

- `button.closest('.row-item, .step-row')` → cerca il div contenitore della riga (accetta sia `.row-item` per gli ingredienti che `.step-row` per i passaggi)
- `container.children.length > 1` → non rimuove l'ultima riga. Deve rimanere almeno un ingrediente/passaggio nel form. Il form HTML ha `required` sugli input, quindi senza almeno un ingrediente il form non si invierebbe comunque
- `row.remove()` → rimuove l'elemento dal DOM

```javascript
function aggiungiIngrediente() {
    const container = document.getElementById('ingredienti-container');
    if (!container) return;
    const row = document.createElement('div');
    row.className = 'row-item';
    row.innerHTML = '<input type="text" name="ingrediente_nome" placeholder="Ingrediente" required>' +
                    '<input type="text" name="ingrediente_quantita" placeholder="Quantità">' +
                    '<input type="text" name="ingrediente_unita" placeholder="Unità">' +
                    '<button type="button" class="icon-btn" onclick="rimuoviRiga(this)">×</button>';
    container.appendChild(row);
}
```

Aggiunge una nuova riga ingrediente dinamicamente.

- `document.createElement('div')` → crea un nuovo elemento `<div>` nel DOM (non ancora visibile)
- `row.className = 'row-item'` → imposta la classe CSS
- `row.innerHTML = '...'` → imposta il contenuto HTML interno. I campi hanno gli stessi `name` delle righe generate dal JSP: quando il form viene inviato, il server riceve tutti i valori come array (`request.getParameterValues("ingrediente_nome")`)
- `container.appendChild(row)` → aggiunge la nuova riga alla fine del container

**Importante**: i campi nuovi hanno `name="ingrediente_nome"` (uguale agli altri). HTTP invia tutti i campi con lo stesso nome come array. Il server li processa in ordine di apparizione nel DOM.

```javascript
function aggiungiPassaggio() {
    const container = document.getElementById('passaggi-container');
    if (!container) return;
    const row = document.createElement('div');
    row.className = 'step-row';
    row.innerHTML = '<textarea name="passaggio_descrizione" rows="3" placeholder="Descrivi questo passaggio..." required></textarea>' +
                    '<button type="button" class="icon-btn" onclick="rimuoviRiga(this)">×</button>';
    container.appendChild(row);
}
```

Identica logica di `aggiungiIngrediente` ma per i passaggi, con un `<textarea>` invece di tre input.

```javascript
function handleRecipeImagePreview(input) {
    const box = document.getElementById('imagePreviewBox');
    if (!box) return;
    const file = input.files && input.files[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = function (e) {
        box.innerHTML = '<img src="' + e.target.result + '" alt="Anteprima" class="image-preview-img">';
    };
    reader.readAsDataURL(file);
}
```

Mostra un'anteprima dell'immagine selezionata prima dell'upload.

- `input.files[0]` → il primo file selezionato dall'utente. `input.files` è un `FileList` (oggetto simile a un array)
- `new FileReader()` → oggetto API Web che legge file dal filesystem dell'utente (solo file già selezionati dall'utente)
- `reader.onload = function(e) {...}` → callback eseguita quando la lettura è completata. `e.target.result` contiene il file come stringa base64 (`data:image/jpeg;base64,...`)
- `reader.readAsDataURL(file)` → avvia la lettura asincrona del file. Quando finisce, chiama `onload`
- `box.innerHTML = '<img src="..." ...>'` → sostituisce il contenuto del box di anteprima con l'immagine

**Perché base64?** `readAsDataURL` produce una stringa che può essere usata direttamente come `src` di un `<img>` senza fare una richiesta HTTP separata. Perfetto per anteprime.

---

# `profile.js` — Preview avatar impostazioni

## Scopo del file
Gestisce la preview dell'avatar nel form di `impostazioni.jsp`.

---

## Analisi riga per riga

```javascript
function previewProfileAvatar(input) {
    const file = input.files && input.files[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = function (e) {
        const preview = document.getElementById('avatarPreview');
        if (!preview) return;
        if (preview.tagName.toLowerCase() === 'img') {
            preview.src = e.target.result;
        } else {
            preview.classList.remove('settings-avatar-fallback');
            preview.style.backgroundImage = 'url(' + e.target.result + ')';
            preview.style.backgroundSize = 'cover';
            preview.style.backgroundPosition = 'center';
            preview.textContent = '';
        }
    };
    reader.readAsDataURL(file);
}
```

Simile a `handleRecipeImagePreview` ma gestisce due casi diversi per l'elemento di anteprima:

**Se l'elemento è un `<img>`** (l'utente ha già un avatar):
- `preview.src = e.target.result` → aggiorna direttamente la sorgente dell'immagine

**Se l'elemento è un `<div>`** (l'utente non ha avatar, mostrava la lettera iniziale):
- `preview.classList.remove('settings-avatar-fallback')` → rimuove la classe CSS che mostrava il background colorato
- `preview.style.backgroundImage = 'url(...)'` → imposta l'immagine come sfondo
- `preview.style.backgroundSize = 'cover'` → l'immagine copre tutto il div
- `preview.textContent = ''` → rimuove il testo (la lettera iniziale del nome)

`preview.tagName.toLowerCase() === 'img'` → `.tagName` restituisce il nome del tag in maiuscolo (`"IMG"`), `.toLowerCase()` lo converte per confronto case-insensitive.

---

# `login.js` — Validazione form login

## Scopo del file
Toggle visibilità password e validazione client-side del form di login.

---

## Analisi riga per riga

```javascript
document.addEventListener('DOMContentLoaded', () => {
    const togglePassword = document.querySelector('#togglePassword');
    const password = document.querySelector('#password');
    const form = document.querySelector('#registerForm');
```

`DOMContentLoaded` → evento che si attiva quando il DOM è completamente parsato (ma prima che le immagini siano caricate). Usato per assicurarsi che gli elementi esistano prima di registrare i listener.

**Nota**: questo file usa `#togglePassword` e `#registerForm` che non esistono in `login.jsp` (ci sono `#eyeIcon` e il form non ha ID). Probabilmente è un file residuo di una versione precedente. Il toggle della password in `login.jsp` è gestito da una funzione `togglePassword()` definita inline nella pagina.

```javascript
    if(form) {
        form.addEventListener('submit', function(event) {
            if (password.value.length < 6) {
                event.preventDefault();
                alert('Attenzione: La password deve contenere almeno 6 caratteri!');
                password.focus();
            }
        });
    }
```

Validazione client-side: impedisce l'invio del form se la password è troppo corta. `event.preventDefault()` blocca l'invio del form. `password.focus()` rimette il cursore nel campo password per comodità.

---

# `home.js` — Gestione like (frontend-only)

## Scopo del file
Gestione pulsanti "Mi Piace" lato client. **Attenzione**: questo file è un residuo di una versione precedente. In `home.jsp` i like sono gestiti via form POST al server. Questo JS non ha effetto nella versione attuale.

---

## Analisi riga per riga

```javascript
document.addEventListener('DOMContentLoaded', () => {
    const likeButtons = document.querySelectorAll('.btn-like');
    
    likeButtons.forEach(button => {
        button.addEventListener('click', function() {
            this.classList.toggle('active');
            
            if(this.classList.contains('active')) {
                this.textContent = 'Ti piace';
            } else {
                this.textContent = 'Mi Piace';
            }
            
            // In un'app reale, qui faresti una chiamata AJAX (fetch) 
            // al server per salvare il Mi Piace nella tabella 'mi_piace' del Database.
        });
    });
});
```

Seleziona tutti i bottoni con classe `.btn-like` (che non esistono nella versione corrente di `home.jsp`, che usa `.action-btn`). Il commento nel codice spiega l'evoluzione pianificata: usare fetch/AJAX invece del submit di un form HTML, che non richiederebbe il refresh della pagina.

---

# `register.js.js` — Toggle password registrazione

## Nota: nome file anomalo
Il file ha doppia estensione `.js.js` per un probabile errore di rinomina. Non viene incluso in nessuna JSP (non c'è un `<script src=".../register.js.js">`). La funzionalità è riprodotta inline in `register.jsp`.

```javascript
document.addEventListener('DOMContentLoaded', () => {
    const togglePassword = document.querySelector('#togglePassword');
    const password = document.querySelector('#password');

    if(togglePassword && password) {
        togglePassword.addEventListener('click', function () {
            const type = password.getAttribute('type') === 'password' ? 'text' : 'password';
            password.setAttribute('type', type);
            this.textContent = type === 'password' ? '👁️' : '🙈';
        });
    }
});
```

Toggle della visibilità della password con cambio emoji (👁️/🙈). Usa `getAttribute/setAttribute` invece della proprietà diretta `.type` per maggiore compatibilità.

---

## Riepilogo: quali JS sono effettivamente usati

| File | Incluso in | Funzioni attive |
|------|-----------|-----------------|
| `main.js` | Quasi tutte le JSP | `toggleDropdown()`, chiusura dropdown |
| `recipe.js` | `crea_ricetta.jsp` | `aggiungiIngrediente()`, `aggiungiPassaggio()`, `rimuoviRiga()`, `handleRecipeImagePreview()` |
| `profile.js` | `impostazioni.jsp` | `previewProfileAvatar()` |
| `login.js` | `login.jsp` | Nessuna (selettori errati, non trova gli elementi) |
| `home.js` | Nessuno (non incluso) | — |
| `register.js.js` | Nessuno (non incluso) | — |
