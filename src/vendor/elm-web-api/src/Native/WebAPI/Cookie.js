Elm.Native = Elm.Native || {};
Elm.Native.WebAPI = Elm.Native.WebAPI || {};
Elm.Native.WebAPI.Cookie = Elm.Native.WebAPI.Cookie || {};

Elm.Native.WebAPI.Cookie.make = function (localRuntime) {
    localRuntime.Native = localRuntime.Native || {};
    localRuntime.Native.WebAPI = localRuntime.Native.WebAPI || {};
    localRuntime.Native.WebAPI.Cookie = localRuntime.Native.WebAPI.Cookie || {};

    if (!localRuntime.Native.WebAPI.Cookie.values) {
        var Task = Elm.Native.Task.make(localRuntime);
        var Utils = Elm.Native.Utils.make(localRuntime);

        localRuntime.Native.WebAPI.Cookie.values = {
            getString: Task.asyncFunction(function (callback) {
                callback(Task.succeed(document.cookie));
            }),

            setString: function (cookie) {
                return Task.asyncFunction(function (callback) {
                    document.cookie = cookie;
                    callback(Task.succeed(Utils.Tuple0));
                });
            },

            dateToUTCString: function (date) {
                return date.toUTCString();
            },

            uriEncode: function (string) {
                return encodeURIComponent(string);
            },

            uriDecode: function (string) {
                return decodeURIComponent(string);
            }
        };
    }

    return localRuntime.Native.WebAPI.Cookie.values;
};
