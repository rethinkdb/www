---
---
# Data for the realtime query animations
names = ["natalie", "brandon", "marshall", "tomas", "grant", "joe", "alex",
    "yoshiko", "andres", "pierre", "devon", "skyla", "ashley", "oren", "leon",
    "trevor", "jessica", "emil", "trevor", "neal", "lindsey", "arthur",
    "johnny", "zachary", "levi", "ryan", "jonathon", "eileen", "cindy",
    "kylee", "connor", "michele", "joseph", "mike", "slava", "daphne",
    "anthony", "juliana", "andre", "ken", "zoe", "eva", "samantha", "matt",
    "christina", "etienne", "watts", "daniel", "marc", "jeroen", "graham",
    "karl", "andrea", "tim", "josh", "jessie"]

$ ->
    draw_ui_graph()

    # Realtime query animations
    setInterval(add_realtime_message, 2000)

    # Switching between examples & use cases
    $('.examples nav a').on 'click', (event) =>
        event.preventDefault()
        
        # Add active border styling to the link and remove previous active states
        $(this).siblings().removeClass('active')
        $(this).addClass('active')
        $tab_index = $(this).index()

        # Remove the current active example
        $('.examples .example, .example h3, .example p, .example img').removeClass('active')
        # Show the correct example using the index
        $('.examples .example').eq($tab_index).addClass('active')

        # Target active (visible) elements
        $img_el = $('.example.active').children()
        $txt_el = $('.example.active .example-text').children()

        # Wait before animating in the content
        setTimeout ->
            $('.example.active').children().addClass('active')
            $('.example.active .example-text').children().addClass('active')
        , 100

# Realtime messages stream of player scores
add_realtime_message = ->
    score_cap = 120
    max_messages = 20
    msg_height = 24 # height of each message in pixels

    msg =
        player: names[Math.floor(Math.random() * names.length)]
        score: Math.floor(Math.random() * score_cap)

    # Create a new message, prepend it to the message list, and slide the messages down
    $msg = $("<li>#{JSON.stringify(msg)}</li>")
    $realtime = $('.realtime-queries')
    $('.query-results .messages', $realtime).prepend($msg)
    $messages = $('.query-results .messages li', $realtime)
    # Delay so the CSS animations can take effect
    setTimeout ->
        # If there are more than N messages, drop the last ones
        for _msg in $messages.toArray().slice(max_messages)
            $(_msg).remove()
        # Visually slide messages down (delay so animations take effect)
        $.each($messages, (i, _msg) ->
            $(_msg).css('top', "#{i*msg_height}px")
        )
    , 100

    update_leaderboard(msg)
        
# Realtime leaderboard of top scores
update_leaderboard = (msg) ->
    max_scores = 12
    score_height = 24 # height of each score in pixels

    # Create a new score, add it to the leaderboard, and reorder the scores
    $score = $("<li data-score='#{msg['score']}' data-name='#{msg['player']}' />").html("#{msg['player']}: #{msg['score']} points")
    $realtime = $('.realtime-queries')
    $('.query-results .leaderboard', $realtime).append($score)
    $scores = $('.query-results .leaderboard li', $realtime)

    # Sort the scores in descending order
    leaderboard = $scores.map ->
        el: this
        score: $(this).data('score')
        name: $(this).data('name')
    leaderboard = leaderboard.toArray()
    leaderboard.sort (a,b) ->
        score_delta = b.score - a.score
        # If the scores are the same, sort by name, alphabetically
        if score_delta is 0
            return -1 if a.name < b.name
            return 1 if a.name > b.name
            return 0
        return score_delta

    # Delay so the CSS animations can take effect
    setTimeout ->
        # If there are more than N top scores, drop the lowest ones
        for score in leaderboard.slice(max_scores)
            $(score['el']).css('height', 0)
            setTimeout -> { $(score['el']).remove() }, 300
        # Visually sort by score
        for score, i in leaderboard
            $(score['el']).css('top', "#{i*score_height}px")
        # Delay removing elements until the CSS animation has completed
        setTimeout ->
        , 300
    , 100


# Draw a moving line graph using D3
draw_ui_graph = ->
    # Moving line graph on the landing page
    graph = d3.select('.ui-graph').append('svg:svg').attr('width', '100%').attr('height', '100%')
    data = [0..50].map((i) -> Math.floor(Math.random() * 5 + 3))
    update_freq = 1250
    width = 350
    height = 100

    x = d3.scale.linear().domain([0,48]).range([-5, width])
    y = d3.scale.linear().domain([0,10]).range([0, height])

    line = d3.svg.line()
        .x (d,i) -> x(i)
        .y (d) -> y(d)
        .interpolate('linear')

    graph.selectAll('path')
        .data([data])
        .enter()
        .append('svg:path')
        .attr('d', line)

    redraw = ->
        graph.selectAll('path')
            .data([data])
            .attr('transform', "translate(#{x(1)})")
            .attr('d', line)
            .interrupt()
            .transition()
            .ease('linear')
            .duration(update_freq)
            .attr('transform', "translate(#{x(0)})")

    setInterval () ->
        data.push(data.shift())
        redraw()
    , update_freq

