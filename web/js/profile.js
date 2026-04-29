function previewProfileAvatar(input) {
    const file = input.files && input.files[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = function (e) {
        const preview = document.getElementById('avatarPreview');
        if (!preview) return;
        if (preview.tagName.toLowerCase() === 'img') {
            preview.src = e.target.result;
        } else {
            preview.classList.remove('settings-avatar-fallback');
            preview.style.backgroundImage = 'url(' + e.target.result + ')';
            preview.style.backgroundSize = 'cover';
            preview.style.backgroundPosition = 'center';
            preview.textContent = '';
        }
    };
    reader.readAsDataURL(file);
}
