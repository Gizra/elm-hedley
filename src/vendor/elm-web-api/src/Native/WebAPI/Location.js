Elm.Native = Elm.Native || {};
Elm.Native.WebAPI = Elm.Native.WebAPI || {};
Elm.Native.WebAPI.Location = Elm.Native.WebAPI.Location || {};

Elm.Native.WebAPI.Location.make = function (localRuntime) {
    localRuntime.Native = localRuntime.Native || {};
    localRuntime.Native.WebAPI = localRuntime.Native.WebAPI || {};
    localRuntime.Native.WebAPI.Location = localRuntime.Native.WebAPI.Location || {};

    if (!localRuntime.Native.WebAPI.Location.values) {
        var Task = Elm.Native.Task.make(localRuntime);
        var Utils = Elm.Native.Utils.make(localRuntime);

        // In core before 3.0.0
        var copy = Utils.copy;

        if (!copy) {
            // In core from 3.0.0
            copy = function (value) {
                return Utils.update(value, {});
            };
        }

        localRuntime.Native.WebAPI.Location.values = {
            location: Task.asyncFunction(function (callback) {
                var location = copy(window.location);

                // Deal with Elm reserved word
                location["port$"] = location.port;

                // Polyfill for IE
                if (!location.origin) {
                    location.origin = 
                        location.protocol + "//" +
                        location.hostname + 
                        (location.port ? ':' + location.port: '');
                }

                callback(Task.succeed(location));
            }),

            reload: function (forceServer) {
                return Task.asyncFunction(function (callback) {
                    window.location.reload(forceServer);

                    // Now, I suppose this won't really accomplish anything,
                    // but let's do it anyway.
                    try {
                        callback(
                            Task.succeed(Utils.Tuple0)
                        );
                    } catch (ex) {
                        callback(
                            Task.fail(ex.message)
                        );
                    }
                });
            }
        };
    }

    return localRuntime.Native.WebAPI.Location.values;
};
