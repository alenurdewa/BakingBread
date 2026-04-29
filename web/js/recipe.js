function rimuoviRiga(button) {
    const row = button.closest('.row-item, .step-row');
    if (!row) return;
    const container = row.parentElement;
    if (container.children.length > 1) {
        row.remove();
    }
}

function aggiungiIngrediente() {
    const container = document.getElementById('ingredienti-container');
    if (!container) return;
    const row = document.createElement('div');
    row.className = 'row-item';
    row.innerHTML = '<input type="text" name="ingrediente_nome" placeholder="Ingrediente" required><input type="text" name="ingrediente_quantita" placeholder="Quantità"><input type="text" name="ingrediente_unita" placeholder="Unità"><button type="button" class="icon-btn" onclick="rimuoviRiga(this)">×</button>';
    container.appendChild(row);
}

function aggiungiPassaggio() {
    const container = document.getElementById('passaggi-container');
    if (!container) return;
    const row = document.createElement('div');
    row.className = 'step-row';
    row.innerHTML = '<textarea name="passaggio_descrizione" rows="3" placeholder="Descrivi questo passaggio..." required></textarea><button type="button" class="icon-btn" onclick="rimuoviRiga(this)">×</button>';
    container.appendChild(row);
}

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
