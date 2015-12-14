elm-make src/*.elm
elm-make test/*.elm --output test/raw-test.js
bash test/elm-io.sh test/raw-test.js test/test.js
node test/test.js
