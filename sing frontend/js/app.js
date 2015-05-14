/**
 * Whether to use pjax page swithing
 * @type {boolean}
 */
window.PJAX_ENABLED = true;
/**
 * Whether to print some log information
 * @type {boolean}
 */
window.DEBUG = true;

/**
 * Plugins configuration options
 */

/**
 * Setting Widgster's body selector to theme specific
 * @type {string}
 */
$.fn.widgster.Constructor.DEFAULTS.bodySelector = '.widget-body';

$(function(){

    /**
     * Main app class that handles page switching, async script loading, resize & pageLoad callbacks.
     * Events:
     *   sing-app:loaded - fires after pjax request is made and ALL scripts are trully loaded
     *   sing-app:content-resize - fires when .content changes its size (e.g. switching between static & collapsing
     *     navigation states)
     * @constructor
     */
    var SingAppView = function(){

        this.pjaxEnabled = window.PJAX_ENABLED;
        this.debug = window.DEBUG;
        this.navCollapseTimeout = 2500;
        this.$sidebar = $('#sidebar');
        this.$content = $('#content');
        this.$loaderWrap = $('.loader-wrap');
        this.$navigationStateToggle = $('#nav-state-toggle');
        this.$navigationCollapseToggle = $('#nav-collapse-toggle');
        this.settings = window.SingSettings;
        this.pageLoadCallbacks = {};
        this.resizeCallbacks = [];
        this.screenSizeCallbacks = {
            xs:{enter:[], exit:[]},
            sm:{enter:[], exit:[]},
            md:{enter:[], exit:[]},
            lg:{enter:[], exit:[]}
        };
        this.loading = false;

        this._resetResizeCallbacks();
        this._initOnResizeCallbacks();
        this._initOnScreenSizeCallbacks();

        this.$sidebar.on('mouseenter', $.proxy(this._sidebarMouseEnter, this));
        this.$sidebar.on('mouseleave', $.proxy(this._sidebarMouseLeave, this));
        /**
         * open navigation in case collapsed sidebar clicked
         */
        $(document).on('click', '.nav-collapsed #sidebar', $.proxy(this.expandNavigation, this));
        //we don't need this cool feature for big boys
        ('ontouchstart' in window) && this.$content.swipe({
            swipeLeft: $.proxy(this._contentSwipeLeft, this),
            swipeRight: $.proxy(this._contentSwipeRight, this),
            threshold: Sing.isScreen('xs') ? 100 : 200
        });

        this.checkNavigationState();

        if (this.pjaxEnabled){
            /**
             * Initialize pjax & attaching all related events
             */
            this.$sidebar.find('.sidebar-nav a:not([data-toggle=collapse], [data-no-pjax], [href=#])').on('click', $.proxy(this._checkLoading, this));
            $(document).pjax('#sidebar .sidebar-nav a:not([data-toggle=collapse], [data-no-pjax], [href=#])', '#content', {
                fragment: '#content',
                type: 'GET', //this.debug ? 'POST' : 'GET' //GET - for production, POST - for debug.
                timeout: 4000
            });
            $(document).on('pjax:start', $.proxy(this._changeActiveNavigationItem, this));
            $(document).on('pjax:start', $.proxy(this._resetResizeCallbacks, this));
            $(document).on('pjax:send', $.proxy(this.showLoader, this));
            $(document).on('pjax:success', $.proxy(this._loadScripts, this));
            //custom event which fires when all scripts are actually loaded
            $(document).on('sing-app:loaded', $.proxy(this._loadingFinished, this));
            $(document).on('sing-app:loaded', $.proxy(this._collapseNavIfSmallScreen, this));
            $(document).on('sing-app:loaded', $.proxy(this.hideLoader, this));
            $(document).on('pjax:end', $.proxy(this.pageLoaded, this));
        }

        this.$navigationStateToggle.on('click', $.proxy(this.toggleNavigationState, this));
        this.$navigationCollapseToggle.on('click', $.proxy(this.toggleNavigationCollapseState, this));

        /* reimplementing bs.collapse data-parent here as we don't want to use BS .panel*/
        this.$sidebar.find('.collapse').on('show.bs.collapse', function(e){
            // execute only if we're actually the .collapse element initiated event
            // return for bubbled events
            if (e.target != e.currentTarget) return;

            var $triggerLink = $(this).prev('[data-toggle=collapse]');
            $($triggerLink.data('parent')).find('.collapse.in').not($(this)).collapse('hide');
        })
            /* adding additional classes to navigation link li-parent for several purposes. see navigation styles */
            .on('show.bs.collapse', function(e){
                // execute only if we're actually the .collapse element initiated event
                // return for bubbled events
                if (e.target != e.currentTarget) return;

                $(this).closest('li').addClass('open');
            }).on('hide.bs.collapse', function(e){
                // execute only if we're actually the .collapse element initiated event
                // return for bubbled events
                if (e.target != e.currentTarget) return;

                $(this).closest('li').removeClass('open');
            });

        window.onerror = $.proxy(this._logErrors, this);
    };

    /**
     * Initiates an array of throttle onResize callbacks.
     * @private
     */
    SingAppView.prototype._initOnResizeCallbacks = function(){
        var resizeTimeout,
            view = this;

        $(window).on('resize sing-app:content-resize', function() {
            clearTimeout(resizeTimeout);
            resizeTimeout = setTimeout(function(){
                view._runPageCallbacks(view.pageResizeCallbacks);
                view.resizeCallbacks.forEach(function(fn){
                    fn();
                });
            }, 100);
        });
    };

    /**
     * Initiates an array of throttle onScreenSize callbacks.
     * @private
     */
    SingAppView.prototype._initOnScreenSizeCallbacks = function(){
        var resizeTimeout,
            view = this,
            prevSize = Sing.getScreenSize();

        $(window).resize(function() {
            clearTimeout(resizeTimeout);
            resizeTimeout = setTimeout(function(){
                var size = Sing.getScreenSize();
                if (size != prevSize){ //run only if something changed
                    //run exit callbacks first
                    view.screenSizeCallbacks[prevSize]['exit'].forEach(function(fn){
                        fn(size, prevSize);
                    });
                    //run enter callbacks then
                    view.screenSizeCallbacks[size]['enter'].forEach(function(fn){
                        fn(size, prevSize);
                    });
                    view.log('screen changed. new: ' + size + ', old: ' + prevSize);
                }
                prevSize = size;
            }, 100);
        });
    };

    SingAppView.prototype._resetResizeCallbacks = function(){
        this.pageResizeCallbacks = {};
    };

    /**
     * Collapses navigation if nav-static local storage option is set to false
     */
    SingAppView.prototype.checkNavigationState = function(){
        if (this.isNavigationStatic()){
            this.staticNavigationState();
            if (Sing.isScreen('sm') || Sing.isScreen('xs')){
                this.collapseNavigation();
            }
        } else {
            if (Sing.isScreen('md') || Sing.isScreen('lg')){
                var view = this;
                setTimeout(function(){
                    view.collapseNavigation();
                }, this.navCollapseTimeout);
            } else {
                this.collapseNavigation();
            }
        }
    };

    /**
     * Expands or collapses navigation. Valid only for collapsing navigation state
     */
    SingAppView.prototype.toggleNavigationCollapseState = function(){
        if ($('body').is('.nav-collapsed')){
            this.expandNavigation();
        } else {
            this.collapseNavigation();
        }
    };

    SingAppView.prototype.collapseNavigation = function(){
        //this method only makes sense for non-static navigation state
        if (this.isNavigationStatic() && (Sing.isScreen('md') || Sing.isScreen('lg'))) return;

        $('body').addClass('nav-collapsed');
        this.$sidebar.find('.collapse.in').collapse('hide')
            .siblings('[data-toggle=collapse]').addClass('collapsed');
    };

    SingAppView.prototype.expandNavigation = function(){
        //this method only makes sense for non-static navigation state
        if (this.isNavigationStatic() && (Sing.isScreen('md') || Sing.isScreen('lg'))) return;

        $('body').removeClass('nav-collapsed');
        this.$sidebar.find('.active .active').closest('.collapse').collapse('show')
            .siblings('[data-toggle=collapse]').removeClass('collapsed');
    };

    SingAppView.prototype._sidebarMouseEnter = function(){
        if (Sing.isScreen('md') || Sing.isScreen('lg')){
            this.expandNavigation();
        }
    };

    SingAppView.prototype._sidebarMouseLeave = function(){
        if (Sing.isScreen('md') || Sing.isScreen('lg')){
            this.collapseNavigation();
        }
    };

    SingAppView.prototype._collapseNavIfSmallScreen = function(){
        if (Sing.isScreen('xs') || Sing.isScreen('sm')){
            this.collapseNavigation();
        }
    };

    /**
     * Toggles between static and collapsing navigation states.
     * Collapsing - navigation automatically collapse when mouse leaves it and expand when enters.
     * Static - stays always open.
     */
    SingAppView.prototype.toggleNavigationState = function(){
        if (this.isNavigationStatic()){
            this.collapsingNavigationState();
        } else {
            this.staticNavigationState();
        }
        $(window).trigger('sing-app:content-resize');
    };

    /**
     * Turns on static navigation state.
     * Collapsing navigation state - navigation automatically collapse when mouse leaves it and expand when enters.
     * Static navigation state - navigation stays always open.
     */
    SingAppView.prototype.staticNavigationState = function(){
        this.settings.set('nav-static', true).save();
        $('body').addClass('nav-static');
    };

    /**
     * Turns on collapsing navigation state.
     * Collapsing navigation state - navigation automatically collapse when mouse leaves it and expand when enters.
     * Static navigation state - navigation stays always open.
     */
    SingAppView.prototype.collapsingNavigationState = function(){
        this.settings.set('nav-static', false).save();
        $('body').removeClass('nav-static');
        this.collapseNavigation();
    };

    SingAppView.prototype.isNavigationStatic = function(){
        return this.settings.get('nav-static') === true;
    };

    /**
     * Changes active navigation item depending on current page.
     * Should be executed before page load
     * @param event
     * @param xhr
     * @param options
     * @private
     */
    SingAppView.prototype._changeActiveNavigationItem = function(event, xhr, options){
        var $newActiveLink = this.$sidebar.find('a[href*="' + this.extractPageName(options.url) + '"]').filter(function(){
            return this.href === options.url;
        });

        // collapse .collapse only if new and old active links belong to different .collapse
        if (!$newActiveLink.is('.active > .collapse > li > a')){
            this.$sidebar.find('.active .active').closest('.collapse').collapse('hide');
        }
        this.$sidebar.find('.active').removeClass('active');

        $newActiveLink.closest('li').addClass('active')
            .parents('li').addClass('active');
    };

    /**
     * Checks whether screen is sm or md and closes navigation if opened
     * @private
     */
    SingAppView.prototype._contentSwipeLeft = function(){
        //this method only makes sense for small screens + ipad
        if (Sing.isScreen('lg')) return;

        if (!$('body').is('.nav-collapsed')){
            this.collapseNavigation();
        }
    };

    /**
     * Checks whether screen is sm or md and opens navigation if closed
     * @private
     */
    SingAppView.prototype._contentSwipeRight = function(){
        //this method only makes sense for small screens + ipad
        if (Sing.isScreen('lg')) return;

        // fixme. this check is bad. I know. breaks loose coupling principle
        // SingApp should not know about some "strange" sidebar chat.
        // check line 726 for more info
     /*   if ($('body').is('.chat-sidebar-closing')) return;

        if ($('body').is('.nav-collapsed')){
            this.expandNavigation();
        }*/
    };

    SingAppView.prototype.showLoader = function(){
        var view = this;
        this.showLoaderTimeout = setTimeout(function(){
            view.$loaderWrap.removeClass('hide');
            setTimeout(function(){
                view.$loaderWrap.removeClass('hiding');
            }, 0)
        }, 200);
    };

    SingAppView.prototype.hideLoader = function(){
        clearTimeout(this.showLoaderTimeout);
        this.$loaderWrap.addClass('hiding');
        var view = this;
        this.$loaderWrap.one($.support.transition.end, function () {
            view.$loaderWrap.addClass('hide');
        }).emulateTransitionEnd(200)
    };

    /**
     * Specify a function to execute when window was resized or .content size was changed (e.g. sidebar static/collapsed).
     * Runs maximum once in 100 milliseconds (throttle).
     * Page dependent. So `fn` will be executed only when at the page it was added.
     * Cleaned after page left.
     * @param fn A function to execute
     * @param allPages whether to keep callback after leaving page
     */
    SingAppView.prototype.onResize = function(fn, /**Boolean=*/ allPages){
        allPages = typeof allPages !== 'undefined' ? allPages : false;
        if (allPages){
            this.resizeCallbacks.push(fn);
        } else {
            this._addPageCallback(this.pageResizeCallbacks, fn);
        }
    };

    /**
     * Specify a function to execute when a page was reloaded with pjax.
     * @param fn A function to execute
     */
    SingAppView.prototype.onPageLoad = function(fn){
        this._addPageCallback(this.pageLoadCallbacks, fn);
    };

    /**
     * Specify a function to execute when window entered/exited particular size.
     * Page independent. Runs regardless of current page (on every page).
     * @param size ('xs','sm','md','lg')
     * @param fn callback(newScreenSize, prevScreenSize)
     * @param onEnter whether to run a callback when screen enters `size` or exits. true by default @optional
     */
    SingAppView.prototype.onScreenSize = function(size, fn, /**Boolean=*/ onEnter){
        onEnter = typeof onEnter !== 'undefined' ? onEnter : true;
        this.screenSizeCallbacks[size][onEnter ? 'enter' : 'exit'].push(fn)
    };

    /**
     * Runs page loaded callbacks
     */
    SingAppView.prototype.pageLoaded = function(){
        this._runPageCallbacks(this.pageLoadCallbacks);
    };

    /**
     * Convenient private method to add app callback depending on current page.
     * @param callbacks
     * @param fn callback to execute
     * @private
     */
    SingAppView.prototype._addPageCallback = function(callbacks, fn){
        var pageName = this.extractPageName(location.href);
        if (!callbacks[pageName]){
            callbacks[pageName] = [];
        }
        callbacks[pageName].push(fn);
    };

    /**
     * Convenient private method to run app callbacks depending on current page.
     * @param callbacks
     * @private
     */
    SingAppView.prototype._runPageCallbacks = function(callbacks){
        var pageName = this.extractPageName(location.href);
        if (callbacks[pageName]){
            callbacks[pageName].forEach(function(fn){
                fn();
            })
        }
    };

    /**
     * Parses entire body response in order to find & execute script tags.
     * This has to be done because it's only .content attached to the page after ajax request.
     * Usually content does not contain all scripts required from page loading, so need to additionally extract them from body response.
     * @param event
     * @param data
     * @param status
     * @param xhr
     * @param options
     * @private
     */
    SingAppView.prototype._loadScripts = function(event, data, status, xhr, options){
        var $bodyContents = $($.parseHTML(data.match(/<body[^>]*>([\s\S.]*)<\/body>/i)[0], document, true)),
            $scripts = $bodyContents.filter('script[src]').add($bodyContents.find('script[src]')),
            $templates = $bodyContents.filter('script[type="text/template"]').add($bodyContents.find('script[type="text/template"]')),
            $existingScripts = $('script[src]'),
            $existingTemplates = $('script[type="text/template"]');

        //append templates first as they are used by scripts
        $templates.each(function() {
            var id = this.id;
            var matchedTemplates = $existingTemplates.filter(function() {
                //noinspection JSPotentiallyInvalidUsageOfThis
                return this.id === id;
            });
            if (matchedTemplates.length) return;

            var script = document.createElement('script');
            script.id = $(this).attr('id');
            script.type = $(this).attr('type');
            script.innerHTML = this.innerHTML;
            document.body.appendChild(script);
        });



        //ensure synchronous loading
        var $previous = {
            load: function(fn){
                fn();
            }
        };

        $scripts.each(function() {
            var src = this.src;
            var matchedScripts = $existingScripts.filter(function() {
                //noinspection JSPotentiallyInvalidUsageOfThis
                return this.src === src;
            });
            if (matchedScripts.length) return;

            var script = document.createElement('script');
            script.src = $(this).attr('src');
            $previous.load(function(){
                document.body.appendChild(script);
            });

            $previous = $(script);
        });

        var view = this;
        $previous.load(function(){
            $(document).trigger('sing-app:loaded');
            view.log('scripts loaded.');
        })
    };

    SingAppView.prototype.extractPageName = function(url){
        //credit: http://stackoverflow.com/a/8497143/1298418
        var pageName = url.split('#')[0].substring(url.lastIndexOf("/") + 1).split('?')[0];
        return pageName === '' ? 'index.html' : pageName;
    };

    SingAppView.prototype._checkLoading = function(e){
        var oldLoading = this.loading;
        this.loading = true;
        if (oldLoading){
            this.log('attempt to load page while already loading; preventing.');
            e.preventDefault();
        } else {
            this.log(e.currentTarget.href + ' loading started.');
        }
        //prevent default if already loading
        return !oldLoading;
    };

    SingAppView.prototype._loadingFinished = function(){
        this.loading = false;
    };

    SingAppView.prototype._logErrors = function(){
        var errors = JSON.parse(localStorage.getItem('lb-errors')) || {};
        errors[new Date().getTime()] = arguments;
        localStorage.setItem('sing-errors', JSON.stringify(errors));
        this.debug && alert('check errors');
    };

    SingAppView.prototype.log = function(message){
        if (this.debug){
            console.log("SingApp: "
                    + message
                    + " - " + arguments.callee.caller.toString().slice(0, 30).split('\n')[0]
                    + " - " + this.extractPageName(location.href)
            );
        }
    };


    window.SingApp = new SingAppView();

//    SingApp.expandNavigation();

    initAppPlugins();
    initAppFunctions();
    initAppFixes();
    initDemoFunctions();
});

/**
 * Theme functions extracted to independent plugins.
 */
function initAppPlugins(){
    /* ========================================================================
     * Handle transparent input groups focus
     * ========================================================================
     */
    !function($){

        $.fn.transparentGroupFocus = function () {
            return this.each(function () {
                $(this).find('.input-group-addon + .form-control').on('blur focus', function(e){
                    $(this).parents('.input-group')[e.type=='focus' ? 'addClass' : 'removeClass']('focus');
                });
            })
        };

        $('.input-group-transparent, .input-group-no-border').transparentGroupFocus();
    }(jQuery);

    /* ========================================================================
     * Ajax Load links, buttons & inputs
     * loads #data-ajax-target from url provided in data-ajax-load
     * ========================================================================
     */
    !function($){
        $(document).on('click change', '[data-ajax-load], [data-ajax-trigger^=change]', function(e){
            var $this = $(this),
                $target = $($this.data('ajax-target'));
            if ($target.length > 0 ){
                e = $.Event('ajax-load:start', {originalEvent: e});
                $this.trigger(e);

                !e.isDefaultPrevented() && $target.load($this.data('ajax-load'), function(){
                    $this.trigger('ajax-load:end');
                });
            }
            return false;
        });
        $(document).on('click', '[data-toggle^=button]', function (e) {
            return $(e.target).find('input').data('ajax-trigger') != 'change';
        })
    }(jQuery);


    /* ========================================================================
     * Table head check all checkboxes
     * ========================================================================
     */
    !function($){
        $(document).on('click', 'table th [data-check-all]', function () {
            $(this).closest('table').find('input[type=checkbox]')
                .not(this).prop('checked', $(this).prop('checked'));
        });
    }(jQuery);

    /* ========================================================================
     * Animate Progress Bars
     * ========================================================================
     */
    !function($){

        $.fn.animateProgressBar = function () {
            return this.each(function () {
                var $bar = $(this).find('.progress-bar');
                setTimeout(function(){
                    $bar.css('width', $bar.data('width'));
                }, 0)
            })
        };

        $('.js-progress-animate').animateProgressBar();
    }(jQuery);
}

/**
 * Sing required js functions
 */
function initAppFunctions(){
    !function($){
        /**
         * Change to loading state when fetching notifications
         */
        var $loadNotificationsBtn = $('#load-notifications-btn');
        $loadNotificationsBtn.on('ajax-load:start', function (e) {
            $loadNotificationsBtn.button('loading');
        });
        $loadNotificationsBtn.on('ajax-load:end', function () {
            $loadNotificationsBtn.button('reset');
        });

        /**
         * Move notifications dropdown to sidebar when/if screen goes xs
         * and back when leaves xs
         */
        function moveNotificationsDropdown(){
            $('.sidebar-status .dropdown-toggle').after($('#notifications-dropdown-menu').detach());
        }

        function moveBackNotificationsDropdown(){
            $('#notifications-dropdown-toggle').after($('#notifications-dropdown-menu').detach());
        }
        SingApp.onScreenSize('xs', moveNotificationsDropdown);
        SingApp.onScreenSize('xs', moveBackNotificationsDropdown, false);

        Sing.isScreen('xs') && moveNotificationsDropdown();

        /**
         * Set Sidebar zindex higher than .content and .page-controls so the notifications dropdown is seen
         */
        $('.sidebar-status').on('show.bs.dropdown', function(){
            $('#sidebar').css('z-index', 2);
        }).on('hidden.bs.dropdown', function(){
            $('#sidebar').css('z-index', '');
        });

        /**
         * Show help tooltips
         */
        $('#nav-state-toggle, #nav-collapse-toggle').tooltip();

        function initSidebarScroll(){
            var $sidebarContent = $('.js-sidebar-content');
            if ($('#sidebar').find('.slimScrollDiv').length != 0){
                $sidebarContent.slimscroll({
                    destroy: true
                })
            }
            $sidebarContent.slimscroll({
                height: window.innerHeight,
                size: '4px'
            });
        }

        SingApp.onResize(initSidebarScroll, true);
        initSidebarScroll();

        /*
         When widget is closed remove its parent if it is .col-*
         */
        $(document).on('close.widgster', function(e){
            var $colWrap = $(e.target).closest('.content > .row > [class*="col-"]:not(.widget-container)');

            // remove colWrap only if there are no more widgets inside
            if (!$colWrap.find('.widget').not(e.target).length){
                $colWrap.remove();
            }
        });

    }(jQuery);

    /* ========================================================================
     * Chat Sidebar
     * ========================================================================
     */
    !function($){
        //.chat-sidebar-container contains all needed styles so we don't pollute body{ }
      /*  var $chatContainer = $('body').addClass('chat-sidebar-container');
        $(document).on('click', '[data-toggle=chat-sidebar]', function(){
            $chatContainer.toggleClass('chat-sidebar-opened');
            $(this).find('.chat-notification-sing').remove();*/
        });

        /*
         * Open chat on swipe left but first check if navigation is collapsed
         * otherwise do nothing
         */
        $('#content').on('swipeLeft', function(e){
            console.log(arguments);
            if ($('body').is('.nav-collapsed')){
                $chatContainer.addClass('chat-sidebar-opened');
            }
        })
            /*
             * Hide chat on swipe right but first check if navigation is collapsed
             * otherwise do nothing
             */
            .on('swipeRight', function(e){
            if ($('body').is('.nav-collapsed.chat-sidebar-opened')){
                $chatContainer.removeClass('chat-sidebar-opened')
                    // as there is no way to cancel swipeLeft handlers attached to
                    // .content making this hack with temporary class which will be
                    // used by SingApp to check whether it is permitted to open navigation
                    // on swipeRight
                    .addClass('chat-sidebar-closing').one($.support.transition.end, function () {
                        $('body').removeClass('chat-sidebar-closing');
                    }).emulateTransitionEnd(300);
            }
        });

        $(document).on('click', '.chat-sidebar-user-group > a', function(){
            var $this = $(this),
                $target = $($this.attr('href')),
                $targetTitle = $target.find('.title');
            $this.removeClass('active').find('.badge').remove();
            $target.addClass('open');
            $('.chat-sidebar-contacts').removeClass('open');
            $('.chat-sidebar-footer').addClass('open');
            $('.message-list', $target).slimscroll({
                height: $target.height() - $targetTitle.height()
                    - parseInt($targetTitle.css('margin-top'))
                    - parseInt($targetTitle.css('margin-bottom')),
                width: '',
                size: '4px'
            });
            return false;
        });

        $(document).on('click', '.chat-sidebar-chat .js-back', function(){
            var $chat = $(this).closest('.chat-sidebar-chat').removeClass('open');
            var $sidebarContacts = $('.chat-sidebar-contacts').addClass('open');
            $('.chat-sidebar-footer').removeClass('open');

            return false;
        });

        $('#chat-sidebar-input').keyup(function(e){
            if(e.keyCode != 13) return;
            var val;
            if ((val = $(this).val().trim()) == '') return;

            var $currentMessageList = $('.chat-sidebar-chat.open .message-list'),
                $message = $('<li class="message from-me">' +
                    '<span class="thumb-sm"><img class="img-circle" src="img/avatar.png" alt="..."></span>' +
                    '<div class="message-body"></div>' +
                    '</li>');
            $message.appendTo($currentMessageList).find('.message-body').text(val);
            $(this).val('');
        });

        $('#chat-sidebar-search').keyup(function(){
            var $contacts = $('.chat-sidebar-contacts.open'),
                $chat = $('.chat-sidebar-chat.open'),
                val = $(this).val().trim().toUpperCase();
            if ($contacts.length){
                $('.chat-sidebar-user-group .list-group-item').addClass('hide').filter(function(){
                    return val == '' ? true : ($(this).find('.message-sender').text().toUpperCase().indexOf(val) != -1)
                }).removeClass('hide');
            }
            if ($chat.length){
                $('.chat-sidebar-chat.open .message-list .message').addClass('hide').filter(function(){
                    return val == '' ? true : ($(this).find('.message-body').text().toUpperCase().indexOf(val) != -1)
                }).removeClass('hide');
            }
        });

        function initChatSidebarScroll(){
            var $sidebarContent = $('.chat-sidebar-contacts');
            if ($('#chat').find('.slimScrollDiv').length != 0){
                $sidebarContent.slimscroll({
                    destroy: true
                })
            }
            $sidebarContent.slimscroll({
                height: window.innerHeight,
                width: '',
                size: '4px'
            });
        }

        SingApp.onResize(initChatSidebarScroll, true);
        initChatSidebarScroll();
    }(jQuery);
}



/**
 * Sing browser fixes. It's always something broken somewhere
 */
function initAppFixes(){
    var isWebkit = 'WebkitAppearance' in document.documentElement.style;
    if (isWebkit){
    }
}

/**
 * Demo-only functions. Does not affect the core Sing functionality.
 * Should be removed when used in real app.
 */
function initDemoFunctions(){
    !function($){
        $('#load-notifications-btn').on('ajax-load:end', function () {
            setTimeout(function(){
                $('#notifications-list').find('.bg-attention').removeClass('bg-attention');
            }, 10000)
        });
        $('#notifications-toggle').find('input').on('ajax-load:end', function(){
            $('#notifications-list').find('[data-toggle=tooltip]').tooltip();
        });

        $('[data-toggle="chat-sidebar"]').one('click', function(){
            setTimeout(function(){
                $('.chat-sidebar-user-group:first-of-type .list-group-item:first-child').addClass('active')
                    .find('.fa-circle').after('<span class="badge badge-danger pull-right animated bounceInDown">3</span>');
            }, 1000)
        });

        setTimeout(function(){
            var $chatNotification = $('#chat-notification');
            $chatNotification.removeClass('hide').addClass('animated fadeIn')
                .one('webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend', function(){
                    $chatNotification.removeClass('animated fadeIn');
                    setTimeout(function(){
                        $chatNotification.addClass('animated fadeOut')
                            .one('webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend', function(){
                              $chatNotification.addClass('hide');
                            });
                    }, 4000);
                });
            $chatNotification.siblings('[data-toggle="chat-sidebar"]').append('<i class="chat-notification-sing animated bounceIn"></i>')
        }, 4000)

    }(jQuery);
}