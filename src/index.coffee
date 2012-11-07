{EventEmitter} = require 'events'
{spawn}        = require 'child_process'

class SSHClient extends EventEmitter
  COMMAND_START = '__SSH_COMMAND_START__'
  COMMAND_END = '__SSH_COMMAND_END__'

  buffer = ''
  callbacks = []
  other = false

  trim = ->
    lines = buffer.split '\n'
    start = lines.indexOf COMMAND_START
    end = lines.indexOf COMMAND_END
    output = lines.slice start+1, end
    output.join '\n'

  processBuffer = ->
    if buffer.indexOf(COMMAND_END + '\n') == -1
      return

    if other
      callback = callbacks.shift()
      if typeof callback == 'function'
        callback trim buffer
      buffer = ''
    else
      other = not other

  constructor: (options = {}) ->
    args = [
      '-o', 'PasswordAuthentication=no'
      '-o', 'StrictHostKeyChecking=no'
      '-o', 'UserKnownHostsFile=/dev/null'
    ]

    if options.port
      args.push '-p'
      args.push options.port

    if options.identity
      args.push '-i'
      args.push options.identity

    args.push '-tt'

    if options.user
      args.push "#{options.user}@#{options.host}"
    else
      args.push "#{options.host}"

    @ssh = spawn 'ssh', args

    @ssh.stdout.on 'data', (data) =>
      buffer += data.toString()
      processBuffer()

    @ssh.stderr.on 'data', (data) =>
      buffer += data.toString()
      processBuffer()

    @ssh.on 'exit', (code, signal) =>
      @emit 'exit'

  close: ->
    @ssh.kill 'SIGHUP'

  exec: (cmd, callback) ->
    @ssh.stdin.write "echo; echo #{COMMAND_START}; #{cmd}; echo #{COMMAND_END}\r\n"
    callbacks.push callback

module.exports = (options) ->
  new SSHClient options
