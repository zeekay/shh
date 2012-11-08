should = require('chai').should()

describe 'SSHClient', ->
  describe '#cmd', ->
    it 'should recieve stdout', (done) ->
      shh = require('../../src')
        host: 'localhost'
      shh.cmd 'ls', (err, out) ->
        throw new Error err if err
        out.should.be.a 'string'
        out.should.have.length.above 1
        shh.close()
        done()
