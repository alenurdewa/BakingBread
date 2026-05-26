/*
 * ============================================================
 * FILE: main.js
 * SCOPO: Gestisce il menu a tendina (dropdown) della navbar.
 * Viene incluso nella navbar.jsp.
 * ============================================================
 */

/**
 * Apre o chiude il dropdown della navbar.
 * Viene chiamata dal pulsante avatar nella navbar.
 *
 * @param {Event} event - L'evento click del pulsante
 */
function toggleDropdown(event) {
    // Impedisce all'evento di propagarsi al documento
    // (altrimenti si chiuderebbe subito dopo apertura)
    event.stopPropagation();

    // Cerca il div con classe "dropdown" più vicino al pulsante cliccato
    var dropdownContainer = event.currentTarget.closest(".dropdown");

    // Se non trova il contenitore, esce dalla funzione
    if (!dropdownContainer) {
        return;
    }

    // Cerca il menu (il div figlio con classe "dropdown-menu")
    var menu = dropdownContainer.querySelector(".dropdown-menu");

    // Se non trova il menu, esce dalla funzione
    if (!menu) {
        return;
    }

    // Legge lo stato attuale del menu (visibile o nascosto)
    var menuVisibile = menu.style.display === "block";

    // Prima chiude TUTTI i dropdown aperti nella pagina
    chiudiTuttiDropdown();

    // Se il menu era chiuso, lo apre; se era aperto, rimane chiuso
    if (!menuVisibile) {
        menu.style.display = "block"; // Mostra il menu
    }
}

/**
 * Chiude tutti i menu a tendina aperti nella pagina.
 */
function chiudiTuttiDropdown() {
    // Recupera tutti i dropdown-menu presenti nella pagina
    var tuttiMenu = document.querySelectorAll(".dropdown-menu");

    // Scorre l'array dei menu e li nasconde tutti
    for (var i = 0; i < tuttiMenu.length; i++) {
        tuttiMenu[i].style.display = "none"; // Nasconde il menu
    }
}

/*
 * Listener globale: chiude il dropdown se l'utente clicca
 * in qualsiasi altro punto della pagina (fuori dal menu).
 */
document.addEventListener("click", function() {
    chiudiTuttiDropdown(); // Chiude tutti i menu aperti
});
