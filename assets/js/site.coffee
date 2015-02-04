---
---

$ ->
    # Blog right panel should be set to a fixed position on scroll
    $('.blog .blog-sidebar-wrapper').waypoint (direction) ->
        $(this).toggleClass 'sticky'

    # Global mobile menu: right side
    #   -> open / close the right-side menu
    $('.menu-trigger a').click (event) ->
        event.preventDefault()
        $('body').toggleClass 'pmr-open'
        $('.doc-mobile-nav').height($(window).height())

    # Docs navigation: collapse / expand sections
    $('.doc_navigation h1, .mobile-doc-links h1').click (event) ->
        $(this).toggleClass('expand').next('ul').slideToggle()

    # Docs mobile menu: left side
    #    -> open / close the left-side menu
    $('.docs-menu-trigger').click (event) ->
        event.preventDefault()
        $('body').toggleClass 'pml-open'
    #   -> when searching, expand the width of the menu to 100%
    $('.mobile-search input').focusin ->
        $('body').addClass 'pml-open-wide'
    # -> TODO deprecated, review  when new search is in
    ###
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
    ###
    
    # Desktop search
    # TODO deprecated, review when new search is in
    ###
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
    ###
    
    # Landing page: videos
    #   -> show a video modal on click
    $('.video p').click (event) ->
        event.preventDefault()
        $(this).next('.video-modal').fadeIn()
    #   -> hide the video modal
    $('.video-modal').on('click', dismiss_video)
    dismiss_video = -> $('.video-modal').fadeOut()
    $(document).keyup (event) ->
        if (event.keyCode == 27)
            dismiss_video()
