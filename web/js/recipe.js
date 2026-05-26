/*
 * ============================================================
 * FILE: recipe.js
 * SCOPO: Gestisce il form di creazione/modifica ricetta.
 *        Permette di aggiungere e rimuovere righe di
 *        ingredienti e passaggi in modo dinamico.
 * ============================================================
 */

/**
 * Aggiunge una nuova riga vuota per un ingrediente.
 * Chiamata dal pulsante "+ Aggiungi" nella sezione ingredienti.
 */
function aggiungiIngrediente() {
    // Trova il contenitore della lista ingredienti
    var lista = document.getElementById("listaIngredienti");

    // Se il contenitore non esiste, esce dalla funzione
    if (!lista) {
        return;
    }

    // Conta quante righe ingrediente esistono già (per dare un ID univoco)
    var indice = lista.querySelectorAll(".ingredient-row").length;

    // Crea un nuovo div che rappresenta la riga dell'ingrediente
    var nuovaRiga = document.createElement("div");        // Crea un div HTML
    nuovaRiga.className = "ingredient-row";               // Aggiunge la classe CSS
    nuovaRiga.id = "ing_" + indice;                       // ID univoco

    // Imposta il contenuto HTML della riga:
    // tre campi di testo + pulsante di rimozione
    nuovaRiga.innerHTML =
        "<input type='text' name='ingrediente_nome' placeholder='Es. Farina 00'>" +
        "<input type='text' name='ingrediente_quantita' placeholder='Quantità'>" +
        "<input type='text' name='ingrediente_unita' placeholder='Unità (g, ml...)'>" +
        "<button type='button' class='btn-danger btn-sm' onclick='rimuoviRiga(this)'>✕</button>";

    // Aggiunge la nuova riga in fondo alla lista
    lista.appendChild(nuovaRiga);

    // Porta il focus al primo campo della riga appena creata
    var primoCampo = nuovaRiga.querySelector("input");
    if (primoCampo) {
        primoCampo.focus(); // Posiziona il cursore sul campo nome
    }
}

/**
 * Aggiunge un nuovo passaggio di preparazione.
 * Chiamata dal pulsante "+ Aggiungi" nella sezione passaggi.
 */
function aggiungiPassaggio() {
    // Trova il contenitore della lista passaggi
    var lista = document.getElementById("listaPassaggi");

    if (!lista) {
        return;
    }

    // Conta i passaggi esistenti per calcolare il numero progressivo
    var indice = lista.querySelectorAll(".step-row").length;

    // Il numero visivo del passaggio (indice + 1 perché si inizia da 1)
    var numPassaggio = indice + 1;

    // Crea la riga del passaggio
    var nuovaRiga = document.createElement("div");
    nuovaRiga.className = "step-row";
    nuovaRiga.id = "pass_" + indice;

    // Imposta il contenuto: numero progressivo + textarea + pulsante rimozione
    nuovaRiga.innerHTML =
        "<span class='step-number'>" + numPassaggio + "</span>" +
        "<textarea name='passaggio_descrizione' rows='3' " +
        "          placeholder='Descrivi questo passaggio...'></textarea>" +
        "<button type='button' class='btn-danger btn-sm' onclick='rimuoviRiga(this)'>✕</button>";

    // Aggiunge la riga in fondo alla lista
    lista.appendChild(nuovaRiga);

    // Porta il focus alla textarea appena creata
    var textarea = nuovaRiga.querySelector("textarea");
    if (textarea) {
        textarea.focus();
    }
}

/**
 * Rimuove la riga (ingrediente o passaggio) che contiene il pulsante cliccato.
 *
 * @param {HTMLElement} pulsante - Il pulsante ✕ cliccato dall'utente
 */
function rimuoviRiga(pulsante) {
    // Il pulsante è figlio diretto della riga da rimuovere
    var riga = pulsante.parentElement; // Risale al div contenitore

    // Controlla che la riga esista prima di rimuoverla
    if (riga) {
        riga.remove(); // Rimuove il div dal DOM

        // Dopo aver rimosso, ricalcola i numeri dei passaggi
        aggiornaNumeriPassaggi();
    }
}

/**
 * Aggiorna i numeri progressivi dei passaggi dopo una rimozione.
 * Es. se si rimuove il passaggio 2, il passaggio 3 diventa il 2.
 */
function aggiornaNumeriPassaggi() {
    // Trova tutti i badge con il numero del passaggio
    var numeri = document.querySelectorAll("#listaPassaggi .step-number");

    // Scorre l'array e aggiorna ogni numero con l'indice corretto
    for (var i = 0; i < numeri.length; i++) {
        numeri[i].textContent = i + 1; // Indice base 1 (1, 2, 3...)
    }
}
