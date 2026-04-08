const searchBarBtn = document.querySelector('.searchbar-btn');
const searchBarForm = document.querySelector('.searchbar-form');
const searchBarInput = document.querySelector('.searchbar-form input[type="text"]');

searchBarBtn.addEventListener('click', () => {
    searchBarForm.classList.add('searchbar-open');
    searchBarInput.focus();

    // Set the width of the autocomplete suggestions when searchbar button gets clicked
    const autocompleteSuggestions = document.querySelector('.autocomplete-suggestions');
    const searchBarFormWidth = `${searchBarForm.offsetWidth}px`;
    autocompleteSuggestions.style.width = searchBarFormWidth;
});

const showSearchBar = () => {
    const searchBarOpenInput = document.querySelector('.searchbar-form.searchbar-open input[type="text"]');
    if (searchBarOpenInput) {
        if (searchBarInput !== document.activeElement) {
            searchBarForm.classList.remove('searchbar-open');
        }
    }
};

document.body.addEventListener('click', showSearchBar);

const mql = window.matchMedia('(min-width: 768px)');
mql.addEventListener('change', (e) => {
    if (e.matches) {
        searchBarForm.classList.remove('searchbar-open');
    }
});
