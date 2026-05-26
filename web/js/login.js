/*
 * ============================================================
 * FILE: login.js
 * SCOPO: Gestisce il pulsante "mostra/nascondi password"
 *        nella pagina di login.
 * ============================================================
 */

// Aspetta che tutto il documento HTML sia stato caricato
document.addEventListener("DOMContentLoaded", function() {

    // Recupera il pulsante occhio e il campo password dalla pagina
    var pulsante     = document.getElementById("togglePassword"); // Pulsante 👁
    var campoPassword = document.getElementById("password");      // Input password

    // Controlla che entrambi gli elementi esistano nella pagina
    if (pulsante && campoPassword) {

        // Aggiunge il listener per il click sul pulsante occhio
        pulsante.addEventListener("click", function() {

            // Legge il tipo attuale del campo: "password" o "text"
            var tipoAttuale = campoPassword.getAttribute("type");

            if (tipoAttuale === "password") {
                // Era nascosta: la rende visibile come testo normale
                campoPassword.setAttribute("type", "text");
                pulsante.textContent = "🙈"; // Cambia l'icona
            } else {
                // Era visibile: la nasconde di nuovo
                campoPassword.setAttribute("type", "password");
                pulsante.textContent = "👁"; // Ripristina l'icona
            }
        });
    }
});
