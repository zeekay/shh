Connection = require 'ssh2'
events     = require 'events'
os         = require 'os'

stripColors = (str) ->
  str.replace /\033\[[0-9;]*m/g, ''

class Client extends events.EventEmitter
  constructor: (options = {}) ->
    options.host       ?= 'localhost'
    options.port       ?= 22
    options.username   ?= process.env['USER']
    options.privateKey ?= require('fs').readFileSync process.env['HOME'] + '/.ssh/id_rsa'
    options.publicKey  ?= require('fs').readFileSync process.env['HOME'] + '/.ssh/id_rsa.pub'
    options.colors     ?= false
    options.debug      ?= false

    @bufferLength  = options.bufferLength ? 5000
    @endToken      = options.endToken ? '__SHH_END_TOKEN__'
    @startToken    = options.startToken ? '__SHH_START_TOKEN__'

    @options       = options

    @_ssh          = new Connection()

    @_stderr       = []
    @_stdout       =      []
    @_callbacks    = []
    @_lastFragment = null
    @_streaming    = false

  connect: (callback = ->) ->
    @_ssh.on 'connect', =>
      if @options.debug
        console.log '[ssh :: connect]'
    @_ssh.on 'ready', =>
      if @options.debug
        console.log '[ssh :: ready]'

      @_ssh.shell {}, (err, stream) =>
        throw err if err

        stream.on 'end', ->
          if @options.debug
            console.log '[stream :: end]'

        stream.on 'close', ->
          if @options.debug
            console.log '[stream :: close]'

        stream.on 'exit', (code, signal) ->
          if @options.debug
            console.log '[stream :: exit]', code, signal

        stream.on 'data', (data = '', extended) =>
          unless @options.colors
            data = stripColors data.toString()

          if @options.debug
            console.log '[stream :: data]', data

          @parse data, extended

        callback null, @_stream = stream

    @_ssh.on 'error', (err) ->
      throw err if err

    @_ssh.connect @options

  # try to untruncate first line
  prependLastFragment: (lines) ->
    firstLine = lines.shift()
    lines.unshift @_lastFragment + firstLine
    @_lastFragment = null
    lines

  parse: (data, type='stdout') ->
    # split on newline, unless passed an Array
    if typeof data == 'string'
      lines = data.split os.EOL
    else
      lines = data

    if type == 'stderr'
      return @stream lines, 'stderr' if @_streaming

    if @_lastFragment
      lines = @prependLastFragment lines

    if not @_streaming
      # we need to find a start token first
      start = lines.indexOf @startToken
      start = lines.indexOf @startToken + '\r' if start == -1

      if start != -1
        # found a start token
        @start()
        # parse the remainder
        @parse lines.slice start + 1
      else
        # we ignore everything until we find a start token,
        # preserve last line in case it's truncated
        @_lastFragment = lines.pop()
    else
      # stream data until we find an end token
      end = lines.indexOf @endToken
      end = lines.indexOf @endToken + '\r' if end == -1

      if end != -1
        # we've found an end token
        @stream  lines.slice 0, end
        @end()
        # continue to parse remainder
        @parse lines.slice end + 1
      else
        # stream everything except last line which may be truncated
        @_lastFragment = lines.pop()
        @stream lines

    return

  # stream emits line by line, and saves it to a buffer
  # for output when the command completes. The buffer is limited to @bufferLength
  stream: (lines, type='stdout') ->
    buffer = @['_' + type]

    for line in lines
      if not @colors
        line = stripColors line
        buffer.push line
        buffer.shift() if buffer.length == @bufferLength
        @emit type, line
    return

  start: ->
    # flush output of lastFragment command
    @emit 'startcommand'
    @_streaming = true

  end: ->
    # flush output of lastFragment command
    stderr = @_stderr.join os.EOL
    stdout = @_stdout.join os.EOL
    @emit 'endcommand', stderr, stdout

    # clear buffers
    @_stderr = []
    @_stdout = []

    # end streaming
    @_streaming = false

    # call any callbacks
    callback = @_callbacks.shift()
    if typeof callback == 'function'
      if not stderr.trim()
        stderr = null
      callback stderr, stdout

  close: ->
    @_ssh.end()

  exec: (cmd, callback) ->
    @_callbacks.push callback
    @_stream.write "echo; echo #{@startToken}; #{cmd}; echo #{@endToken}\r\n"

module.exports = wrapper = (options) ->
  new Client options

wrapper.Client = Client
