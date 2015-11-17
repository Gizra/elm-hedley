Elm.Native = Elm.Native || {};
Elm.Native.WebAPI = Elm.Native.WebAPI || {};
Elm.Native.WebAPI.Storage = Elm.Native.WebAPI.Storage || {};

Elm.Native.WebAPI.Storage.make = function (localRuntime) {
    localRuntime.Native = localRuntime.Native || {};
    localRuntime.Native.WebAPI = localRuntime.Native.WebAPI || {};
    localRuntime.Native.WebAPI.Storage = localRuntime.Native.WebAPI.Storage || {};

    if (!localRuntime.Native.WebAPI.Storage.values) {
        var Task = Elm.Native.Task.make(localRuntime);
        var Maybe = Elm.Maybe.make(localRuntime);
        var NS = Elm.Native.Signal.make(localRuntime);
        var Utils = Elm.Native.Utils.make(localRuntime);
   
        var toMaybe = function (obj) {
            return obj == null ? Maybe.Nothing : Maybe.Just(obj); 
        };

        var length = function (storage) {
            return Task.asyncFunction(function (callback) {
                callback(Task.succeed(storage.length));
            });
        };

        var key = function (storage, k) {
            return Task.asyncFunction(function (callback) {
                var result = null;

                // This check needed to avoid a problem in IE9
                if (k >= 0 && k < storage.length) {
                    result = storage.key(k);
                }

                callback(
                    Task.succeed(
                        toMaybe(result)
                    )
                );
            });
        };

        var getItem = function (storage, k) {
            return Task.asyncFunction(function (callback) {
                var result = storage.getItem(k);
                callback(
                    Task.succeed(
                        toMaybe(result)
                    )
                );
            });
        };

        var setItem = function (storage, k, v) {
            return Task.asyncFunction(function (callback) {
                try {
                    storage.setItem(k, v);
                    callback(Task.succeed(Utils.Tuple0));
                } catch (ex) {
                    callback(Task.fail(ex.message));
                }
            });
        };

        var removeItem = function (storage, k) {
            return Task.asyncFunction(function (callback) {
                storage.removeItem(k);
                callback(Task.succeed(Utils.Tuple0));
            });
        };

        var clear = function (storage) {
            return Task.asyncFunction(function (callback) {
                storage.clear();
                callback(Task.succeed(Utils.Tuple0));
            });
        };

        var events = NS.input('WebAPI.Storage.nativeEvents', Maybe.Nothing);

        localRuntime.addListener([events.id], window, "storage", function (event) {
            var e = {
                key: toMaybe(event.key),
                oldValue: toMaybe(event.oldValue),
                newValue: toMaybe(event.newValue),
                url : event.url,
                storageArea: event.storageArea
            };
            
            localRuntime.notify(events.id, toMaybe(e));
        });

        localRuntime.Native.WebAPI.Storage.values = {
            localStorage: window.localStorage,
            sessionStorage: window.sessionStorage,

            length: length,
            key: F2(key),
            getItem: F2(getItem),
            setItem: F3(setItem),
            removeItem: F2(removeItem),
            clear: clear,

            nativeEvents: events
        };
    }
    
    return localRuntime.Native.WebAPI.Storage.values;
};
