---
---

$ ->
    # Blog right panel should be set to a fixed position on scroll
    $('.social-integration').waypoint (direction) ->
        $(this).toggleClass 'sticky'

    # Global mobile navigation - right side
    $('.menu-trigger a').click (event) ->
        event.preventDefault()
        $('body').toggleClass 'pmr-open'
