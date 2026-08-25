// aHR0cHM6Ly9naXRodWIuY29tL2x1b3N0MjYvYWNhZGVtaWMtaG9tZXBhZ2U=
$(function () {
    lazyLoadOptions = {
        scrollDirection: 'vertical',
        effect: 'fadeIn',
        effectTime: 300,
        placeholder: "",
        onError: function(element) {
            console.log('[lazyload] Error loading ' + element.data('src'));
        },
        afterLoad: function(element) {
            if (element.is('img')) {
                // remove background-image style
                element.css('background-image', 'none');
                element.css('min-height', '0');
            } else if (element.is('div')) {
                // set the style to background-size: cover; 
                element.css('background-size', 'cover');
                element.css('background-position', 'center');
            }
        }
    }

    $('img.lazy, div.lazy:not(.always-load)').Lazy({visibleOnly: true, ...lazyLoadOptions});
    $('div.lazy.always-load').Lazy({visibleOnly: false, ...lazyLoadOptions});

    $('[data-toggle="tooltip"]').tooltip()

    var wechatModalScrollY = 0;
    var lastStableScrollY = window.pageYOffset || document.documentElement.scrollTop || 0;
    var hasWechatModalScrollY = false;
    var $wechatProfileSticky = $();
    var freezeWechatProfileCard = function () {
        $wechatProfileSticky = $('.profile-mini-card').closest('.row.sticky-top');
        if (!$wechatProfileSticky.length || $wechatProfileSticky.data('wechat-frozen')) {
            return;
        }

        var rect = $wechatProfileSticky[0].getBoundingClientRect();
        var marginLeft = parseFloat(window.getComputedStyle($wechatProfileSticky[0]).marginLeft) || 0;
        $wechatProfileSticky
            .data('wechat-frozen', true)
            .css({
                position: 'fixed',
                top: rect.top + 'px',
                left: (rect.left - marginLeft) + 'px',
                width: rect.width + 'px',
                zIndex: 1
            });
    };
    var unfreezeWechatProfileCard = function () {
        if (!$wechatProfileSticky.length) {
            return;
        }

        $wechatProfileSticky
            .removeData('wechat-frozen')
            .css({
                position: '',
                top: '',
                left: '',
                width: '',
                zIndex: ''
            });
    };
    var captureWechatModalScroll = function () {
        wechatModalScrollY = lastStableScrollY;
        hasWechatModalScrollY = true;
        freezeWechatProfileCard();
    };
    var restoreWechatModalScroll = function () {
        if (hasWechatModalScrollY && window.pageYOffset !== wechatModalScrollY) {
            window.scrollTo(0, wechatModalScrollY);
        }
    };
    var isWechatModalTrigger = function (event) {
        return event.target && event.target.closest && event.target.closest('[data-target="#modal-wechat"]');
    };

    ['pointerdown', 'mousedown', 'touchstart', 'focusin', 'click'].forEach(function (eventName) {
        document.addEventListener(eventName, function (event) {
            if (isWechatModalTrigger(event)) {
                captureWechatModalScroll();
            }
        }, true);
    });

    $('[data-target="#modal-wechat"]').on('pointerenter mouseenter focusin pointerdown mousedown touchstart', captureWechatModalScroll);
    $('[data-target="#modal-wechat"]').on('click', function () {
        if (!hasWechatModalScrollY) {
            captureWechatModalScroll();
        }
        window.setTimeout(restoreWechatModalScroll, 0);
        window.setTimeout(restoreWechatModalScroll, 50);
        window.requestAnimationFrame(restoreWechatModalScroll);
    });

    $('#modal-wechat').on('show.bs.modal', function () {
        if (!hasWechatModalScrollY) {
            captureWechatModalScroll();
        }
        window.setTimeout(restoreWechatModalScroll, 0);
        window.setTimeout(restoreWechatModalScroll, 50);
        window.requestAnimationFrame(restoreWechatModalScroll);
    });

    $('#modal-wechat').on('shown.bs.modal', restoreWechatModalScroll);
    $('#modal-wechat').on('hidden.bs.modal', function () {
        unfreezeWechatProfileCard();
        restoreWechatModalScroll();
        window.setTimeout(restoreWechatModalScroll, 0);
        window.setTimeout(function () {
            restoreWechatModalScroll();
            hasWechatModalScrollY = false;
            lastStableScrollY = window.pageYOffset || document.documentElement.scrollTop || 0;
        }, 50);
    });

    $(window).on('scroll', function () {
        if (!hasWechatModalScrollY && !$('#modal-wechat').hasClass('show') && !$('body').hasClass('modal-open')) {
            lastStableScrollY = window.pageYOffset || document.documentElement.scrollTop || 0;
        }
    });

    var $grid = $('.grid').masonry({
        "percentPosition": true,
        "itemSelector": ".grid-item",
        "columnWidth": ".grid-sizer"
    });
    // layout Masonry after each image loads
    $grid.imagesLoaded().progress(function () {
        $grid.masonry('layout');
    });

    $(".lazy").on("load", function () {
        $grid.masonry('layout');
    });
})
