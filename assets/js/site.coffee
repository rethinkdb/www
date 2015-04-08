---
---

$ ->
    # Global mobile menu: right side
    #   -> open / close the right-side menu
    $('.menu-trigger a').click (event) ->
        event.preventDefault()
        $('body').toggleClass 'pmr-open'

    # Blog right panel should be set to a fixed position on scroll
    $_sidebar = $('.blog-sidebar ul')
    if $_sidebar.length
        blog_sidebar_sticky = new Waypoint.Sticky
            element: $('.blog-sidebar ul')

    # Docs navigation: collapse / expand sections
    $('.docs-nav h1, .mobile-doc-links h1').click (event) ->
        $(this).toggleClass('expand').next('ul').slideToggle('fast')

    # Landing page: videos
    #   -> show a video modal on click
    $('.video p').click (event) ->
        event.preventDefault()
        $modal = $(this).next('.video-modal')

        # Buid the iframe for the YouTube embed
        yt = $modal.data('youtube-id')                                     # Get the YouTube id
        attrs = "width='560' height='315' frameborder='0' allowfullscreen" # iframe attributes
        opts = "rel=0&autoplay=1&autohide=1"                               # YouTube options
        src = "src='//www.youtube.com/embed/#{yt}?#{opts}'"                # Video to show
        iframe = "<iframe #{attrs} #{src}></iframe>"

        # Add the iframe to the modal
        $('.iframe-container', $modal).html(iframe)

        # Fade in the modal
        $modal.fadeIn('fast')
    #   -> hide the video modal
    dismiss_video = ->
        $modal = $('.video-modal:visible')
        $modal.fadeOut 'fast', ->
            # Once the modal has faded out, reset the content once again
            $('.iframe-container').empty()
    
    # Two ways to dismiss videos: clicking outside the video or pressing ESC
    $('.video-modal').on 'click', (event) ->
        event.preventDefault()
        dismiss_video()
    $(document).keyup (event) ->
        if (event.keyCode == 27)
            dismiss_video()


    
