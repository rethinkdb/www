---
---

'use strict';

class SiteUtils {
    constructor() {
        $(() => {
            /* ------------
               Global mobile menu: right side
               -> open / close the right-side menu
               ------------ */
            $('.menu-trigger a').click((event) => {
                event.preventDefault();
                $('body').toggleClass('pmr-open');
            });

            /* ------------
               Blog right panel should be set to a fixed position on scroll
               ------------ */
            const $_sidebar = $('.blog-sidebar ul');
            if ($_sidebar.length) {
                const blog_sidebar_sticky = new Waypoint.Sticky({ element: $('.blog-sidebar ul') });
                blog_sidebar_github = new Waypoint({
                    element: $('.blog-sidebar ul'),
                    handler: () => {
                        // Delay the popup animation
                        setTimeout(() => {
                            $('.github-star .popup', $_sidebar).removeClass('hidden')
                        }, 2000);
                    }
                });
            }

            /* ------------
               Docs navigation: collapse / expand sections
               ------------ */
            $('.docs-nav h1, .mobile-doc-links h1').click((event) => {
                $(this).toggleClass('expand').next('ul').slideToggle('fast', () => {
                     // Refresh any waypoints: expanding the the menu may have shifted trigger points
                    if (Waypoint) { Waypoint.refreshAll(); }
                });
                event.preventDefault();
                return;
            });

            this.rewrite_links();
            this.create_video_modals();
        });
    }
    /* ------------
       Landing page: video modals
       ------------ */
    create_video_modals() {
        // -> show a video modal on click
        $('.video').click((event) => {
            event.preventDefault()
            const $modal = $('.video-modal', this);

            // Buid the iframe for the YouTube embed
            // -------------------------------------
            // Get the YouTube video id
            const yt = $modal.data('youtube-id');
            // Specify iframe attributes
            const attrs = "width='560' height='315' frameborder='0' allowfullscreen";
            // YouTube video options
            const opts = "rel=0&autoplay=1&autohide=1";
            // Video to show
            const src = `src='//www.youtube.com/embed/${yt}?${opts}'`;
            const iframe = `<iframe ${attrs} ${src}></iframe>`;

            // Add the iframe to the modal
            $('.iframe-container', $modal).html(iframe);

            // Fade in the modal
            $modal.fadeIn('fast');
        });

        // Two ways to dismiss videos: clicking outside the video or pressing ESC
        $('.video-modal').on('click', (event) => {
            event.preventDefault();
            event.stopPropagation();
            this.dismiss_video();
        });
        $(document).keyup((event) => {
            if (event.keyCode == 27) {
                this.dismiss_video();
            }
        });
    }

    // -> hide the video modal
    dismiss_video() {
        $modal = $('.video-modal:visible')
        $modal.fadeOut('fast', () => {
            // Once the modal has faded out, reset the content once again
            $('.iframe-container').empty();
        });
    }

    /* ------------
       Rewrite links that point to multi-language
       documents, based on the language switcher + a cookie
       ------------*/
    rewrite_links() {
        // List of multi-language documents
        const routes = {
            '/api/': true,
            '/docs/changefeeds/': true,
            '/docs/cookbook/': true,
            '/docs/dates-and-times/': true,
            '/docs/geo-support/': true,
            '/docs/guide/': true,
            '/docs/nested-fields/': true,
            '/docs/publish-subscribe/': true,
            '/docs/rabbitmq/': true,
            '/docs/secondary-indexes/': true,
            '/docs/sql-to-reql/': true,
            '/docs/storing-binary/': true,
        };

        // Get the current language from a cookie, if it exists
        let lang = Cookies.get('lang');

        // Set the cookie with the current language in either case
        if (lang === undefined) {
            lang = 'javascript';
            Cookies.set('lang', lang, { path: '/' });
        }
        else if ( /javascript/.test(document.location.pathname)) {
            if (lang !== 'javascript') {
                lang = 'javascript';
                Cookies.set('lang', lang, { path: '/' });
            }
        }
        else if (/python/.test(document.location.pathname)) {
            if (lang !== 'python') {
                lang = 'python';
                Cookies.set('lang', lang, { path: '/' });
            }
        }
        else if (/ruby/.test(document.location.pathname)) {
            if (lang !== 'ruby') {
                lang = 'ruby';
                Cookies.set('lang', lang, { path: '/' });
            }
        }

        // Rewrite the links on the page
        const links_on_page = $('a');
        for (let i=0; i < links_on_page.length; i++) {
            let link = links_on_page[i];
            let href = $(link).attr('href');
            if (href === undefined) {
                continue;
            }
            // Trim the hash at the end of URLs
            if (href.substr(-1) === '#') {
                href = href.substr(0, href.length-1);
            }
            // Make sure there's a trailing slash
            if (href.substr(-1) !== '/') {
                href = "#{href}/";
            }
            // Rewrite only the right links
            if (routes[href]) {
                $(link).attr('href', href+lang+'/');
            }
        }
    }
}

const site = new SiteUtils();
