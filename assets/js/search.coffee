---
---
window.rdb_search =
    # Algolia connection details
    client: new AlgoliaSearch('KCOV7EA2RN', 'd3fe58627b3cdf453a83f59e502ae80b'),
    index: undefined,
    # Timer to track when the user last typed in the search box
    typing_timer: undefined,
    # Length of time in ms to wait before fetching results
    typing_interval: 25,
    # Templates for search results
    templates:
        # data is an object that should have the following properties:
        #   - title (required): the title of the result
        #   - snippet (required): the snippet in the result that matched
        #   - url (required): the permalink / URL of the result
        #   - langs (optional)
        desktop_result: (title, snippet, url, langs) ->
            found_lang = false
            #if langs?
            #    if lang['pyth

            """
                <li class="search-result">
                    <h2>#{title}</h2>
                    <p>#{snippet}</p>
                    <p><a href="#{url}">Go to command &rarr;</a></p>
                </li>
            """

# Set up the Algolia search index
rdb_search.index = rdb_search.client.initIndex 'docs'


search_algolia = (success, content) ->
    if success
        out = ""
        tmpl = rdb_search.templates.desktop_result

        # Organize results by title (we want one result across languages)
        results_index = {}
        results = []
        for hit in content.hits
            # Have we already added at least one article with this title to the results?
            if hit.title of results_index
                r = results_index[hit.title]
            else
                # Add it to the index of results, since it's the first of its kind
                r = results.length
                results_index[hit.title] = r
                results.push({})

            # Group the hit properly by language (will be null if it's not specified)
            results[r][hit.language] = hit

        console.log results

        # Use the search result template to build the list of results
        for result in results
            first = Object.keys(result)[0]
            snippet = first._snippetResult.content.value
            out += tmpl(first.title, snippet, first.permalink)

        $('.search-results ul').html(out)

$ ->
    $('.doc_navigation h1, .mobile-doc-links h1').click (event) ->
        $(this).toggleClass('expand').next('ul').slideToggle()

    # ---
    # Desktop search behavior
    # ---
    $('.search input').keyup (event) ->
        query = $(this).val()
        console.log query
        if (not query and event.keycode is 8)
            $('.docs .search-results').hide()
        else if query.length > 0
            # Timer to track when the user last typed in the search box
            clearTimeout(rdb_search.typing_timer)
            rdb_search.typing_timer = setTimeout ->
                rdb_search.index.search(query, search_algolia, { attributesToSnippet: 'content:20'})
            , rdb_search.typing_interval
            # Show the results
            $('.docs .search-results').show()

    # Search results close btn
    $('.close-results').click (event) ->
        event.preventDefault()
        $('.docs-content .search-results').hide()
        $('.search input').val('')

    # ---
    # Mobile docs navigation - left side
    # ----
    # Open the left-side menu
    $('.docs-menu-trigger').click (event) ->
        event.preventDefault()
        $('body').toggleClass 'pml-open'
        $('.doc-mobile-nav').height $(window).height()

    # Extend the width of the menu to 100%
    $('.mobile-search input').focusin ->
        $('body').addClass 'pml-open-wide'

    $('.mobile-search input').keyup (event) ->
        # When the user deletes the full string, hide the panel
        if (not $(this).val() and event.keycode is 8)
            $('.search-results').hide()
            $('.mobile-doc-links').show()
        # User typing, show results panel and hide nav links
        else
            $('.search-results').show()
            $('.mobile-doc-links').hide()
            $('.clear-search').show()

    $('.clear-search').click (event) ->
        event.preventDefault()
        #  Close btn input, clear text and restore nav links
        $('body').removeClass 'pml-open-wide'
        $('.mobile-search input').val('')
        $('.search-results').hide()
        $('.mobile-doc-links').show()
        $(this).hide()

