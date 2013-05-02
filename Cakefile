exec = require 'executive'

option '-g', '--grep [filter]', 'test filter'

task 'clean', 'clean lib/', ->
  exec 'rm -rf lib/'

task 'build', 'compile src/*.coffee to lib/*.js', ->
  exec './node_modules/.bin/coffee -bc -m -o lib/ src/'

task 'watch', 'watch for changes and recompile project', ->
  exec './node_modules/.bin/coffee -bc -m -w -o lib/ src/'

task 'test', 'run tests', (options) ->
  tests = options.tests ? 'test/integration'
  if options.grep?
    grep = "--grep #{options.grep}"
  else
    grep = ''

  exec "NODE_ENV=test node_modules/.bin/mocha
        --colors
        --compilers coffee:coffee-script
        --recursive
        --reporter spec
        --require test/_helper.js
        --timeout 15000
        #{grep}
        #{tests}"

task 'test:unit', 'run tests', (options) ->
  options.tests = 'test/unit/'
  invoke 'test'

task 'test:integration', 'run integration tests', (options) ->
  options.tests = 'test/integration/'
  invoke 'test'

task 'publish', 'Publish current version to npm', ->
  exec [
    'cake build'
    'git push'
    'npm publish'
  ]
