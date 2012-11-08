child_process = require 'child_process'
events        = require 'events'
os            = require 'os'

COMMAND_START = '__SSH_COMMAND_START__'
COMMAND_END   = '__SSH_COMMAND_END__'
BUFFER_LENGTH = 5000

stripColors = (str) ->
  str.replace /\033\[[0-9;]*m/g, ''

class SSHClient extends events.EventEmitter
  _stdout:       []
  _stderr:       []
  _lastFragment: null
  _callbacks:    []
  _streaming:    false

  constructor: (options = {}) ->
    @bufferLength = options.bufferLength ? BUFFER_LENGTH

    @colors = options.colors ? false

    # construct arguments for ssh
    args = [
      '-t', '-t'
      '-o', 'PasswordAuthentication=no'
      '-o', 'StrictHostKeyChecking=no'
      '-o', 'UserKnownHostsFile=/dev/null'
      '-o', 'ControlMaster=no'
    ]

    if options.port
      args.push '-p'
      args.push options.port

    if options.identity
      args.push '-i'
      args.push options.identity

    if options.user
      args.push "#{options.user}@#{options.host}"
    else
      args.push "#{options.host}"

    # span ssh process
    @ssh = child_process.spawn 'ssh', args

    # set encoding
    @ssh.stderr.setEncoding 'utf8'
    @ssh.stdout.setEncoding 'utf8'

    # handle data
    @ssh.stderr.on 'data', (data) =>
      @parse data, 'stderr'

    @ssh.stdout.on 'data', (data) =>
      @parse data

    # handle exit
    @ssh.on 'exit', (code, signal) =>
      @emit 'exit', code, signal

      while @_callbacks.length
        callback = @_callbacks.shift()
        if typeof callback == 'function'
          callback new Error 'SSH exited'

    # resume stdin so we can begin receiving data
    @ssh.stdin.resume()

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

    return if not data?.split
    if type == 'stderr'
      return @stream lines, 'stderr' if @_streaming

    if @_lastFragment
      lines = @prependLastFragment lines

    if not @_streaming
      # we need to find a start token first
      start = lines.indexOf COMMAND_START
      start = lines.indexOf COMMAND_START + '\r' if start == -1

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
      end = lines.indexOf COMMAND_END
      end = lines.indexOf COMMAND_END + '\r' if end == -1

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
    @ssh.kill 'SIGHUP'

  cmd: (cmd, callback) ->
    @_callbacks.push callback
    @ssh.stdin.write "echo; echo #{COMMAND_START}; #{cmd}; echo #{COMMAND_END}\r\n"

module.exports = wrapper = (options) ->
  new SSHClient options

wrapper.SSHClient     = SSHClient
wrapper.COMMAND_START = COMMAND_START
wrapper.COMMAND_END   = COMMAND_END
