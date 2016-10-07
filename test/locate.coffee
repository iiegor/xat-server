should = require('chai').should()
assert = require('chai').assert

test = require '../src/test/test-kit'
XatUser = test.IXatUser
deploy = test.deployServer

conf = require '../config/default'
Chat = require '../src/workers/chat'


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

  checkResponse = (resp, locator, responder) ->
    resp.xml.should.have.property 'z'
    z = resp.xml.z
    z.attributes.should.contain.keys(['u', 'd', 't', 'n', 'a', 'h', 'v'])
    z.attributes.u.split('_')[0].should.be.equal responder.todo.w_userno
    z.attributes.d.should.be.equal locator.todo.w_userno
    z.attributes.n.should.be.equal responder.todo.w_name
    z.attributes.a.should.be.equal responder.todo.w_avatar
    z.attributes.h.should.be.equal String(responder.todo.w_homepage)

  describe 'user sends locate to receiver in same chat', ->

    before (beforeDone) ->
      locator.connect()

      locator.once 'ee-done', (data) ->
        responder.connect()

        responder.once 'ee-done', (data) ->
          beforeDone()


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
          checkResponse(at, locator, responder)
          z = at.xml.z
          assert.equal z.attributes.t.substr(0, 3), '/a_'

    describe 'receiver responds as to friend', ->
      at = null

      before (done) ->
        locator.sendLocate responder.todo.w_userno
        responder.once 'ee-locate-user', (data) ->
          responder.sendResponseToLocate locator.todo.w_userno, true
          locator.once 'ee-at-user', (data) ->
            at = data
            done()

      describe 'sender', ->
        it 'should receive response to locate', ->
          checkResponse(at, locator, responder)
          z = at.xml.z
          z.attributes.t.should.be.equal '/axat.dev/chat/room/' + responder.todo.w_useroom + '/'

    describe 'receiver responds as nofollow', ->
      at = null

      before (done) ->
        locator.sendLocate responder.todo.w_userno
        responder.once 'ee-locate-user', (data) ->
          responder.sendResponseToLocate locator.todo.w_userno, false, true
          locator.once 'ee-at-user', (data) ->
            at = data
            done()

      describe 'sender', ->
        it 'should receive NF', ->
          checkResponse(at, locator, responder)
          z = at.xml.z
          z.attributes.t.should.be.equal '/a_NF'

  describe 'locator and responder are in different chats', ->
    locator = null
    responder = null
    before (done) ->
      responder.todo.w_useroom = '101'
      locator.connect()
      locator.once 'ee-done', ->
        responder.connect()
        responder.once 'ee-done', ->
          done()

    after ->
      locator.end()
      responder.end()

    describe 'receiver responds as nofollow', ->
      at = null

      before (done) ->
        locator.sendLocate responder.todo.w_userno
        responder.once 'ee-locate-user', ->
          responder.sendResponseToLocate locator.todo.w_userno, false, true
          locator.once 'ee-at-user', (data) ->
            at = data
            done()

      describe 'sender', ->
        it 'should receive NF', ->
          checkResponse(at, locator, responder)
          z = at.xml.z
          z.attributes.t.should.be.equal '/a_NF'
