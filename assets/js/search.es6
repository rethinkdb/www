---
---

'use strict';

class RDBSearch {
    constructor() {
        // Algolia connection details
        this.client = new AlgoliaSearch('U39D71436I', 'd39b26296a5e556a451a46b1c9475fe7');
        // Set up the Algolia search index
        this.index = this.client.initIndex('docs');

        // Timer to track when the user last typed in the search box
        this.typing_timer = undefined;
        // Length of time in ms to wait before fetching results
        this.typing_interval = 150;

        // DOM element for search results
        this.$results = undefined;
        // Templates for search results
        this.templates = {
            /* Takes the following parameters
               - title (required): the title of the result
               - snippet (required): the snippet in the result that matched
               - language (required): language of the result
               - url (required): the permalink / URL of the result */
            desktop_result: (title, snippet, language, url) => {
                return `
                    <a href="${url}">
                        <li class="search-result" data-url="${url}">
                            <p>
                                <strong>${title}</strong>&nbsp;<span class="language">${language}</span>
                                <span class="snippet">${snippet}</span>
                            </p>
                        </li>
                    </a>`;
            },
            // Template for when no results were found
            desktop_no_results: () => {
                return `
                <li class="search-result no-results">
                    <p>No results found</p>
                </li>`;
            }
        }
        $(() => this.dom_ready());
    }

    search_algolia(success, content) {
        let out = "";
        let results = [];

        for (let index = 0; index < content.hits.length; index++) {
            const hit = content.hits[index];
            const result_index = results.findIndex(function(item, index, array) {
                return item.hasOwnProperty(hit.title);
            })

            if (result_index === -1) {
                let result = {}
                result[hit.title] = {}
                result[hit.title][hit.language] = hit
                results.push(result)
            } else {
                results[result_index][hit.title][hit.language] = hit
            }            
        }

        for (let i = 0; i < results.length; i++) {
            const result = results[i];
            const r = results[i][Object.keys(result)[0]];

            for (let j = 0; j < Object.keys(r).length; j++) {
                const item = r[Object.keys(r)[j]];
                console.log(item);

                const snippet = item._snippetResult.content.value.substring(0, 30);
                const permalink = item.permalink && item.permalink.startsWith('/') ? item.permalink : `/${item.permalink}`

                out += rdb_search.templates.desktop_result(
                    item.title,
                    snippet,
                    item.language,
                    permalink
                );   
            }
        }

        // No search results? Show a message in the search results
        if (results.length === 0) {
            out = rdb_search.templates.desktop_no_results();
        }

        rdb_search.$results.html(out);
    }

    dom_ready() {
        this.$results = $('.search-results'); 
        /* ---
           Desktop search behavior
           --- */
        $('.search input').keyup((event) => {
            const query = $(event.target).val();
            // No query, so hide the results
            if (!query) {
                this.$results.hide()
            }
            else if (query.length > 2) {
                // Timer to track when the user last typed in the search box
                clearTimeout(this.typing_timer);
                this.typing_timer = setTimeout(() => {
                    this.index.search(query, this.search_algolia, { attributesToSnippet: 'content:30'})
                }, this.typing_interval);
                // Show the results
                this.$results.show();
            }
        });

        /* Search results close button
           -> when clicked, hide the results and clear the search query */
        $('.close-results').click((event) => {
            event.preventDefault();
            this.$results.hide();
            $('.search input').val('');
        });

        /* ---
           Mobile docs navigation - left side
           ---- */
        // Open the left-side menu
        $('.docs-menu-trigger').click((event) => {
            event.preventDefault()
            $('body').toggleClass('pml-open');
            $('.doc-mobile-nav').height($(window).height());
        });

        // Extend the width of the menu to 100%
        $('.mobile-search input').focusin(() => $('body').addClass('pml-open-wide'));

        $('.mobile-search input').keyup((event) => {
            // When the user deletes the full string, hide the panel
            if (!$(this).val() && event.keycode === 8) {
                $('.search-results').hide(); // TODO - which results box does this close?
                $('.mobile-doc-links').show();
            }
            // User typing, show results panel and hide nav links
            else {
                $('.search-results').show(); // TODO - which results box does this show?
                $('.mobile-doc-links').hide();
                $('.clear-search').show();
            }
        });

        $('.clear-search').click((event) => {
            event.preventDefault();
            // Close btn input, clear text and restore nav links
            $('body').removeClass('pml-open-wide');
            $('.mobile-search input').val('');
            $('.search-results').hide(); // TODO - which results box does this close?
            $('.mobile-doc-links').show();
            $(this).hide();
        });

        // -> TODO deprecated, review  when new search is in
        /*
        $('.mobile-search input').keyup(function(event) {
            if((!$(this).val()) && (event.keyCode == 8)) {
                // When the user deletes the full string from the input
                $('.search-results').hide();
                $('.mobile-doc-links').show();
            }
            else {
                // User typing, show results panel and hide nav links
                $('.search-results').show();
                $('.mobile-doc-links').hide();
                $('.clear-search').show();
            }
        });
        $('.clear-search').click(function(event) {
            event.preventDefault();
            // Close btn input, clear text and restore nav links
            $('body').removeClass('pml-open-wide');
            $('.mobile-search input').val('');
            $('.search-results').hide();
            $('.mobile-doc-links').show();
            $(this).hide();
        });
        */
        
        // Desktop search
        // TODO deprecated, review when new search is in
        /*
        // Desktop search behaviors
        $('.search input').keyup(function(event) {
            if((!$(this).val()) && (event.keyCode == 8)) {
                $('.documentation-content .search-results').hide();
            }
            else {
                $('.documentation-content .search-results').show();
            }
        });
        // Search results close btn
        $('.close-results').click(function(event) {
            event.preventDefault();
            $('.documentation-content .search-results').hide();
            $('.search input').val('');
        });
        */
    }
}

const rdb_search = new RDBSearch();
