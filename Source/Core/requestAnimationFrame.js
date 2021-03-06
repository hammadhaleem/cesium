/*global define*/
define(function() {
    "use strict";

    var requestAnimationFrameImplementation = window.requestAnimationFrame;

    // look for vendor prefixed function
    if (typeof requestAnimationFrameImplementation === 'undefined') {
        var vendors = ['webkit', 'moz', 'ms', 'o'];
        var i = 0;
        var len = vendors.length;
        while (i < len && typeof requestAnimationFrameImplementation === 'undefined') {
            requestAnimationFrameImplementation = window[vendors[i] + 'RequestAnimationFrame'];
            ++i;
        }
    }

    // build an implementation based on setTimeout
    if (typeof requestAnimationFrameImplementation === 'undefined') {
        var lastFrameTime = 0;
        requestAnimationFrameImplementation = function(callback) {
            var currentTime = Date.now();

            // schedule the callback to target 60fps, 16.7ms per frame,
            // accounting for the time taken by the callback
            var delay = Math.max(16 - (currentTime - lastFrameTime), 0);
            lastFrameTime = currentTime + delay;

            return setTimeout(function() {
                callback(lastFrameTime);
            }, delay);
        };
    }

    /**
     * A browser-independent function to request a new animation frame.  This is used to create
     * an application's draw loop as shown in the example below.
     *
     * @exports requestAnimationFrame
     *
     * @param {Function} callback The function to call when animation is ready.
     *
     * @example
     * // Create a draw loop using requestAnimationFrame. The
     * // tick callback function is called for every animation frame.
     * function tick() {
     *   scene.render();
     *   requestAnimationFrame(tick);
     * }
     * tick();
     *
     * @see <a href='http://www.w3.org/TR/animation-timing/#the-WindowAnimationTiming-interface'>The WindowAnimationTiming interface</a>
     */
    var requestAnimationFrame = function(callback) {
        // we need this extra wrapper function because the native requestAnimationFrame
        // functions must be invoked on the global scope (window), which is not the case
        // if invoked as Cesium.requestAnimationFrame(callback)
        requestAnimationFrameImplementation(callback);
    };
    return requestAnimationFrame;
});