---
---
# Data for the realtime query animations
names = ["natalie", "brandon", "marshall", "tomas", "grant", "joe", "alex",
    "yoshiko", "david", "pierre", "devon", "skyla", "ashley", "oren", "leon",
    "trevor", "jessica", "emil", "trevor", "neal", "lindsey", "arthur",
    "johnny", "zachary", "levi", "ryan", "jonathon", "eileen", "cindy",
    "kylee", "connor", "michele", "joseph", "mike", "Slarva", "daphne",
    "anthony", "juliana", "ben", "ken", "zoe", "eva", "samantha", "matt",
    "christina", "etienne", "watts", "daniel", "marc", "jeroen", "karl",
    "annie", "tim", "josh"]
score_cap = 30

$ ->
    draw_ui_graph()

    # Realtime query animations
    for n in [0..3]
        add_realtime_message()
    setInterval(add_realtime_message, 3000)

    # Switching between examples & use cases
    $('.examples nav a').on 'click', (event) ->
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
    max_messages = 20
    msg_height = 22 # height of each message in pixels
    
    # Create a new message
    msg =
        name: names[Math.floor(Math.random() * names.length)]
        score: Math.floor(Math.random() * score_cap)
    $msg = $("<li class='collapsed'>{'player':&nbsp;'#{msg.name}',&#8203;&nbsp;'score':&nbsp;#{msg.score}}</li>")

    # Prepend it to the message list, and slide the messages down
    $messages = $('.realtime-queries .messages')
    $messages.prepend($msg)
    setTimeout (-> $msg.removeClass('collapsed')), 100

    # Trim the list if it's too long
    for _msg in $messages.children().slice(max_messages)
        $(_msg).remove()

    # Update the leaderboard with the new score
    update_leaderboard(msg)

    # Bump up the score cap
    score_cap = score_cap + 1
        
# Realtime leaderboard of top scores
update_leaderboard = (msg) ->
    max_scores = 5
    score_height = 24 # height of each score in pixels

    # Create a new score, add it to the leaderboard, and reorder the scores
    $new_score = $("<li class='collapsed' data-score='#{msg['score']}' data-name='#{msg['name']}' />").html("#{msg['name']}: #{msg['score']} points")
    $leaderboard = $('.realtime-queries .leaderboard')

    delayed_expand = (_s) ->
        setTimeout (-> $(_s).removeClass('collapsed')), 100

    # If the leaderboard is empty, add the score as the first entry
    if $leaderboard.is(':empty')
        $leaderboard.append($new_score)
        delayed_expand($new_score)
    else
        # Go through each score on the leaderboard to figure out where the new score fits
        $.each $leaderboard.children(), (i, _s) =>
            # Score and name of the current list item
            curr =
                score: parseInt($(_s).data('score'))
                name: $(_s).data('name')

            # If the new score is higher than the current score (or if the name
            # comes before it alphabetically), time to add it to the list
            if (msg.score > curr.score) or (msg.score == curr.score and msg.name < curr.name)
                $(_s).before($new_score)
                delayed_expand($new_score)
                return false

            # If the leaderboard has room (but it's the lowest score), add it to the end
            num_scores = $leaderboard.children().length
            if (num_scores < max_scores) and (i+1 == num_scores)
                $(_s).after($new_score)
                delayed_expand($new_score)
                return false

    # Trim the list if it's too long
    for score in $leaderboard.children().slice(max_scores)
        $(score).remove()

# Draw a moving line graph using D3
draw_ui_graph = ->
    # Moving line graph on the landing page
    graph = d3.select('.ui-graph').append('svg:svg').attr('width', '100%').attr('height', '100%')
    # Generate a set of random values for the read and write graph -- we'll rotate through these for the line graphs
    data =
        reads: [0..80].map((i) -> Math.floor(Math.random() * 4 + 42))
        writes: [0..80].map((i) -> Math.floor(Math.random() * 20 + 15))

    update_freq = 1250
    width = 400
    height = 100

    x = d3.scale.linear().domain([0,48]).range([-5, width])
    y = d3.scale.linear().domain([50,0]).range([0, height])

    line = d3.svg.line()
        .x (d,i) -> x(i)
        .y (d) -> y(d)
        .interpolate('linear')

    for graph_type in ['reads', 'writes']
        graph.selectAll("path.#{graph_type}")
            .data([data[graph_type]])
            .enter()
                .append('svg:path')
                .attr('class', graph_type)
                .attr('d', line)

    redraw = ->
        for graph_type in ['reads', 'writes']
            graph.selectAll("path.#{graph_type}")
                .data([data[graph_type]])
                .attr('transform', "translate(#{x(1)})")
                .attr('d', line)
                .interrupt()
                .transition()
                .ease('linear')
                .duration(update_freq)
                .attr('transform', "translate(#{x(0)})")

    setInterval () ->
        # Rotate the data for each graph -- pop the first element, push it to the end
        for arr in [data['reads'], data['writes']]
            arr.push(arr.shift())
        redraw()
    , update_freq
