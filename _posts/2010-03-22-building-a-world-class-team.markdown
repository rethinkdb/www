---
layout: post
title: "Building a world-class team: six mistakes I made early in my career"
author: Slarvae Akhmechet
author_github: coffeemug
--- 

For the past few weeks my primary job at RethinkDB has been to hire world-
class software developers. Recruiting great people is a difficult
process with at least seven components: sourcing candidates, reviewing
resumes, doing technical phone screens, conducting technical interviews,
closing candidates, extending offers, and keeping candidates happy once
they've joined. Each component seems simple in principle, but is very subtle
in practice. A testament to this is that all software companies aspire to hire
only the best people, but in practice very few companies achieve this goal.
<!--more-->

I've performed many technical interviews before, but always as a small part of
a process designed by someone else. I was very excited to start recruiting for
RethinkDB because I could finally design the recruiting process from scratch,
and fix many of the issues that were previously outside of my control. There
are many amazing articles on how to recruit for software companies. Many of the
ideas I borrowed for our process come from the articles written by [Joel
Spolsky][1], [Steve Yegge][2], [Marc Andreessen][3], [Michael Lopp][4], and
[Paul English][5]. I won't attempt to restate all of their advice, which
largely became conventional wisdom anyway. Instead, I will focus on pointing
out the mistakes I've made early in my career, even after reading everything
there is to read about hiring. I hope this will add a little more clarity to
the subtleties of the process.

[1]: http://www.joelonsoftware.com/articles/GuerrillaInterviewing3.html
[2]: http://steve-yegge.blogspot.com/2008/03/get-that-job-at-google.html
[3]: http://pmarca-archive.posterous.com/how-to-hire-the-best-people-youve-ever-worked
[4]: http://www.randsinrepose.com/archives/2010/01/04/wanted.html
[5]: http://paulenglish.com/hiring.html

Over time, I hope to write about every component of the recruiting process, but
for now I will focus on my favorite part - doing technical interviews. In this
blog post I will cover what not to do. Later on I will write a follow up post
discussing exactly how we conduct technical interviews and what types of
questions we ask.

# Informal interviews

Almost every great article on interviewing I've ever read insists on one thing:
that you should establish a formal interview process and stick to it.  Despite
reading this over and over again, early in my career I did all of the technical
interviews informally. In almost every case I can think of, this turned out to
be a disaster.

For an inexperienced person, performing a formal interview is psychologically
difficult. Early on, I lacked the confidence to place smarter, older, or more
experienced people in front of a white board, and ask them tough technical
questions. Eventually I learned that it is much easier to do than it seems.
The best people not only welcome a challenge, they require it. All the great
people I know would never work for a company that doesn't perform a tough,
formal interview because they recognize the company will mostly end up with bad
employees. The first time I resolved to do a formal interview, I cautiously
asked a candidate who looked twice my age and had a stellar resume to code a
binary search. I was pleasantly surprised when he smiled and gladly walked up
to the whiteboard.

The only counterexample I've seen is Aaron Swartz's [article][6] on hiring. His
main argument is that he was never great at solving problems under the social
pressure of the interview, and wouldn't want to ask others to do it too. I
agree with Aaron - I am often unable to solve complex problems during the
interview because of the nervous pressure. But I don't want to hire people as
good as me, I want to hire people much better than me. It's a cliche, but
firing an employee is so difficult and expensive, that the last thing to be
concerned about is a false negative.

[6]: http://www.aaronsw.com/weblog/hiring

Occasionally, some candidates suggest an alternative to a formal process (such
as asking them to write a piece of code over a period of a few days, or hiring
them temporarily as contractors). This has never really worked for me.
Firstly, I can never feel confident enough in the candidate's abilities without
going through all the technical questions. Secondly, this ends up taking a
tremendous amount of time, and if the candidate doesn't work out (which will
happen most of the time), you've essentially wasted a ton of your time and
theirs.

If you decide to go down the path of informal interviews, I'd caution you to be
extremely careful. At the very least, make sure you do it because you honestly
think it's a better way to hire great people, and not because you feel insecure
about asking intimidating people tough questions. My opinion is that if you end
up hiring great people this way, it will probably be an accident.

# Making exceptions for technical friends or ex-coworkers

A special case of the above is hiring technical friends, family, or old
coworkers, without a formal interview. Unless you're absolutely certain, beyond
a shadow of a reasonable doubt, that they're one of the best developers in the
world, don't hire them without an interview. It might be awkward to ask a
friend or someone you've already worked with for two years to go through a
formal interview, but it will be much more awkward to ask them to leave when
they don't work out.

This is one of the reasons I prefer not to meet new candidates in an informal
setting before the first interview. It establishes a rapport of friendship, and
makes it that much harder to ask them to do a formal interview later. If you're
a beginner and lack the confidence to ask a friend to go through a formal
interview, try to meet new candidates in a formal setting to avoid having an
awkward conversation later. In retrospect, this seems somewhat obvious, but
I've seen too many smart people skip a formal interview process because they've
made friends with the candidate. I'd wager a guess that the overwhelming
majority of Silicon Valley startups founded by young, first-time entrepreneurs
make this mistake, and most of the time it has disastrous consequences.

# Avoiding candidates that seem intimidating

It's funny how many of the rookie mistakes stem from lack of confidence. Early
on, I avoided candidates that seemed intimidating either because of their
skills, age, or track record. In retrospect, this is the exact opposite of what
I should have been doing! Recently, someone who was a very successful manager
at Google gave me great advice - if someone does not intimidate you, don't hire
them. Period.

# Building an army of clones

Diversity is very much valued in the U.S. Every company aspires to have diverse
employees, but this is much easier said than done because true diversity is
completely unobvious. You can go out of your way to hire people of different
nationalities, skin colors, and cultural backgrounds, but if they're all
Java-only programmers, it won't do your company much good. We are naturally
inclined to sympathize with people that are similar to us, so the intellectual
honesty required not to mistake diversity for lack of intelligence is
staggering.

Sometimes it is immediately obvious that a company (or an industry sector) is
hiring clones of its current employees because its interview questions resemble
a secret handshake for a fraternity. When I was working on Wall Street,
everyone always asked what C++ keywords "explicit" and "mutable" do.  Every
Wall Street software veteran knew the answer, but I've never encountered a
single codebase there that made use of these keywords.

In many cases, the fact that a company hires only very specialized people is
hidden by an unconscious linguistic transformation. Many companies today
heavily focus on questions from the field of algorithms, but rename them to
"problem solving" questions. The field of algorithm design and analysis is an
essential pillar of Computer Science, but it is very important not to focus the
vast majority of the interview on algorithms alone. It is only one field of
many that need to be probed during an interview. Algorithms involve problem
solving, sure, but they also involve a tremendous amount of domain expertise in
algorithms. Not being able to solve complex and unobvious algorithmic problems
doesn't necessarily make one a poor problem solver - only a poor algorist.

One example of this is Microsoft - a company that at its heyday had plenty of
great coders, but very few people with a great sense of user interface design.
This likely happened because early Microsoft employees, all brilliant people,
mistook lack of algorithms experience coupled with a great sense of UI, for
lack of intelligence. In order to avoid this problem I always ask the candidate
to teach me about a field I know nothing about. Anything will do - jazz,
physics, color theory, nutrition, computer vision, _anything_ hard. If _all_
our interests intersect, I'm probably hiring a clone of myself. If this happens
too often, the interview process is likely [overfitting][], and needs to be
redesigned.

[overfitting]: http://en.wikipedia.org/wiki/Overfitting

# Ignoring everything but intelligence

I'm ashamed to admit that early in my career I was a pretty bad employee. My
skills and intelligence weren't an issue - I never encountered a problem at
work that I couldn't solve. But my attitude was. I'd spend days lingering, and
I often made my coworkers linger with me. I'd read technical articles all day
long, or complain about the poor quality of the code base or the inflexibility
of company policies, or talk for hours about how the whole thing would have
been much better if it were written in Lisp.

Well, it _was_ fun to read articles on my employer's dime, the code base
usually _was_ horrendous, the policies _were_ terrible, and the whole thing
_would_ have been much better were it written in Lisp. But none of that was
constructive, or useful, or helpful to my employer or me. In retrospect, I
can't believe how incompetent I was, despite my skills and (hopefully)
intelligence.

Intelligence means nothing without solid work ethic and a killer drive to
accomplish useful things. Many young, intelligent people feel a sense of
entitlement because the job market is heavily stacked in their favor. Smart
people _should_ feel entitled, but if this goes out of reasonable proportions,
it can be a very poisonous mindset to be in. This is very difficult to
recognize during the interview, so try to pay attention to little hints that
might indicate the candidate has raw intelligence that isn't backed by good old
professionalism. Steer clear of such candidates no matter how smart they are,
or you will have a much bigger problem on your hands later on.

# Letting the job market set the anchor

In his article [The Guerrilla Guide to Interviewing][7], Joel Spolsky says:

[7]: http://www.joelonsoftware.com/articles/GuerrillaInterviewing3.html

_At the end of the interview, you must be prepared to make a sharp decision
about the candidate. [...] Never say "Maybe, I can't tell." If you can't tell,
that means No Hire. It's really easier than you'd think. Can't tell? Just say
no! If you are on the fence, that means No Hire. Never say, "Well, Hire, I
guess, but I'm a little bit concerned about…" That's a No Hire as well.
Mechanically translate all the waffling to "no" and you'll be all right._

In my experience, this is much harder to do than Joel might lead you to
believe, because of a psychological effect sales people refer to as
"anchoring". In sales, naming a price first is called setting the anchor,
because this number will affect the psychology of the counterparty for the rest
of the negotiations process. If you offer a software license for $50,000 per
year, people might try to negotiate you down to $25,000 per year, but it
wouldn't even occur to them to offer you fifty bucks.

During the recruiting process, you're entering implicit negotiations with the
job market, and the first few candidates it throws at you will act as the
anchor. Chances are, the first few candidates will be mediocre, so when you see
someone who's a lot better than mediocre (but still nowhere near stellar),
you'll automatically get excited about hiring them.

Over time, the pressure to hire people in order to deliver the product will
force you to second guess your standards. You'll start wondering if the
interview questions you're asking are too hard, or if your standards are
impossibly high. And you will hire mediocre employees who will hire more bad
people, who eventually will wreck your company. The problem seems easy to avoid
if you know about it, but in practice it's very difficult to fight your own
psychology.

So set the anchor first, before you even see the first resume. If you're
building a software startup, recognize that you're competing with everyone in
the world, and can only win if you first employees are the best in the world at
what they do. Not the "Northeast division" best. The Olympics best.
Theoretically, it's possible that your standard is unreasonably high, but in
practice people almost always have the opposite problem.

I look to Bell Labs for inspiration. At its peak, the folks at Bell Labs
developed radio astronomy, the transistor, the laser, information theory, the C
programming language, and the UNIX operating system. These are the kinds of
people you should be trying to hire. Think Dennis Ritchie before he developed
the C language. Think Claude Shannon before he invented information theory.
When in doubt, ask yourself: "would this person have been good enough to be
hired for a junior position at Bell Labs during its peak?" If the answer isn't
a resounding yes, it's a No Hire.

Knowing about these mistakes helped us tremendously to design a balanced hiring
process for recruiting great candidates. In the next post, I will cover the
structure of the actual interviews, our philosophy for picking technical
questions, and the exact types of questions we ask every candidate.

_Thanks to [Ben Kudria][7] and John Rizzo for feedback and many great
suggestions on how to improve this post._

[8]: http://ben.kudria.net/
