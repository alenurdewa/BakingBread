/* file: webapp/js/home.js */

document.addEventListener('DOMContentLoaded', () => {
    
    // Gestione del tasto "Mi Piace" (lato frontend)
    const likeButtons = document.querySelectorAll('.btn-like');
    
    likeButtons.forEach(button => {
        button.addEventListener('click', function() {
            // Aggiunge o rimuove la classe 'active' ad ogni click
            this.classList.toggle('active');
            
            // Cambia il testo in base allo stato
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