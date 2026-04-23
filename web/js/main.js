/* file: webapp/js/main.js */

// Gestione Anteprima Immagine e Conversione Base64
function handleImageUpload(event) {
    const file = event.target.files[0];
    if (file) {
        const reader = new FileReader();
        reader.onload = function(e) {
            const base64String = e.target.result;
            // Mostra l'anteprima
            const uploadBox = document.getElementById('imagePreviewBox');
            uploadBox.style.backgroundImage = 'url(' + base64String + ')';
            uploadBox.style.backgroundSize = 'cover';
            uploadBox.style.backgroundPosition = 'center';
            uploadBox.querySelector('p').style.display = 'none'; // Nasconde il testo "+"
            
            // Inserisce il Base64 nell'input nascosto per il database
            document.getElementById('immagine_base64_input').value = base64String;
        };
        reader.readAsDataURL(file);
    }
}

// Gestione Stelle (Rating)
function setRating(stars) {
    document.getElementById('rating_input').value = stars;
    const starElements = document.querySelectorAll('.star-btn');
    starElements.forEach((star, index) => {
        if (index < stars) {
            star.classList.add('active');
            star.innerHTML = '★';
        } else {
            star.classList.remove('active');
            star.innerHTML = '☆';
        }
    });
}

// Animazione Bottoni Like
function toggleLike(btn) {
    btn.classList.toggle('liked');
    if(btn.classList.contains('liked')) {
        btn.style.color = 'var(--primary-color)';
        btn.style.transform = 'scale(1.1)';
        setTimeout(() => btn.style.transform = 'scale(1)', 200);
    } else {
        btn.style.color = 'var(--text-muted)';
    }
}