// Funzione per switchare tra le tab
function switchTab(tabId, element) {
    var contents = document.querySelectorAll('.tab-content');
    contents.forEach(function(content) {
        content.style.display = 'none';
    });

    var buttons = document.querySelectorAll('.tab-btn');
    buttons.forEach(function(btn) {
        btn.classList.remove('active');
    });

    document.getElementById(tabId).style.display = 'grid';
    element.classList.add('active');
}

// Logica per convertire l'immagine selezionata in Base64 e inserirla nell'input nascosto
document.addEventListener("DOMContentLoaded", function() {
    var fileInput = document.getElementById('fileInput');
    var avatarBase64Input = document.getElementById('avatar_base64');

    if(fileInput) {
        fileInput.addEventListener('change', function(event) {
            var file = event.target.files[0];
            if (file) {
                var reader = new FileReader();
                reader.onload = function(e) {
                    // Imposta la stringa base64 nell'input nascosto
                    avatarBase64Input.value = e.target.result;
                };
                reader.readAsDataURL(file);
            }
        });
    }
});