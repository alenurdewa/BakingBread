document.addEventListener('DOMContentLoaded', () => {
    const togglePassword = document.querySelector('#togglePassword');
    const password = document.querySelector('#password');
    const form = document.querySelector('#registerForm');

    // Toggle Password
    if(togglePassword && password) {
        togglePassword.addEventListener('click', function () {
            const type = password.getAttribute('type') === 'password' ? 'text' : 'password';
            password.setAttribute('type', type);
            this.textContent = type === 'password' ? '👁️' : '🙈';
        });
    }

    // Validazione base Frontend
    if(form) {
        form.addEventListener('submit', function(event) {
            if (password.value.length < 6) {
                event.preventDefault(); // Blocca l'invio del form
                alert('Attenzione: La password deve contenere almeno 6 caratteri!');
                password.focus();
            }
        });
    }
});