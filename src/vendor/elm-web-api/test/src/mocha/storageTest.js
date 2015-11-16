var expect = require('chai').expect;
var Q = require('q');

module.exports = function (browser) {
    var run;

    if (
        browser.desiredCapabilities.browserName == 'chrome' ||
        browser.desiredCapabilities.browserName == 'internet explorer' ||
        browser.desiredCapabilities.browserName == 'opera'
    ) {
        // Can't get the tab switching to work in these
        run = describe.skip;
    } else {
        run = describe;
    }

    run("The Storage example", function () {
        var url = 'http://localhost:8080/storage.html';
        
        before(function () {
            return browser
                .newWindow(url, "tab1")
                .waitForExist("#select-area", 6000)
                .selectByIndex("#select-area", 0)
                .selectByIndex("#select-operation", 5)
                .click("#perform-action")
                .newWindow(url, "tab2")
                .waitForExist("#select-area", 6000)
                .selectByIndex("#select-area", 0)
                .selectByIndex("#select-operation", 5)
                .click("#perform-action");
        });

        after(function () {
            return browser
                .switchTab("tab1")
                .close()
                .switchTab("tab2")
                .close();
        });

        it("first set should trigger add event", function () {
            var expectedText = "LogEvent { area = Local, change = Add \"testKey\" \"testValue\", url = \"" + url + "\" }";

            return browser
                .switchTab("tab1")
                .waitForExist("#select-area", 6000)
                .selectByIndex("#select-area", 0)
                .selectByIndex("#select-operation", 3)
                .waitForExist("#select-set-key", 6000)
                .setValue("#select-set-key", "testKey")
                .setValue("#select-set-value", "testValue")
                .click("#perform-action")
                .switchTab("tab2")
                .waitUntil(function () {
                    return this.getText("#log").then(function (text) {
                        return text.indexOf(expectedText) >= 0;
                    });
                }, 8000, 250);
        });
        
        it("second set should trigger modify event", function () {
            var expectedText = "LogEvent { area = Local, change = Modify \"testKey\" \"testValue\" \"testValue2\", url = \"" + url + "\" }";

            return browser
                .switchTab("tab1")
                .setValue("#select-set-key", "testKey")
                .setValue("#select-set-value", "testValue2")
                .click("#perform-action")
                .switchTab("tab2")
                .waitUntil(function () {
                    return this.getText("#log").then(function (text) {
                        return text.indexOf(expectedText) >= 0;
                    });
                }, 8000, 250);
        });
        
        it("remove should trigger remove event", function () {
            var expectedText = "LogEvent { area = Local, change = Remove \"testKey\" \"testValue2\", url = \"" + url + "\" }";

            return browser
                .switchTab("tab1")
                .selectByIndex("#select-operation", 4)
                .waitForExist("#select-remove-key", 6000)
                .setValue("#select-remove-key", "testKey")
                .click("#perform-action")
                .switchTab("tab2")
                .waitUntil(function () {
                    return this.getText("#log").then(function (text) {
                        return text.indexOf(expectedText) >= 0;
                    });
                }, 8000, 250);
        });
        
        it("clear should trigger clear event", function () {
            var expectedText = "LogEvent { area = Local, change = Clear, url = \"" + url + "\" }";

            return browser
                .switchTab("tab1")
                .selectByIndex("#select-operation", 3)
                .waitForExist("#select-set-key", 6000)
                .setValue("#select-set-key", "testKey")
                .setValue("#select-set-value", "testValue")
                .click("#perform-action")
                .selectByIndex("#select-operation", 5)
                .click("#perform-action")
                .switchTab("tab2")
                .waitUntil(function () {
                    return this.getText("#log").then(function (text) {
                        return text.indexOf(expectedText) >= 0;
                    });
                }, 8000, 250);
        }); 
    });
};
