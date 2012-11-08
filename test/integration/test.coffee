shh    = require '../src'
should = require('chai').should()

describe 'Client', ->
  client = null
  beforeEach ->
    client = new shh.Client
      host: 'localhost'

  describe '#cmd', ->
    it 'should successfully call the callback with stdout', (done) ->
      client.cmd 'ls', (err, out) ->
        throw new Error err if err
        out.should.be.a 'string'
        out.should.have.length.above 1
        client.close()
        done()

    it 'should successfully call the callback with stdout, even with multiple nested calls', (done) ->
      client.cmd 'ls', (err, out) ->
        throw new Error err if err

        client.cmd 'ls', (err, out) ->
          throw new Error err if err

          client.cmd 'ls', (err, out) ->
            throw new Error err if err
            out.should.be.a 'string'
            out.should.have.length.above 1
            client.close()
            done()

  describe '#emit', ->
    it 'should emit stdout', (done) ->
      client.on 'stdout', (out) ->
        out.should.be.a 'string'
        out.should.have.length.above 1

      client.cmd 'ls', (err, out) ->
        throw new Error err if err
        client.close()
        done()
