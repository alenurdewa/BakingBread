/*
 * ============================================================
 * FILE: home.js
 * SCOPO: Piccoli miglioramenti visivi per la home page.
 *        Gestisce il feedback visivo istantaneo sui pulsanti
 *        like e salva, prima che la pagina si ricarichi.
 * ============================================================
 */

// Aspetta che il documento sia completamente caricato
document.addEventListener("DOMContentLoaded", function() {

    // Recupera tutti i pulsanti azione (like e salva)
    var pulsantiAzione = document.querySelectorAll(".action-btn");

    // Scorre tutti i pulsanti e aggiunge un listener al click
    for (var i = 0; i < pulsantiAzione.length; i++) {

        pulsantiAzione[i].addEventListener("click", function() {
            // Aggiunge temporaneamente una classe di feedback visivo
            // (il pulsante "lampeggia" per indicare che il click è stato ricevuto)
            this.style.opacity = "0.5"; // Abbassa l'opacità a metà
        });
    }
});
