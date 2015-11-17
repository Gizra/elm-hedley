Elm.Native = Elm.Native || {};
Elm.Native.WebAPI = Elm.Native.WebAPI || {};
Elm.Native.WebAPI.Document = Elm.Native.WebAPI.Document || {};

Elm.Native.WebAPI.Document.make = function (localRuntime) {
    localRuntime.Native = localRuntime.Native || {};
    localRuntime.Native.WebAPI = localRuntime.Native.WebAPI || {};
    localRuntime.Native.WebAPI.Document = localRuntime.Native.WebAPI.Document || {};

    if (!localRuntime.Native.WebAPI.Document.values) {
        var Task = Elm.Native.Task.make(localRuntime);
        var NS = Elm.Native.Signal.make(localRuntime);
        var Utils = Elm.Native.Utils.make(localRuntime);

        var getState = function () {
            switch (document.readyState) {
                case "loading":
                    return {ctor: "Loading"};

                case "interactive":
                    return {ctor: "Interactive"};

                case "complete":
                    return {ctor: "Complete"};

                default:
                    throw "Got unrecognized document.readyState: " + document.readyState;
            }
        };

        var readyState = NS.input('WebAPI.Document.readyState', getState());

        localRuntime.addListener([readyState.id], document, 'readystatechange', function () {
            localRuntime.notify(readyState.id, getState());
        });

        localRuntime.Native.WebAPI.Document.values = {
            readyState: readyState,

            getReadyState: Task.asyncFunction(function (callback) {
                callback(Task.succeed(getState()));
            }),

            getTitle : Task.asyncFunction(function (callback) {
                callback(Task.succeed(document.title));
            }),

            setTitle : function (title) {
                return Task.asyncFunction(function (cb) {
                    document.title = title;
                    cb(Task.succeed(Utils.Tuple0));
                });
            }
        };
    }

    return localRuntime.Native.WebAPI.Document.values;
};
