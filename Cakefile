{exec} = require 'child_process'

run = (cmd, callback) ->
  exec cmd, (err, stderr, stdout) ->
    if stderr
      console.error stderr
    if stdout
      console.log stdout

    if typeof callback == 'function'
      callback err, stderr, stdout

task 'build', 'Build project', ->
  run './node_modules/.bin/coffee -bc -o lib/ src/'

task 'test', 'run tests', ->
  run "NODE_ENV=test
    ./node_modules/.bin/mocha
    --compilers coffee:coffee-script
    --reporter spec
    --colors
    test"

task 'publish', 'Publish current version to NPM', ->
  run './node_modules/.bin/coffee -bc -o lib/ src/', ->
    run 'git push', ->
      run 'npm publish'

