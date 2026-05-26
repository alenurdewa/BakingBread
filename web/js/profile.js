/*
 * ============================================================
 * FILE: profile.js
 * SCOPO: Gestisce la pagina impostazioni.
 *        Mostra l'anteprima dell'avatar prima del caricamento.
 * ============================================================
 */

/**
 * Mostra un'anteprima dell'immagine avatar selezionata dall'utente.
 * Viene chiamata dall'attributo onchange del campo <input type="file">.
 *
 * @param {HTMLInputElement} input - Il campo file da cui leggere l'immagine
 */
function anteprimaAvatar(input) {
    // Controlla se l'utente ha selezionato almeno un file
    if (input.files && input.files[0]) {

        // FileReader permette di leggere il file localmente nel browser
        // senza necessità di caricarlo sul server
        var reader = new FileReader();

        // Callback: eseguita quando la lettura del file è completata
        reader.onload = function(evento) {

            // Cerca l'elemento di anteprima nella pagina
            var preview = document.getElementById("avatarPreview");

            if (preview) {
                // Se è un tag <img>, aggiorna il src con i dati del file
                if (preview.tagName === "IMG") {
                    preview.src = evento.target.result; // Dati base64 dell'immagine

                } else {
                    // Se è uno <span> (il fallback con la lettera),
                    // lo sostituisce con un tag <img>
                    var img = document.createElement("img");   // Crea un nuovo img
                    img.src = evento.target.result;             // Imposta il src
                    img.id = "avatarPreview";                   // Stesso ID
                    img.className = preview.className;          // Stessa classe CSS
                    img.alt = "Avatar anteprima";

                    // Sostituisce lo span con l'immagine nel DOM
                    preview.parentNode.replaceChild(img, preview);
                }
            }
        };

        // Avvia la lettura del file come URL base64
        reader.readAsDataURL(input.files[0]);
    }
}
