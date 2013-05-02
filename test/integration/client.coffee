shh    = require '../../lib'
should = require('chai').should()

describe 'Client [integration]', ->
  client = null
  beforeEach ->
    client = new shh.Client
      host: 'localhost'

  describe '#exec', ->
    it 'should successfully call the callback with stdout', (done) ->
      client.connect ->
        client.exec 'ls', (err, out) ->
          throw new Error err if err
          out.should.be.a 'string'
          out.should.have.length.above 1
          client.close()
          done()

    it 'should successfully call the callback with stdout, even with multiple nested calls', (done) ->
      client.connect ->
        client.exec 'ls', (err, out) ->
          throw new Error err if err

          client.exec 'ls', (err, out) ->
            throw new Error err if err

            client.exec 'ls', (err, out) ->
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

      client.connect ->
        client.exec 'ls', (err, out) ->
          throw new Error err if err
          client.close()
          done()
