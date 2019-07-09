---
---

'use strict';

class RDBSearch {
    constructor() {
        // Algolia connection details
        this.client = new AlgoliaSearch('KCOV7EA2RN', 'd3fe58627b3cdf453a83f59e502ae80b');
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
               - url (required): the permalink / URL of the result */
            desktop_result: (title, snippet, url) => {
                return `
                    <a href="${url}">
                        <li class="search-result" data-url="${url}">
                            <p><strong>${title}</strong> <span class="snippet">${snippet}</span></p>
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
        if (success) {
            let out = "";
            const tmpl = this.templates.desktop_result;

            // Organize results by title (we want one result across languages)
        }

        const results_index = {};
        let results = [];
        for (hit in content.hits) {
            // Have we already added at least one article with this title to the results?
            let r = results_index.find(hit.title);
            if (r === undefined) {
                // Add it to the index of results, since it's the first of its kind
                const r = results.length;
                results_index[hit.title] = r;
                results.push({});
            }

            // Group the hit properly by language (will be null if it's not specified)
            results[r][hit.language] = hit;
        }
        console.log(results);

        // Use the search result template to build the list of results
        for (result in results) {
            /* Pick one of the returned results for the template (it doesn't
               matter which one, because we're going to render all the languages
               as a compound result) */
            const first = result[Object.keys(result)[0]];
            const snippet = first._snippetResult.content.value;
            out += tmpl(first.title, snippet, first.permalink);
        }

        // No search results? Show a message in the search results
        if (results.length===0) {
            out = rdb_search.templates.desktop_no_results();
        }

        this.$results.html(out);
    }

    dom_ready() {
        this.$results = $('.search-results'); 
        /* ---
           Desktop search behavior
           --- */
        $('.search input').keyup((event) => {
            const query = $(this).val();
            // No query, so hide the results
            if (!query) {
                this.$results.hide()
            }
            else if (query.length > 0) {
                // Timer to track when the user last typed in the search box
                clearTimeout(this.typing_timer);
                this.typing_timer = setTimeout(() => {
                    console.log('Querying Algolia: '+query);
                    this.index.search(query, this.search_algolia, { attributesToSnippet: 'content:20'})
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
