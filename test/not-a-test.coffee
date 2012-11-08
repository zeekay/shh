shh = require '../'

shh = new shhClient
  host: 'voltaire'

shh.on 'stdout', (out) ->
  console.log out

shh.on 'stderr', (err) ->
  console.log err

shh.on 'startcommand', ->
  console.log 'found start token'

shh.on 'endcommand', (stderr, stdout) ->
  console.log 'found end token'

shh.cmd 'ls', (err, out) ->
  console.log out
  console.log 'calling second command'
  shh.cmd 'ls -al', (err, out) ->
    console.log out
    console.log 'closing shh'
    shh.close()
