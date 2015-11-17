var expect = require('chai').expect;
var Q = require('q');

module.exports = function (browser) {
    describe("The Location example", function () {
        beforeEach(function (done) {
            browser.url('http://localhost:8080/location.html', done);
        });

        var falsy = function () {
            return Q.when(false); 
        };

        it("should reload from server", function () {
            return browser
                .setValue("#input", "This goes away on reload")
                .click("#reload-force-button")

                // Wait for it not to have a value again
                .waitUntil(function () {
                    return this.getValue("#input").then(function (value) {
                        return value === "";
                    }, falsy);
                }, 6000, 250);
        });
        
        it("should reload from cache", function () {
            return browser
                .setValue("#input", "This goes away on reload")
                .click("#reload-cache-button")

                // Wait for it not to have a value again
                .waitUntil(function () {
                    return this.getValue("#input").then(function (value) {
                        return value === "";
                    }, falsy);
                }, 6000, 250);
        });
    });
};
