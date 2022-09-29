window.addEventListener('DOMContentLoaded', () => {
  const searchBarBtn = document.querySelector('.searchbar-btn');
  const searchBarForm = document.querySelector('.searchbar-form');
  const searchBarInput = document.querySelector('.searchbar-form input[type="text"]');
  const searchBarHome = document.querySelector('.page-home .searchbar-form');

  // Remove the searchbar from the navbar on the homepage because
  // it intereferes with the autocomplete-suggestions on the homepage search
  if (searchBarHome) {
    searchBarHome.remove();
  }

  searchBarBtn.addEventListener('click', () => {
    searchBarForm.classList.remove('visible-md');
    searchBarForm.classList.remove('visible-lg');
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
      if (searchBarInput === document.activeElement) {
        searchBarForm.classList.add('searchbar-open');
        searchBarForm.classList.remove('visible-md');
        searchBarForm.classList.remove('visible-lg');
      } else {
        searchBarForm.classList.remove('searchbar-open');
        searchBarForm.classList.add('visible-md');
        searchBarForm.classList.add('visible-lg');
      }
    }
  }

  document.body.addEventListener('click', showSearchBar);

  window.addEventListener('resize', () => {
    const searchBarOpenInput = document.querySelector('.searchbar-form.searchbar-open input[type="text"]');
    if (searchBarOpenInput) {
      if (searchBarInput === document.activeElement) {
        if (document.body.clientWidth >= 992) {
          searchBarForm.classList.remove('searchbar-open');
          searchBarForm.classList.add('visible-md');
          searchBarForm.classList.add('visible-lg');
        } else {
          searchBarForm.classList.add('searchbar-open');
          searchBarForm.classList.remove('visible-md');
          searchBarForm.classList.remove('visible-lg');
        }
      }
    }
  });
});
