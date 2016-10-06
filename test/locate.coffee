should = require('chai').should()
assert = require('chai').assert

test = require '../src/test/test-kit'
XatUser = test.IXatUser
deploy = test.deployServer

conf = require '../config/default'


describe 'locating interactions', ->

  locator = null
  responder = null
  server = null

  before () ->
    deploy().then (_server) ->
      server = _server
      locator = new XatUser(
        todo:
          w_userno: '50'
          w_k1: 'k_50'
          w_name: 'n1'
          w_avatar: '123'
          w_homepage: 'http://example.com'
          w_useroom: '100'
      ).addExtension('user-actions').addExtension('extended-events')

      responder = new XatUser(
        todo:
          w_userno: '51'
          w_useroom: '100'
          w_k1: 'k_51'
          w_name: 'tester'
          w_avatar: '555'
          w_userrev: 0
      ).addExtension('user-actions').addExtension('extended-events')



  after ->
    server.kill()


  describe 'user sends locate to receiver in same chat', ->

    messages =
      all: []
      locator: []
      responder: []

    before (beforeDone) ->
      locator.connect()

      locator.on 'data', (data) ->
        messages.locator.push data
        messages.all.push data
      locator.on 'ee-done', (data) ->
        responder.connect()

        responder.on 'ee-done', (data) ->
          beforeDone()

      responder.on 'data', (data) ->
        messages.responder.push data
        messages.all.push data

    after ->
      locator.end()
      responder.end()

    describe 'receiver responds as not to friend', ->
      locate = null
      at = null

      before (done) ->
        locator.sendLocate responder.todo.w_userno
        responder.once 'ee-locate-user', (data) ->
          locate = data
          responder.sendResponseToLocate locator.todo.w_userno
          locator.once 'ee-at-user', (data) ->
            at = data
            done()

      describe 'receiver', ->
        it 'should receive locate request from sender', ->
          locate.xml.should.have.property 'z'

          z = locate.xml.z
          z.attributes.should.contain.keys(['u', 'd', 't'])
          z.attributes.u.split('_')[0].should.be.equal locator.todo.w_userno
          z.attributes.d.should.be.equal responder.todo.w_userno
      describe 'sender', ->
        it 'should receive response to locate', () ->
          at.xml.should.have.property 'z'
          z = at.xml.z
          z.attributes.should.contain.keys(['u', 'd', 't'])
          z.attributes.u.split('_')[0].should.be.equal responder.todo.w_userno
          z.attributes.d.should.be.equal locator.todo.w_userno
          assert.equal z.attributes.t.substr(0, 3), '/a_'
