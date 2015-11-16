Elm.Native = Elm.Native || {};
Elm.Native.WebAPI = Elm.Native.WebAPI || {};
Elm.Native.WebAPI.Window = Elm.Native.WebAPI.Window || {};

Elm.Native.WebAPI.Window.make = function (localRuntime) {
    localRuntime.Native = localRuntime.Native || {};
    localRuntime.Native.WebAPI = localRuntime.Native.WebAPI || {};
    localRuntime.Native.WebAPI.Window = localRuntime.Native.WebAPI.Window || {};

    if (!localRuntime.Native.WebAPI.Window.values) {
        var Task = Elm.Native.Task.make(localRuntime);
        var Utils = Elm.Native.Utils.make(localRuntime);
    
        var elmAlert = function (message) {
            return Task.asyncFunction(function (callback) {
                window.alert(message);
                callback(Task.succeed(Utils.Tuple0));
            });
        };
    
        var elmConfirm = function (message) {
            return Task.asyncFunction(function (callback) {
                var result = window.confirm(message);
                callback(
                    result
                        ? Task.succeed(Utils.Tuple0)
                        : Task.fail(Utils.Tuple0)
                );
            });
        };

        var elmPrompt = function (message, defaultResponse) {
            return Task.asyncFunction(function (callback) {
                var result = window.prompt(message, defaultResponse);
                callback(
                    // Safari returns "" when you press cancel, so
                    // we need to check for that.
                    result == null || result == ""
                        ? Task.fail(Utils.Tuple0)
                        : Task.succeed(result)
                );
            });
        };

        localRuntime.Native.WebAPI.Window.values = {
            alert: elmAlert,
            confirm: elmConfirm,
            prompt: F2(elmPrompt)
        };
    }
    
    return localRuntime.Native.WebAPI.Window.values;
};
