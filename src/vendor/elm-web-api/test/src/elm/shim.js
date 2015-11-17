var LocalStorage = require('node-localstorage').LocalStorage;

var window = {
    localStorage: new LocalStorage('./localStorage.store'),
    sessionStorage: new LocalStorage('./sessionStorage.store'),

    setTimeout: setTimeout
}

var app = Elm.worker(Elm.Main);

app.ports.result.subscribe(function (s) {
    console.log(s);
});
