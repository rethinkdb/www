---
---

machinize_text = (text) ->
    text.toLowerCase().replace(/[ ]/g, '-').replace(/\?/g, '').replace(/,/g, '').replace(/'/g, '').slice(0, 45).replace(/-$/, '')

init_api_page = ->
    position_hash = window.location.hash.slice(1)

    # Remove main sticky header
    $('.sticky-wrapper:has(.navbar)').waypoint 'destroy'
    $('.navbar').removeClass 'stuck'

    # Stick API header
    $('#api-header .sticky-wrapper').height($('#api-command-bar').outerHeight())


    is_scrolling = false # Are we scrolling the page?
    timeout_scrolling = null
    past_header = false # Is the header stuck?
    header_padding = 10
    api_width = $('#api-app').width()
    $api_nav = $('#api-nav')
    $api_sections = $('#api-sections')
    $bar = $('#api-command-bar')

    # nav_margin_left is the absolute margin left of $api_nav when we are not past the header
    # nav_margin_left = $('#content .container .section').css('padding-left')
    #                 + $('#content .container').css('margin-left')
    #                 + 1 # (for the border)
    nav_margin_left = 42
    min_width_page = 961 # Min with set on sticky-wrapper

    $('#api-header').waypoint
        offset: header_padding
        handler: ->
            past_header = not past_header
            if past_header
                # Make the header stick
                $bar.addClass 'stuck'
                $bar.css
                    'width': api_width
                    'padding-top': header_padding

                # Add a margin to the nav and sections
                $api_nav.css('top', $bar.outerHeight() - 5) # Painfully unexplainable margin
                $api_nav.css('top', $bar.outerHeight() - 5) # Painfully unexplainable margin
                extra_margin = Math.max(($(window).width()-min_width_page)/2, 0) # extra_margin is the margin on the left of the whole page
                $api_nav.css('left', extra_margin+nav_margin_left-$(window).scrollLeft()) # Painfully unexplainable margin
                $bar.css('left', extra_margin+nav_margin_left-$(window).scrollLeft())

                $api_nav.addClass 'scrolling'

                # Scroll the nav to the top in case we flipped across the waypoint while in the middle of the nav
                $api_nav.scrollTop(0)
            else
                # Let the header go free again
                $bar.removeClass 'stuck'
                $bar.css
                    'width': 'auto'
                    'padding-top': 0

                # Remove a margin to the nav and sections
                $api_nav.css('top','auto')
                $api_nav.removeClass 'scrolling'

    $(window).on 'scroll', ->
        if past_header
            if $(document).width() > $(window).width()
                extra_margin = Math.max(($(window).width()-min_width_page)/2, 0)
                $api_nav.css('left', extra_margin+nav_margin_left-$(window).scrollLeft()) # Painfully unexplainable margin
                $bar.css('left', extra_margin+nav_margin_left-$(window).scrollLeft())

    $(window).resize ->
        if past_header
            extra_margin = Math.max(($(window).width()-min_width_page)/2, 0)
            $api_nav.css('left', extra_margin+nav_margin_left-$(window).scrollLeft()) # Painfully unexplainable margin
            $bar.css('left', extra_margin+nav_margin_left-$(window).scrollLeft())


    all_links = $('.nav-list a')
    # Add waypoint on each command
    $.each $('.api-anchor'), (index, value) ->
        $(value).waypoint
            offset: 0
            handler: ->
                # We don't want to update the left navigation if the user clicked on a link and we are programatically scrolling
                if not is_scrolling
                    # Set the new active link
                    all_links.removeClass 'active'
                    new_active = $("a[href='##{$(value).attr('name')}']")
                    new_active.addClass 'active'
                    position_hash = $(value).attr('name')

                    # Check if we need to scroll the left navigation
                    viewport_height = $.waypoints('viewportHeight')

                    if new_active[0]?
                        pixel_offset_from_top = new_active[0].offsetTop - $api_nav.scrollTop()
                        pixels_from_top_of_window = new_active[0].offsetTop + new_active.height() - $api_nav.scrollTop() + $api_nav[0].offsetTop

                        if (pixel_offset_from_top < 0 or pixels_from_top_of_window > viewport_height) and $('#api-sections').is(':hover')
                            nav_height = $.waypoints('viewportHeight') - $api_nav[0].offsetTop
                            scrolltop_offset = new_active[0].offsetTop - Math.floor(nav_height  / 2)

                            $api_nav.stop().animate
                                scrollTop: scrolltop_offset
                            , 250

    $('#api-nav').on 'scroll', ->
        is_scrolling = true
        if timeout_scrolling?
            clearTimeout timeout_scrolling
        timeout_scrolling = setTimeout ->
            is_scrolling = false
            timeout_scrolling = null
        , 1000

    # Listen to click on links in the left panel
    $('.command a').click (event) ->
        event.preventDefault()
        $('.nav-list a').removeClass 'active'
        $(event.currentTarget).addClass 'active'

        # Find the element we're supposed to scroll to and start scrolling
        hash = $(event.currentTarget).attr('href').slice(1)
        section = $(event.currentTarget).parent().parent().prev().html()

        scrolltop_offset = $("h1[data-alt='#{section}']").parent().find(".api-anchor[name='#{hash}']").offset().top

        is_scrolling = true
        $('html, body').animate
            scrollTop: scrolltop_offset
        , 250, 'swing', ->
            window.location.hash = hash
            is_scrolling = false

    $('.lang-link').mousedown (event) ->
        if position_hash? and position_hash isnt ''
            event.preventDefault()
            event.stopPropagation()


            window.location = $(event.currentTarget).attr('href')+'#'+position_hash



# We have two versions of count. In case the h2 tag has a property name, we use it as an anchor
get_anchor = (question) ->
    anchor = $(question).attr('href').slice(0, -1)

$ ->
    # First, create the table of contents
    section_list = $("<ul class='nav nav-list'></ul>")

    $('#api-nav').append(section_list)

    # Go through each section to add it to the table of contents
    $('.apisection').each (idx, section) ->
        # Add the section header to table of contents
        section_header = $('h1', section).data('alt')
        section_item = $("<li class='nav'></li>")
        section_item.append($("<li class='nav-header'>" + section_header + "</li>"))

        # Add the list of groups
        question_list = $("<ul class='nav nav-list'></ul>")
        $('h2 a', section).each (idx, question) ->
            question_item = $("<li class='command'></li>")

            anchor = get_anchor question

            question_item.append($("<a href='#" + machinize_text(anchor) + "'>" + $(question).text() + "</a>"))
            question_list.append(question_item)

        section_item.append(question_list)

        # Add the section to table of contents
        section_list.append(section_item)

    # Wrap each question in a div (for styling)
    $('h2').each (idx, question_header) ->
        wrapper = $("<div class='api-command'></div>")
        $(question_header).nextUntil("h2").each (idx, question_paragraph) ->
            $(question_paragraph).appendTo(wrapper)

        question_header = $(question_header).replaceWith(wrapper)
        question_header.prependTo(wrapper)

    # Finally, inject anchors into groups
    $('h2 a').each (idx, question) ->
        $(question).addClass('slim')
        anchor = get_anchor question
        $("<a class='api-anchor' name='" + machinize_text(anchor) + "'></a>").insertBefore(question)

    # Handle click on links + scrolling
    init_api_page()
