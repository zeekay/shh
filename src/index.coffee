child_process = require 'child_process'
events        = require 'events'
os            = require 'os'

COMMAND_START = '__SSH_COMMAND_START__'
COMMAND_END   = '__SSH_COMMAND_END__'

stripColors = (str) ->
  str.replace /\033\[[0-9;]*m/g, ''

class SSHClient extends events.EventEmitter
  stdout       = ''
  stderr       = ''
  lastFragment = null
  callbacks    = []
  streaming    = false

  constructor: (options = {}) ->
    @stripColors = options.stripColors ? true

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
      @emit 'exit'

    # resume stdin so we can begin receiving data
    @ssh.stdin.resume()

  # try to untruncate first line
  prependLastFragment: (lines) ->
    firstLine = lines.shift()
    lines.unshift lastFragment + firstLine
    lastFragment = null
    lines

  parse: (data, type='stdout') ->
    return if not data?.split
    if type == 'stderr'
      return @stream data, 'stderr' if streaming

    lines = data.split os.EOL

    if lastFragment
      lines = @prependLastFragment lines

    if not streaming
      # we need to find a start token first
      startToken = lines.indexOf COMMAND_START
      if startToken != -1
        # found a start token
        @start()
        # parse the remainder
        @parse lines.slice(startToken + 1).join os.EOL
      else
        # we ignore everything until we find a start token
        lastFragment = lines.pop()
        return
    else
      # stream data until we find an end token
      endToken = lines.indexOf COMMAND_END
      if endToken != -1
        # we've found an end token
        @stream (lines.slice 0, endToken).join os.EOL
        @end()
        # continue to parse remainder
        @parse lines.slice endToken + 1
      else
        lastFragment = lines.pop()
        @stream lines.join os.EOL

  stream: (out, type='stdout') ->
    if @stripColors
      out = stripColors out

    if type == 'stdout'
      stdout += out
      @emit 'stdout', out
    else
      stderr += out
      @emit 'stderr', out

  start: ->
    # flush output of lastFragment command
    @emit 'startcommand'
    streaming = true

  end: ->
    # flush output of lastFragment command
    @emit 'endcommand', stderr, stdout

    # call any callbacks
    callback = callbacks.shift()
    if typeof callback == 'function'
      callback stderr, stdout

    # clear buffers
    stderr = stdout = ''

    # end streaming
    streaming = false

  close: ->
    @ssh.kill 'SIGHUP'

  cmd: (cmd, callback) ->
    @ssh.stdin.write "echo; echo #{COMMAND_START}; #{cmd}; echo #{COMMAND_END}\r\n"
    callbacks.push callback

module.exports = (options) ->
  new SSHClient options
