exec = require 'executive'

option '-g', '--grep [filter]', 'test filter'
option '-v', '--version [<newversion> | major | minor | patch | build]', 'new version'

task 'clean', 'clean lib/', ->
  exec 'rm -rf lib/'
  exec 'rm -rf .test'

task 'build', 'compile src/*.coffee to lib/*.js', ->
  exec 'node_modules/.bin/coffee -bcm -o lib/ src/'
  exec 'node_modules/.bin/coffee -bcm -o .test/ test/'

task 'watch', 'watch for changes and recompile project', ->
  exec 'node_modules/.bin/coffee -bcmw -o lib/ src/'
  exec 'node_modules/.bin/coffee -bcmw -o .test test/'

task 'test', 'run tests', (options) ->
  tests = options.tests ? 'test/unit test/integration'
  if options.grep?
    grep = "--grep #{options.grep}"
  else
    grep = ''

  exec "NODE_ENV=test node_modules/.bin/mocha
      --colors
      --reporter spec
      --timeout 5000
      --compilers coffee:coffee-script/register
      --require postmortem/register
        #{grep}
        #{tests}"

task 'test:unit', 'run tests', (options) ->
  options.tests = 'test/unit/'
  invoke 'test'

task 'test:integration', 'run integration tests', (options) ->
  options.tests = 'test/integration/'
  invoke 'test'

task 'publish', 'publish project', (options) ->
  newVersion = options.version ? 'patch'

  exec """
  git push
  npm version #{newVersion}
  npm publish
  """.split '\n'
