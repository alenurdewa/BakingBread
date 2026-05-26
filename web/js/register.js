/*
 * ============================================================
 * FILE: register.js
 * SCOPO: Gestisce la pagina di registrazione:
 *        1. Toggle mostra/nascondi password
 *        2. Verifica lato client che le password coincidano
 * ============================================================
 */

// Aspetta che il DOM sia completamente caricato
document.addEventListener("DOMContentLoaded", function() {

    // ----- Toggle mostra/nascondi password -----

    var btnToggle        = document.getElementById("togglePassword");    // Pulsante 👁
    var campoPassword    = document.getElementById("password");           // Campo password
    var campoConferma    = document.getElementById("conferma_password");  // Campo conferma

    // Attiva il toggle solo se il pulsante esiste nella pagina
    if (btnToggle && campoPassword) {
        btnToggle.addEventListener("click", function() {

            // Determina il tipo attuale del campo password
            var tipo = campoPassword.getAttribute("type");

            if (tipo === "password") {
                // Rende visibile la password
                campoPassword.setAttribute("type", "text");
                // Rende visibile anche il campo di conferma (se esiste)
                if (campoConferma) {
                    campoConferma.setAttribute("type", "text");
                }
                btnToggle.textContent = "🙈"; // Cambia icona
            } else {
                // Nasconde di nuovo la password
                campoPassword.setAttribute("type", "password");
                if (campoConferma) {
                    campoConferma.setAttribute("type", "password");
                }
                btnToggle.textContent = "👁"; // Ripristina icona
            }
        });
    }

    // ----- Validazione client-side: password uguali -----

    var form = document.getElementById("registerForm"); // Il form di registrazione

    if (form) {
        // Aggiunge un listener sull'evento "submit" del form
        form.addEventListener("submit", function(event) {

            // Legge i valori dei due campi password
            var pwd1 = campoPassword    ? campoPassword.value    : "";
            var pwd2 = campoConferma    ? campoConferma.value    : "";

            // Se le password non coincidono, blocca l'invio del form
            if (pwd1 !== pwd2) {
                event.preventDefault(); // Impedisce l'invio
                // Mostra un messaggio di errore all'utente
                alert("Le due password non corrispondono. Riprova.");
                // Porta il focus al secondo campo per facilitare la correzione
                if (campoConferma) {
                    campoConferma.focus();
                }
            }
        });
    }
});
