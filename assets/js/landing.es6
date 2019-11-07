---
---

'use strict';
jQuery.prototype[Symbol.iterator] = Array.prototype.values;

// Data for the realtime query animations
const names = ["natalie", "brandon", "marshall", "tomas", "grant", "joe", "alex",
    "yoshiko", "david", "pierre", "devon", "skyla", "ashley", "oren", "leon",
    "trevor", "jessica", "emil", "trevor", "neal", "lindsey", "arthur",
    "johnny", "zachary", "levi", "ryan", "jonathon", "eileen", "cindy",
    "kylee", "connor", "michele", "joseph", "mike", "slava", "daphne",
    "anthony", "juliana", "ben", "ken", "zoe", "eva", "samantha", "matt",
    "christina", "etienne", "watts", "daniel", "marc", "jeroen", "karl",
    "annie", "tim", "josh", "gabor"];
let score_cap = 30;

$(() => {
    const example = new RealtimeExample();
    example.draw_ui_graph();

    // Realtime query animations
    for (let n of Array(3).fill()) { example.add_message(); }
    setInterval(() => {
        example.add_message()
    }, 3000);

    // Switching between examples & use cases
    $('.examples nav a').on('click', (event) => {
        event.preventDefault();
        
        // Add active border styling to the link and remove previous active states
        $(event.target).siblings().removeClass('active');
        $(event.target).addClass('active');
        const $tab_index = $(event.target).index();

        // Remove the current active example
        $('.examples .example, .example h3, .example p, .example img').removeClass('active');
        // Show the correct example using the index
        $('.examples .example').eq($tab_index).addClass('active');

        // Target active (visible) elements
        const $img_el = $('.example.active').children();
        const $txt_el = $('.example.active .example-text').children();

        // Wait before animating in the content
        setTimeout(() => {
            $('.example.active').children().addClass('active');
            $('.example.active .example-text').children().addClass('active');
        }, 100);
    });
});

class RealtimeExample {
    // Realtime leaderboard of top scores
    update_leaderboard(msg) {
        const max_scores = 5;

        // Create a new score, add it to the leaderboard, and reorder the scores
        const $new_score = $(`<li class='collapsed' data-score='${msg['score']}' data-name='${msg['name']}' />`).html(`${msg['name']}: ${msg['score']} points`);
        const $leaderboard = $('.realtime-queries .leaderboard');

        const delayed_expand = (_s) => {
            setTimeout(() => { $(_s).removeClass('collapsed')}, 100);
        };

        // If the leaderboard is empty, add the score as the first entry
        if( $leaderboard.is(':empty')) {
            $leaderboard.append($new_score);
            delayed_expand($new_score);
        }
        else {
            // Go through each score on the leaderboard to figure out where the new score fits
            $.each($leaderboard.children(), (i, _s) => {
                // Score and name of the current list item
                const  curr = {
                    score: parseInt($(_s).data('score')),
                    name: $(_s).data('name')
                };

                /* If the new score is higher than the current score (or if the name
                   comes before it alphabetically), time to add it to the list */
                if ((msg.score > curr.score) || (msg.score == curr.score && msg.name < curr.name)) {
                    $(_s).before($new_score);
                    delayed_expand($new_score);
                    return false;
                }

                // If the leaderboard has room (but it's the lowest score), add it to the end
                const num_scores = $leaderboard.children().length;
                if ((num_scores < max_scores) && (i+1 == num_scores)) {
                    $(_s).after($new_score);
                    delayed_expand($new_score);
                    return false;
                }
            });
        }

        // Trim the list if it's too long
        $.each($leaderboard.children().slice(max_scores), (_score) => $(_score).remove());
    }

    // Realtime messages stream of player scores
    add_message() {
        const max_messages = 20;
        
        // Create a new message
        const msg = {
            name: names[Math.floor(Math.random() * names.length)],
            score: Math.floor(Math.random() * score_cap)
        };
        const $msg = $(`<li class='collapsed'>{'player':&nbsp;'${msg.name}',&#8203;&nbsp;'score':&nbsp;${msg.score}}</li>`);

        // Prepend it to the message list, and slide the messages down
        const $messages = $('.realtime-queries .messages');
        $messages.prepend($msg);
        setTimeout(() => { $msg.removeClass('collapsed')}, 100);

        // Trim the list if it's too long
        $.each($messages.children().slice(max_messages), (_msg) => $(_msg).remove());

        // Update the leaderboard with the new score
        this.update_leaderboard(msg);

        // Bump up the score cap
        score_cap = score_cap + 1
    }

    // Draw a moving line graph using D3
    draw_ui_graph() {
        // Moving line graph on the landing page
        const graph = d3.select('.ui-graph').append('svg:svg').attr('width', '100%').attr('height', '100%');
        
        // Generate a set of random values for the read and write graph -- we'll rotate through these for the line graphs
        const data = {
            reads: Array(80).fill().map((i) => Math.floor(Math.random() * 4 + 42)),
            writes: Array(80).fill().map((i) => Math.floor(Math.random() * 20 + 15))
        };

        const update_freq = 1250;

        const width = 400;
        const height = 100;

        const x = d3.scale.linear().domain([0,48]).range([-5, width]);
        const y = d3.scale.linear().domain([50,0]).range([0, height]);

        const line = d3.svg.line()
            .x((d,i) => x(i))
            .y((d) => y(d))
            .interpolate('linear');

        for (let graph_type of ['reads', 'writes']) {
            graph.selectAll(`path.${graph_type}`)
                .data([data[graph_type]])
                .enter()
                    .append('svg:path')
                    .attr('class', graph_type)
                    .attr('d', line);
        }

        let redraw = () => {
            for (let graph_type of ['reads', 'writes']) {
                graph.selectAll(`path.${graph_type}`)
                    .data([data[graph_type]])
                    .attr('transform', `translate(${x(1)})`)
                    .attr('d', line)
                    .interrupt()
                    .transition()
                    .ease('linear')
                    .duration(update_freq)
                    .attr('transform', `translate(${x(0)})`);
            }
        };

        setInterval(() => {
            // Rotate the data for each graph -- pop the first element, push it to the end
            for (let arr of [data['reads'], data['writes']]) {
                arr.push(arr.shift());
            }
            redraw();
        }, update_freq);
    }
}

        
