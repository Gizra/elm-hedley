Elm.Native = Elm.Native || {};
Elm.Native.WebAPI = Elm.Native.WebAPI || {};
Elm.Native.WebAPI.AnimationFrame = Elm.Native.WebAPI.AnimationFrame || {};

// http://paulirish.com/2011/requestanimationframe-for-smart-animating/
// http://my.opera.com/emoller/blog/2011/12/20/requestanimationframe-for-smart-er-animating
 
// requestAnimationFrame polyfill by Erik Möller
// fixes from Paul Irish and Tino Zijdel
// list-based fallback implementation by Jonas Finnemann Jensen

var raf = window.requestAnimationFrame;
var caf = window.cancelAnimationFrame;

if (!raf) {
    var tid = null, cbs = [], nb = 0, ts = 0;

    function animate () {
        var i, clist = cbs, len = cbs.length;
        tid = null;
        ts = Date.now();
        cbs = [];
        nb += clist.length;

        for (i = 0; i < len; i++) {
            if (clist[i]) clist[i](ts);
        }
    }

    raf = function (cb) {
        if (tid == null) {
            tid = setTimeout(animate, Math.max(0, 20 + ts - Date.now()));
        }

        return cbs.push(cb) + nb;
    };

    caf = function (id) {
        delete cbs[id - nb - 1];
    };
}

Elm.Native.WebAPI.AnimationFrame.make = function (localRuntime) {
    localRuntime.Native = localRuntime.Native || {};
    localRuntime.Native.WebAPI = localRuntime.Native.WebAPI || {};
    localRuntime.Native.WebAPI.AnimationFrame = localRuntime.Native.WebAPI.AnimationFrame || {};

    if (!localRuntime.Native.WebAPI.AnimationFrame.values) {
        var Task = Elm.Native.Task.make(localRuntime);
        var Utils = Elm.Native.Utils.make(localRuntime);

        localRuntime.Native.WebAPI.AnimationFrame.values = {
            task: Task.asyncFunction(function (callback) {
                raf(function (time) {
                    callback(Task.succeed(time));
                });
            }),

            request: function (taskProducer) {
                return Task.asyncFunction(function (callback) {
                    var request = raf(function (time) {
                        Task.perform(taskProducer(time));
                    });

                    callback(Task.succeed(request));
                });
            },

            cancel: function (request) {
                return Task.asyncFunction(function (callback) {
                    caf(request);
                    callback(Task.succeed(Utils.Tuple0));
                });
            }
        };
    }
    
    return localRuntime.Native.WebAPI.AnimationFrame.values;
};
