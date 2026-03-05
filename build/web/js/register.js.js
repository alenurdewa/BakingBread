document.addEventListener('DOMContentLoaded', () => {
    const togglePassword = document.querySelector('#togglePassword');
    const password = document.querySelector('#password');

    if(togglePassword && password) {
        togglePassword.addEventListener('click', function () {
            // Cambia l'attributo type da password a text e viceversa
            const type = password.getAttribute('type') === 'password' ? 'text' : 'password';
            password.setAttribute('type', type);
            // Cambia l'icona
            this.textContent = type === 'password' ? '👁️' : '🙈';
        });
    }
});