var windowTest = require('./windowTest');
var elmTest = require('./elmTest');
var locationTest = require('./locationTest');
var storageTest = require('./storageTest');

module.exports = function (browser) {
    var title =
        browser.desiredCapabilities.browserName + "-" +
        browser.desiredCapabilities.version + "-" +
        browser.desiredCapabilities.platform + " "
        browser.desiredCapabilities.build;
    
    describe(title, function () {
        this.timeout(600000);
        this.slow(4000);

        var allPassed = true;

        // Before any tests run, initialize the browser.
        before(function (done) {
            browser.init(function (err) {
                if (err) throw err;
                done();
            });
        });

        elmTest(browser);
        windowTest(browser);
        locationTest(browser);
        storageTest(browser);

        afterEach(function() {
            allPassed = allPassed && (this.currentTest.state === 'passed');
        });

        after(function (done) {
            console.log(title + (allPassed ? " PASSED" : " FAILED"));
            browser.passed(allPassed, done);
        });
    });
};
