RethinkDB styles
===


## Components & Libraries

Relies on:

- [Bourbon](http://bourbon.io), a simple and lightweight library for Sass

- [Bourbon Neat](http://neat.bourbon.io), a lightweight and semantic library grid framework for Sass and Bourbon

- [Bitters](http://bitters.bourbon.io), scaffold styles, variables and structure for Bourbon projects

## Basic styles

Files are imported into the ``assets/css/styles.scss`` manifest file. Files at the top will be
compiled first. The Bourbon "suite" is included near the top, so that base styles from Bitters and a basic grid framework can used.

The Bitters base styles ``(_sass/base/)`` include a set of Sass variables, default element styles and project structure. Variables set in the ``_sass/base/_variables.scss`` file can be referenced globally.

Design patterns such as buttons, typography, lists, and modals are included inside the base folder. These are basic template styles for elements that can and should be customized when necessary.

## Grid framework

The grid used throughout the site is dependent on Bourbon Neat. Edit the ``_sass/base/_grid-settings.scss`` file to adjust responsive breakpoints, column/gutter widths, and the max-width of a page. Please note that the class ``.site-container`` and Bourbon's ``@include outer-container;`` mixin inherit the max-width property from Neat's ``$max-width`` variable.

Column helpers for defining layouts are in the ``_base/extends/_neat-columns.scss`` file. If one needs content to be a 1/3 of the page width, one can use the class ``.third`` on the content container. These column helpers rely on Neat's ``@include span-columns(number-o-columns)`` command. Please note that ``@include span-columns`` and the Neat column classes work best when the content's parent container has the class ``.site-container`` or has extended the ``@include outer-container`` mixin.

For example:

```html
<div class="site-container">

<div class="third">I'm a third</div>

<div class="third">You're a third</div>

<div class="third">We're all thirds</div>

</div>
```

## Mixins & Extends

When Bourbon mixins aren't enough, one can create custom mixins and reference them from the ``_sass/base/mixins/`` folder. Mixins should be used when one wants the output of the mixin to change depending on how one calls it.

Extends can be used when one notices multiple elements use the same CSS properties. Extends can help produce less CSS code, with the same number of selectors. One can create extends as needed in the ``_sass/base/extends/`` folder. Roy Tomeji wrote a simple guide explaining when one should use a mixin or extend [here](http://roytomeij.com/blog/2013/should-you-use-a-sass-mixin-or-extend.html). 

## Override & Add New Styles

When base styles aren't enough for specific pages, individual scss files should be written and referenced in the ``assets/css/styles.scss`` manifest file. For example, the home or 'landing' page has its own stylesheet ``_sass/_landing.scss``.

Individual page stylesheets can make use of extends and design patterns found in the base folder to minimize code duplication. For example, the ``_about.scss`` and ``_community.scss`` files both use the ``.hero-bg`` class. Both pages share a hero background design element. By extending ``.hero-bg``, both stylesheets rely on the base properties defined by the extend, but still set a custom background property.

One can look at ``_sass/base/extends/_hero-bg.scss`` to see the shared properties that will be used by ``@extend .hero-bg``. To see the specific styles related to the community or about page, one can reference the ``_sass/_community.scss`` file.

In ``_sass/_community.scss``:

```scss
.community-wrapper .hero {

@extend .hero-bg;

@include background-image(url("https://pbs.twimg.com/media/B3aNGmgCUAAupk4.png:large"));

background-size: cover;

}
```

In ``_sass/about.scss``:

```scss
.about .hero {

@include background-image(url("https://pbs.twimg.com/profile_banners/52351557/1399070558/1500x500"));

background-size: cover;

@extend .hero-bg;

}
```
