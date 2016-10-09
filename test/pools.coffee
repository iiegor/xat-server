should = require('chai').should()
assert = require('chai').assert

test = require './lib/test-kit'
XatUser = test.IXatUser
deploy = test.deployServer

describe 'pools', ->
  server = null

  before ->
    deploy().then (_server) ->
      server = _server

  after ->
    server.kill()

  describe 'attempt to connect to pool 1', ->
    user = null
    message = 'pool 0 message ' + new Date().getTime()
    messages = []

    before (done) ->
      user = new XatUser(
        todo:
          w_userno: '53'
          w_k1: 'k_53'
          w_useroom: 100
          w_userrev: 0
          w_pool: 0
      ).addExtension('extended-events').addExtension('user-actions')
      user.connect()
      user.once 'ee-done', ->
        user.sendTextMessage message
        done()

    it 'shouldn\'t receive message sent in zero pool', (done) ->
      user.end()
      user.todo.w_pool = 1
      user.connect()
      user.on 'ee-main-chat-message', (data) ->
        messages.push data.xml.m?.attributes.t
      user.once 'ee-done', ->
        messages.should.not.include message
        done()

    after ->
      user.removeAllListeners 'ee-main-chat-message'

  describe 'tweaker', ->
    tweaker = null
    checker0 = null
    checker1 = null

    before (beforeDone) ->
      tweaker = new XatUser(
        todo:
          w_userno: '50'
          w_k1: 'k_50'
          w_useroom: 100
          w_userrev: 0
          w_pool: 0
      ).addExtension('user-actions').addExtension('extended-events')

      checker0 = new XatUser(
        todo:
          w_userno: 51
          w_useroom: 100
          w_k1: 'k_51'
          w_userrev: 0
          w_pool: 0
      ).addExtension('user-actions').addExtension('extended-events')

      checker1 = new XatUser(
        todo:
          w_userno: 52
          w_useroom: 100
          w_k1: 'k_52'
          w_userrev: 0
          w_pool: 1
      ).addExtension('user-actions').addExtension('extended-events')
      checker0.connect()
      checker0.once 'ee-done', (data) ->
        checker1.connect()
        checker1.once 'ee-done', ->
          tweaker.connect()

          tweaker.once 'ee-done', (data) ->
            beforeDone()



    after ->
      tweaker.end()
      checker0.end()
      checker1.end()


    describe 'tweaker goes to pool 1', ->
      logout = null
      signin = null

      before (beforeDone) ->
        tweaker.setPool 1
        tweaker.once 'ee-done', ->
          test.delay 100, ->
            beforeDone()
        checker0.once 'ee-user-signout', (data) ->
          logout = data.xml
        checker1.once 'ee-user-signin', (data) ->
          signin = data.xml

      it 'checker from pool 0 should receive <l>', ->
        should.exist logout
        logout.should.have.property 'l'
        l = logout.l
        l.attributes.should.have.property 'u'
        l.attributes.u.should.be.equal tweaker.todo.w_userno
      it 'checker from pool 1 should receive <u>', ->
        should.exist signin
        signin.should.have.property 'u'
        u = signin.u
        u.attributes.should.have.property 'u'
        u.attributes.u.should.be.equal tweaker.todo.w_userno


    describe 'tweaker sends message to pool 1', ->
      message = 'message to pool 1' + new Date().getTime()
      receivedBy0 = null
      receivedBy1 = null

      before (done) ->
        tweaker.sendTextMessage message

        checker0.once 'ee-text-message', (data) ->
          receivedBy0 = data.xml

        checker1.once 'ee-text-message', (data) ->
          receivedBy1 = data.xml

        test.delay 100, ->
          done()

      it 'checker from pool 0 shouldn\'t receive <m>', ->
        should.not.exist receivedBy0
      it 'checker from pool 1 should receive <m>', ->
        should.exist receivedBy1
        receivedBy1.should.have.property 'm'
        m = receivedBy1.m
        m.attributes.should.contain.keys ['u', 't']
        m.attributes.u.split('_')[0].should.be.equal tweaker.todo.w_userno
        m.attributes.t.should.be.equal message
