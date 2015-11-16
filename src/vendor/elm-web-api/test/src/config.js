var sauceUserName = process.env.GEB_SAUCE_LABS_USER;
var sauceAccessKey = process.env.GEB_SAUCE_LABS_ACCESS_PASSWORD;

module.exports = {
    // Configuration options    
    quiet: false,           // Silences the console output 

    webdriver: {            // Options for Selenium WebDriver (WebdriverIO) 
        user: sauceUserName,
        key: sauceAccessKey
    },

    httpServer: {           // Options for local http server (npmjs.org/package/http-server) 
        disable: false,
        port: 8080              // Non-standard option; it is passed into the httpServer.listen() method 
    },

    sauceLabs: {            // Options for SauceLabs API wrapper (npmjs.org/package/saucelabs)
        username: sauceUserName,
        password: sauceAccessKey
    },

    sauceConnect: {         // Options for SauceLabs Connect (npmjs.org/package/sauce-connect-launcher)
        disable: false,
        username: sauceUserName,
        accessKey: sauceAccessKey
    },
    
    selenium: {             // Options for Selenium Server (npmjs.org/package/selenium-standalone). Only used if you need Selenium running locally.
        args: []                // options to pass to `java -jar selenium-server-standalone-X.XX.X.jar`
    }
};

