// ==UserScript==
// @name            Search YouTube and More From Within Google
// @description     Adds icons next to Google's search bar which let you search from other sites.
// @match   https://www.google.com/search*
// ==/UserScript==

const newButtonsList = [
    [ 'Yandex', 'https://yandex.com/', 'search/?text=', 'https://yandex.com/favicon.ico'],
    [ 'Bing', 'https://www.bing.com/', 'search?q=', 'https://www.bing.com/favicon.ico'],
    [ 'DuckDuckGo', 'https://duckduckgo.com/', '?q=', 'https://www.duckduckgo.com/favicon.ico'],
    [ 'Startpage', 'https://www.startpage.com/', 'do/search?q=', 'https://www.startpage.com/favicon.ico'],
    [ 'Brave Search', 'https://search.brave.com/', 'search?q=', 'https://brave.com/static-assets/images/brave-favicon.png'],
    [ 'Qwant', 'https://www.qwant.com/', '?q=', 'https://www.qwant.com/favicon.ico'],
    [ 'Searx', 'https://search.inetol.net/', 'search?q=', 'https://search.inetol.net/favicon.ico'],
    [ 'Yahoo', 'https://search.yahoo.com/', 'search?p=', 'https://www.yahoo.com/favicon.ico'],
    [ 'Perplexity', 'https://www.perplexity.ai/', 'search?q=', 'https://www.google.com/s2/favicons?domain=perplexity.ai&sz=32'],
    [ 'Ecosia', 'https://www.ecosia.org/', 'search?q=', 'https://www.ecosia.org/favicon.ico'],
    [ 'Reddit', 'https://www.reddit.com/', 'search?q=', 'https://www.reddit.com/favicon.ico'],
    [ 'Medium', 'https://medium.com/', 'search?q=', 'https://www.google.com/s2/favicons?domain=medium.com&sz=32'],
    [ 'Wikipedia', 'https://en.wikipedia.org/', 'wiki/Special:Search?search=', 'https://en.wikipedia.org/favicon.ico'],
    [ 'ChatGPT', 'https://chat.openai.com/', '?q=', 'https://chat.openai.com/favicon.ico'],
    [ 'Quora', 'https://www.quora.com/', 'search?q=', 'https://www.quora.com/favicon.ico'],
    [ 'Github ', 'https://github.com/', 'search?q=', 'https://github.com/favicon.ico'],
    [ 'Stack Overflow', 'https://stackoverflow.com/', 'search?q=', 'https://stackoverflow.com/favicon.ico'],
    [ 'LibGen', 'https://libgen.is/', 'search.php?req=', 'https://libgen.is/favicon.ico'],
    [ 'Internet Archive', 'https://archive.org/', 'search.php?query=', 'https://archive.org/favicon.ico']
]

let searchForm = document.querySelector('*[name="q"]');
let searchTerms = searchForm.value;

if (searchForm) {
    searchForm.addEventListener('input', function(event) {
        searchTerms = event.target.value;
        letsRock(true);
    });
}

let newButtonsHTML = ''

function makeButtonsHTML() {
    newButtonsHTML = '<div class="customSearch">';
    for ( var i = 0; i < newButtonsList.length; i++ ) {
        newButtonsHTML = newButtonsHTML.concat( '<a title="', newButtonsList[i][0], '" class="customSearchItem" href="', newButtonsList[i][1] );
        if (searchTerms) { newButtonsHTML = newButtonsHTML.concat( newButtonsList[i][2], encodeURIComponent(searchTerms) ) }
        newButtonsHTML = newButtonsHTML.concat( '" target="_self"><span><img src="', newButtonsList[i][3], '" /></span></a>');
    }
    newButtonsHTML = newButtonsHTML.concat( '</div>' );
}

function letsRock(update) {
    var container = document.querySelector('.customSearch');
    if (!update && container ) { return }
    makeButtonsHTML();
    var insertHere = document.querySelector('button[aria-label="Search"]') || document.querySelector('button[aria-label="Google Search"]') || document.querySelector('div[aria-label="Search by image"]');
    /* First one is for most results pages such as All, News, Videos, Books, etc. Second one is for the Images results page. Third one is for Google's home page. */
    if (container) { container.remove() }
    insertHere.insertAdjacentHTML('afterend', newButtonsHTML);
}

const bodyColor = window.getComputedStyle(document.querySelector('body')).backgroundColor;

const buttonWidth = Math.ceil(newButtonsList.length / 2) * 16;

document.body.appendChild(document.createElement('style')).textContent = `
    .customSearch {
        position: relative;
        left: 10px;
        display: flex;
        flex-flow: column wrap;
        align-items: center;
        justify-content: space-around;
        gap: 4px;
        height: 44px;
        width: 0;
        padding: 0;
    }
    .customSearchItem:hover {
        filter: drop-shadow(1px 1px 1px #000)
            drop-shadow(0px 0px 2px #8b9ba1)
            drop-shadow(0px 0px 2px #8b9ba1)
            drop-shadow(0px 0px 2px #8b9ba1)
            drop-shadow(0px 0px 2px #8b9ba1);
    }
    .customSearchItem {
        display: flex;
        height: 18px;
        width: 18px;
        padding: 1px 5px;
        margin: 0px;
    }
    .customSearchItem svg,
    .customSearchItem img,
    .customSearchItem > span {
        height: 16px;
        width: 16px;
    }
    /* .minidiv = when search box is fixed to the top after scrolling down  */
    .minidiv .RNNXgb {
        margin-top: 10px !important;
        height: 32px !important;
    }
    .minidiv .customSearch {
        margin: -6px 0;
    }
    /* for Google.com home page */
    div[aria-label="Search by image"] + .customSearch {
        left: 20px;
    }
    /* centering on home page  */
    .o3j99.ikrT4e.om7nvf .A8SBwf[jscontroller="cnjECf"] {
        position: relative;
        left: -`+ buttonWidth +`px;
    }
    .o3j99.ikrT4e.om7nvf .FPdoLc.lJ9FBc {
        position: relative;
        left: `+ buttonWidth +`px;
    }
    /* for Google doodle underneath buttons  */
    .customSearch:before {
        z-index: -1;
        position: absolute;
        left: 0;
        content: "";
        background-color: `+ bodyColor +`;
        opacity: .8;
        width: `+ (buttonWidth * 2) +`px;
        height: 55px;
    }
    .minidiv .customSearch:before {
        opacity: 0;
    }
`;

letsRock();