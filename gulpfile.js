// Generated on 2015-05-04 using generator-jekyllized 0.7.3
"use strict";

var gulp = require("gulp");
// Loads the plugins without having to list all of them, but you need
// to call them as $.pluginname
var $ = require("gulp-load-plugins")();
// "del" is used to clean out directories and such
var del = require("del");
// BrowserSync isn"t a gulp package, and needs to be loaded manually
var browserSync = require("browser-sync");

var elm  = require('gulp-elm');

var fs = require('fs');

// merge is used to merge the output from two different streams into the same stream
var merge = require("merge-stream");
// Need a command for reloading webpages using BrowserSync

var plumber = require("gulp-plumber");

var reload = browserSync.reload;
// And define a variable that BrowserSync uses in its function
var bs;

// Deletes the directory that is used to serve the site during development
gulp.task("clean:dev", function() {
  return del(["serve/**/*"]);
});


// Deletes the directory that the optimized site is output to
gulp.task("clean:prod", function() {
  return del(["dist/**/*"]);
});


// Compiles the SASS files and moves them into the "assets/stylesheets" directory
gulp.task("styles", function () {
  // Looks at the style.scss file for what to include and creates a style.css file
  return gulp.src("src/assets/scss/style.scss")
    .pipe(plumber())
    .pipe($.sass())
    .on('error', function(err){
      browserSync.notify("SASS error");

      console.error(err.message);

      // Save the error to index.html, with a simple HTML wrapper
      // so browserSync can inject itself in.
      fs.writeFileSync('serve/index.html', "<!DOCTYPE HTML><html><body><pre>" + err.message + "</pre></body></html>");

      // No need to continue processing.
      this.emit('end');
    })
    // AutoPrefix your CSS so it works between browsers
    .pipe($.autoprefixer("last 1 version", { cascade: true }))
    // Directory your CSS file goes to
    .pipe(gulp.dest("serve/assets/stylesheets/"))
    // Outputs the size of the CSS file
    .pipe($.size({title: "styles"}))
    // Injects the CSS changes to your browser since Jekyll doesn"t rebuild the CSS
    .pipe(reload({stream: true}));
});

// Optimizes the images that exists
gulp.task("images", function () {
  return gulp.src("src/assets/images/**")
    .pipe($.changed("dist/assets/images"))
    .pipe($.imagemin({
      // Lossless conversion to progressive JPGs
      progressive: true,
      // Interlace GIFs for progressive rendering
      interlaced: true
    }))
    .pipe(gulp.dest("dist/assets/images"))
    .pipe($.size({title: "images"}));
});

// Copy over fonts to the "dist" directory
gulp.task("fonts", function () {
  return gulp.src("src/assets/fonts/**")
    .pipe(gulp.dest("dist/assets/fonts"))
    .pipe($.size({ title: "fonts" }));
});

// Copy index.html and CNAME files to the "serve" directory
gulp.task("copy:dev", function () {
  return gulp.src(["src/index.html", "src/CNAME"])
    .pipe(gulp.dest("serve"))
    .pipe($.size({ title: "index.html & CNAME" }))
});

gulp.task("cname", function () {
  return gulp.src(["serve/CNAME"])
    .pipe(gulp.dest("dist"))
    .pipe($.size({ title: "CNAME" }))
});


// Optimizes all the CSS, HTML and concats the JS etc
gulp.task("minify", ["styles"], function () {
  var assets = $.useref.assets({searchPath: "serve"});

  return gulp.src("serve/**/*.*")
    // Concatenate JavaScript files and preserve important comments
    .pipe($.if("*.js", $.uglify({preserveComments: "some"})))
    // Minify CSS
    .pipe($.if("*.css", $.minifyCss()))
    // Start cache busting the files
    .pipe($.revAll({ ignore: ["index.html", ".eot", ".svg", ".ttf", ".woff"] }))
    .pipe(assets.restore())
    // Replace the asset names with their cache busted names
    .pipe($.revReplace())
    // Minify HTML
    .pipe($.if("*.html", $.htmlmin({
      removeComments: true,
      removeCommentsFromCDATA: true,
      removeCDATASectionsFromCDATA: true,
      collapseWhitespace: true,
      collapseBooleanAttributes: true,
      removeAttributeQuotes: true,
      removeRedundantAttributes: true
    })))
    // Send the output to the correct folder
    .pipe(gulp.dest("dist"))
    .pipe($.size({title: "optimizations"}));
});


// Task to upload your site to your GH Pages repo
gulp.task("deploy", [], function () {
  // Deploys your optimized site, you can change the settings in the html task if you want to
  return gulp.src("dist/**/*")
    .pipe($.ghPages({branch: "gh-pages"}));
});

gulp.task('elm-init', elm.init);
gulp.task('elm', ['elm-init'], function(){
  return gulp.src('src/elm/Main.elm')
    .pipe(plumber())
    .pipe(elm())
    .on('error', function(err) {
        console.error(err.message);

        browserSync.notify("Elm compile error", 5000);

        // Save the error to index.html, with a simple HTML wrapper
        // so browserSync can inject itself in.
        fs.writeFileSync('serve/index.html', "<!DOCTYPE HTML><html><body><pre>" + err.message + "</pre></body></html>");
    })
    .pipe(gulp.dest('serve'));
});

// BrowserSync will serve our site on a local server for us and other devices to use
// It will also autoreload across all devices as well as keep the viewport synchronized
// between them.
gulp.task("serve:dev", ["styles", "elm", "copy:dev"], function () {
  bs = browserSync({
    notify: true,
    // tunnel: "",
    server: {
      baseDir: "serve"
    }
  });
});


// These tasks will look for files that change while serving and will auto-regenerate or
// reload the website accordingly. Update or add other files you need to be watched.
gulp.task("watch", function () {
  // We need to copy dev, so index.html may be replaced by error messages.
  gulp.watch(["src/elm/*.elm"], ["elm", "copy:dev", reload]);
  gulp.watch(["src/assets/scss/**/*.scss"], ["styles", "copy:dev", reload]);
});

// Serve the site after optimizations to see that everything looks fine
gulp.task("serve:prod", function () {
  bs = browserSync({
    notify: false,
    // tunnel: true,
    server: {
      baseDir: "dist"
    }
  });
});

// Default task, run when just writing "gulp" in the terminal
gulp.task("default", ["clean:dev", "serve:dev", "watch"]);

// Builds the site but doesnt serve it to you
gulp.task("build", ["clean:dev", "copy:dev", "elm", "styles"], function () {});

// Builds your site with the "build" command and then runs all the optimizations on
// it and outputs it to "./dist"
gulp.task("publish", ["clean:prod", "build"], function () {
  gulp.start("minify", "cname", "images", "fonts");
});
