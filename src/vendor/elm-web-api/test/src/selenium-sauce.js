var webdriverio = require('webdriverio'),
    httpserver = require('http-server'),
    selenium = require('selenium-standalone'),
    sauceConnectLauncher = require('sauce-connect-launcher'),
    extend = require('extend'),
    colors = require('colors'),
    SauceLabs = require('saucelabs');

/**
 * Initializes Selenium Sauce using the specified options.
 * 'doEachBrowser' is called once for each browser in options.webdriver.desiredCapabilities, passing in the webdriverio instance.
 */
var SeSauce = function(options, doEachBrowser) {

    extend(this, {
        browsers: [],         // Contains a list of webdriverio instances
        _browserActions: [],

        _initialized: false,
        _stopped: false,

        options: {
            quiet: false,           // Silences the console output
            webdriver: {            // Options for selenium webdriver (webdriverio)
                host: 'ondemand.saucelabs.com',
                port: 80,
                user: null,
                key: null,
                logLevel: 'silent',
                desiredCapabilities: [] // Non-standard option; An array of desired capabilities instead of a single object
            },
            httpServer: {           // Options for local http server (npmjs.org/package/http-server)
                disable: false,         // Non-standard option; used to skip launching the http server
                port: 8080              // Non-standard option; it is passed into the httpServer.listen() method
            },
            sauceLabs: {            // Options for SauceLabs API wrapper (npmjs.org/package/saucelabs)
                username: null,
                password: null
            },
            sauceConnect: {         // Options for SauceLabs Connect (npmjs.org/package/sauce-connect-launcher)
                disable: false,         // Non-standard option; used to disable sauce connect
                username: null,
                accessKey: null
            },
            selenium: {             // Options for Selenium Server (npmjs.org/package/selenium-standalone). Only used if you need Selenium running locally.
                args: []                // options to pass to `java -jar selenium-server-standalone-X.XX.X.jar`
            }
        }
    });


    this._doEachBrowser = doEachBrowser;
    this.options.quiet = options.quiet;

    extend(this.options.webdriver, options.webdriver || {});
    extend(this.options.httpServer, options.httpServer || {});
    extend(this.options.sauceLabs, options.sauceLabs || {});
    extend(this.options.sauceConnect, options.sauceConnect || {});
    extend(this.options.selenium, options.selenium || {});

    if (this.options.webdriver.desiredCapabilities && this.options.webdriver.desiredCapabilities.constructor === Object)
        this.options.webdriver.desiredCapabilities = [this.options.webdriver.desiredCapabilities];

    if (!(this.options.webdriver.user && this.options.webdriver.key) && this.options.webdriver.host == 'ondemand.saucelabs.com') {
        this.options.webdriver.host = 'localhost';
        this.options.webdriver.port = 4444;
    }

    var self = this;

    for (var i = 0, len = this.options.webdriver.desiredCapabilities.length; i < len; i++) {
        var wdOptions = extend({}, this.options.webdriver);
        wdOptions.desiredCapabilities = this.options.webdriver.desiredCapabilities[i];
        var browser = webdriverio.remote(wdOptions);
        this.browsers.push(browser);

        browser._oldInit = browser.init;
        browser.init = function (complete) {
            self._initOnce(function (err) {
                if (err)
                    return complete(err);
                this._oldInit(complete);
            }.bind(this));
        }.bind(browser);

        browser._oldEnd = browser.end;
        browser.end = function (complete) {
            this._oldEnd(function () {
                self.browsers.splice(self.browsers.indexOf(this), 1);
                if (self.browsers.length == 0)
                    self._stop(complete);
                else
                    complete();
            }.bind(this));
        }.bind(browser);

        browser.passed = function(success, complete) {
            this.updateJob({ passed: success }, function() {
                this.end(complete);
            }.bind(this));
        }.bind(browser);

        browser.updateJob = function(data, complete) {
            if (self.sauceLabs)
                self.sauceLabs.updateJob(this.requestHandler.sessionID, data, complete);
            else
                complete();
        }.bind(browser);

        doEachBrowser.call(this, browser);
    }

};

extend(SeSauce.prototype, {

    /**
     * Performs one-time initialization. Calls 'complete' when done, passing in an error message if necessary.
     * @private
     */
    _initOnce: function (complete) {
        if (this._initialized)
            return complete();

        var self = this;
        this._initialized = true;

        this.webdriver = webdriverio;

        if (!this.options.httpServer.disable) {
            this._log("Launching local web server (http://localhost:" + this.options.httpServer.port + "/)...");
            this.httpServer = httpserver.createServer(this.options.httpServer);
            this.httpServer.listen(this.options.httpServer.port);
            this._log("Web server ready.");
        }

        if (this.options.sauceLabs.username && this.options.sauceLabs.password) {
            this._log("Initializing SauceLabs API.");
            this.sauceLabs = new SauceLabs({
                username: this.options.sauceLabs.username,
                password: this.options.sauceLabs.password
            });
        }

        if (this.options.sauceConnect.username && this.options.sauceConnect.accessKey) {
            if (this.options.sauceConnect.disable)
                this._log("Sauce Connect disabled.");
            else {
                this._log("Launching Sauce Connect...");
                delete this.options.sauceConnect.disable;
                sauceConnectLauncher(this.options.sauceConnect, function (errmsg, process) {
                    if (errmsg) {
                        if (process) process.close();
                        return self._doError('Error launching Sauce Connect:\n' + errmsg, complete);
                    }
                    self.sauceConnect = process;
                    self._log("Sauce Connect ready.");
                    complete();
                });
            }
        }
        else {
            this._log("No SauceLabs username/accessKey. Launching Selenium locally...");

            selenium.install({}, function (err) {
                if (err) {
                    self._doError(err, complete);
                } else {
                    selenium.start({
                        seleniumArgs: self.options.selenium.args
                    }, function (err, child) {
                        if (err) {
                            self._doError(err, complete);
                        } else {
                            self.selenium = child;
                            complete();
                        }
                    });
                }
            });
        }
    },

    /**
     * Logs an error message, stops all services, and then calls the 'complete' callback, passing in the error message.
     * @private
     */
    _doError: function (msg, complete) {
        this._err(msg);
        this._stop(function () {
            complete(msg);
        });
    },


    /**
     * @private
     */
    _stop: function (complete) {
        if (this._stopped)
            return complete && complete();

        this._stopped = true;

        if (this.httpServer) {
            this.httpServer.close();
            this._log("Web server stopped.");
        }

        if (this.selenium) {
            this.selenium.kill();
            this._log("Local Selenium server stopped.");
        }

        if (this.sauceConnect) {
            var self = this;
            this._log("Closing Sauce Connect...");
            this.sauceConnect.close(function () {
                self._log("Sauce Connect closed.");
                if (complete)
                    complete();
            });
        }
        else if (complete)
            complete();
    },

    _log: function(str) {
        if(!this.options.quiet)
            console.log('SelSauce: '.blue + str);
    },

    _err: function(str) {
        console.error('SelSauce: '.bgRed + str);
    }
});

module.exports = SeSauce;
