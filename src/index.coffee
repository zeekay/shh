Connection     = require 'ssh2'
{EventEmitter} = require 'events'
fs             = require 'fs'
os             = require 'os'

BUFFER_LENGTH = 5000
END_TOKEN     = '__SHH_END_TOKEN__'
START_TOKEN   = '__SHH_START_TOKEN__'
USERNAME      = process.env['USER']
PRIVATE_KEY   = process.env['SHH_PRIVATE_KEY'] ? process.env['HOME'] + '/.ssh/id_rsa'

stripColors = (str) ->
  str.replace /\x33\[[0-9;]*m/g, ''

class Client extends EventEmitter
  constructor: (options = {}) ->
    options.host       ?= 'localhost'
    options.port       ?= 22
    options.username   ?= USERNAME
    options.privateKey ?= PRIVATE_KEY

    @options       = options

    @bufferLength  = options.bufferLength ? 5000
    @colors        = options.colors ? false
    @debug         = options.debug ? false
    @endToken      = options.endToken ? '__SHH_END_TOKEN__'
    @startToken    = options.startToken ? '__SHH_START_TOKEN__'

    @_connection   = new Connection()
    @_stderr       = []
    @_stdout       = []
    @_callbacks    = []
    @_lastFragment = null
    @_streaming    = false

  connect: (callback = ->) ->
    @_connection.on 'connect', =>
      if @debug
        console.log '[ssh :: connect]'

    @_connection.on 'ready', =>
      if @debug
        console.log '[ssh :: ready]'

      @_connection.shell (err, @_stream) =>
        throw err if err?

        @_stream.on 'end', ->
          if @debug
            console.log '[stream :: end]'

        @_stream.on 'close', ->
          if @debug
            console.log '[stream :: close]'

        @_stream.on 'exit', (code, signal) ->
          if @debug
            console.log '[stream :: exit]', code, signal

        @_stream.on 'data', (data = '', extended) =>
          unless @colors
            data = stripColors data.toString()

          if @debug
            console.log '[stream :: data]', data

          @parse data, extended

        callback null, @_stream

    @_connection.on 'error', (err) ->
      throw err if err?

    @_connection.on 'close', (hadError) ->
      if hadError
        throw new Error('Connection closed unexpectedly')

    # read private key and connect
    fs.exists @options.privateKey, (exists) =>
      throw new Error('Private key not found') if not exists

      fs.readFile @options.privateKey, (err, data) =>
        throw err if err?

        @options.privateKey = data
        @_connection.connect @options

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
        @stream lines.slice 0, end
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
    @_connection.end()

  exec: (cmd, callback) ->
    @_callbacks.push callback
    @_stream.write "echo; echo #{@startToken}; #{cmd}; echo #{@endToken}\r\n"

module.exports = wrapper = (options) ->
  new Client options

wrapper.Client        = Client
wrapper.USERNAME      = USERNAME
wrapper.PRIVATE_KEY   = PRIVATE_KEY
wrapper.BUFFER_LENGTH = BUFFER_LENGTH
wrapper.END_TOKEN     = END_TOKEN
wrapper.START_TOKEN   = START_TOKEN
