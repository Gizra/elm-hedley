Elm.Native.TestUtil = {};
Elm.Native.TestUtil.make = function (localRuntime) {
    localRuntime.Native = localRuntime.Native || {};
    localRuntime.Native.TestUtil = localRuntime.Native.TestUtil || {};

    if (!localRuntime.Native.TestUtil.values) {
        var Task = Elm.Native.Task.make(localRuntime);
        var Signal = Elm.Native.Signal.make(localRuntime);

        var sample = function (signal) {
            // Use closure to track value
            var val = signal.value;

            var handler = function (value) {
                val = value;
            };

            // We construct a new "output" node, because otherwise the incoming
            // signal may be pruned by trimDeadNodes() in Runtime.js
            // (if trimDeadNodes() sees that it is not otherwise used).
            var output = Signal.output("sample-" + signal.name, handler, signal);

            return Task.asyncFunction(function (callback) {
                // Need to return the value inside setTimeout, because
                // otherwise we can be called out-of-order ... that is, a
                // previous `Task.andThen` which updated a Signal may not have
                // actually completed yet unless we do this inside a timeout.
                localRuntime.setTimeout(function () {
                    callback(Task.succeed(val));
                }, 0);
            });
        };

        localRuntime.Native.TestUtil.values = {
            sample: sample
        };
    }

    return localRuntime.Native.TestUtil.values;
};
