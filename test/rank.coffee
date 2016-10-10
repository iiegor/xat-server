should = require('chai').should()

test = require './lib/test-kit'
XatUser = test.IXatUser
deploy = test.deployServer

describe 'ranks', ->
  server = null

  before (done) ->
    deploy().then (_server) ->
      server = _server
      done()

  after -> server.kill()

  describe 'main owner', ->
    owner = null

    chatMeta = null

    before (done) ->
      owner = new XatUser(
        todo:
          w_userno: '50'
          w_useroom: 100
          w_k1: 'k_50'
          pass: 100 + 20000
      ).addExtension('extended-events')
      owner.connect()
      #owner.on 'data', (data) -> console.log(data)
      owner.once 'ee-chat-meta', (data) ->
        chatMeta = data.xml
      owner.once 'ee-done', -> done()

    it 'should auth successfully', ->
      should.exist chatMeta
      chatMeta.should.have.property 'i'
      i = chatMeta.i
      i.attributes.should.have.property 'r'
      i.attributes.r.should.be.equal '1'
  describe 'illegal main owner', ->
    owner = null

    chatMeta = null

    before (done) ->
      owner = new XatUser(
        todo:
          w_userno: '50'
          w_useroom: 100
          w_k1: 'k_50'
          pass: 101 + 20000
      ).addExtension('extended-events')
      owner.connect()
      #owner.on 'data', (data) -> console.log(data)
      owner.once 'ee-chat-meta', (data) ->
        chatMeta = data.xml
      owner.once 'ee-done', -> done()
    it 'shouldn\'t auth successfully', ->
      should.exist chatMeta
      chatMeta.should.have.property 'i'
      i = chatMeta.i
      if i.attributes.r?
        i.attributes.r.should.not.be.equal '1'
