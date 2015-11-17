var SeSauce = require('./selenium-sauce');
var git = require('git-rev');

var remote = require('./remote');
var config = require('./config');
var eachBrowser = require('./mocha/browser');

git.short(function (rev) {
    // If SauceLabs environment variables are present, set up SauceLabs browsers
    if (config.webdriver.user) {
        config.webdriver.desiredCapabilities = remote(rev);
    } else {
        config.webdriver.desiredCapabilities = [{
            browserName: 'firefox'
        }];
    };

    new SeSauce(config, eachBrowser);

    // Need to call mocha with a --delay, since git.short is async
    run();
});

