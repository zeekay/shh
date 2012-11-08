child_process = require('child_process')
os            = require('os')
shh           = require('../../src')
should        = require('chai').should()
sinon         = require('sinon')

client = null

describe 'Client [unit]', ->
  describe '#parse', ->
    before ->
      sinon.stub child_process, 'spawn', ->
        spawn =
          stdout:
            on: ->
            setEncoding: ->
          stderr:
            on: ->
            setEncoding: ->
          stdin:
            resume: ->
          on: ->
      client = shh
        host: 'localhost'

    it 'should parse simple string', (done) ->
      testValue = 'string of shit'
      data = shh.START_TOKEN + os.EOL + testValue + os.EOL + shh.END_TOKEN

      client.on 'stdout', (out) ->
        out.should.contain testValue
        done()

      client.parse data

    it 'should parse something else', (done) ->
      done()
