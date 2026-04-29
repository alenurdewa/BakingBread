function toggleDropdown(event) {
    event.preventDefault();
    event.stopPropagation();
    var dropdown = event.currentTarget.closest('.dropdown');
    if (!dropdown) return;
    dropdown.classList.toggle('open');
}

document.addEventListener('click', function () {
    document.querySelectorAll('.dropdown.open').forEach(function (menu) {
        menu.classList.remove('open');
    });
});
