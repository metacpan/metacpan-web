let storage;

// provide localStorage shim to work around https://bugzilla.mozilla.org/show_bug.cgi?id=748620
try {
    storage = window.localStorage;
}
catch {
    // noop
}
if (!storage) {
    storage = new class {
        getItem(k) {
            return this["_" + k];
        }
        setItem(k, v) {
            return this["_" + k] = v;
        }
    };
}

module.exports = storage;
