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
          w_userno: '51'
          w_useroom: 100
          w_k1: 'k_51'
          w_userrev: 0
          w_pool: 0
      ).addExtension('user-actions').addExtension('extended-events')

      checker1 = new XatUser(
        todo:
          w_userno: '52'
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

    checkSigninReceived = (signin, user) ->
      should.exist signin
      signin.should.have.property 'u'
      u = signin.u
      u.attributes.should.have.property 'u'
      u.attributes.u.should.be.equal user.todo.w_userno

    checkSignoutReceived = (signout, user) ->
      should.exist signout
      signout.should.have.property 'l'
      l = signout.l
      l.attributes.should.have.property 'u'
      l.attributes.u.should.be.equal user.todo.w_userno

    checkMessageReceived = (received, message, sender) ->
      should.exist received
      received.should.have.property 'm'
      m = received.m
      m.attributes.should.contain.keys ['u', 't']
      m.attributes.u.split('_')[0].should.be.equal sender.todo.w_userno
      m.attributes.t.should.be.equal message
      


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
        checker1.once 'ee-user', (data) ->
          signin = data.xml

      it 'checker from pool 0 should receive <l>', ->
        checkSignoutReceived logout, tweaker
      it 'checker from pool 1 should receive <u>', ->
        checkSigninReceived signin, tweaker


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
        checkMessageReceived receivedBy1, message, tweaker
    describe 'tweaker backs to pool 0', ->
      message = 'message to pool 0' + new Date().getTime()
      checkerMessage = 'message to tweaker from pool 0' + new Date().getTime()
      message0 = null
      message1 = null
      messaget = null
      logout = null
      signin = null

      before (done) ->
        tweaker.setPool 0
        checker0.once 'ee-user', (data) ->
          signin = data.xml
        checker1.once 'ee-user-signout', (data) ->
          logout = data.xml

        test.delay 100, ->
          tweaker.sendTextMessage message
          checker0.sendTextMessage checkerMessage
          checker0.once 'ee-text-message', (data) ->
            message0 = data.xml
          checker1.once 'ee-text-message', (data) ->
            message1 = data.xml
          tweaker.once 'ee-text-message', (data) ->
            messaget = data.xml

          test.delay 100, -> done()
      it 'checker from pool 0 should receive <u>', ->
        checkSigninReceived signin, tweaker
      it 'checker from pool 0 should receive <m>', ->
        checkMessageReceived message0, message, tweaker
      it 'checker from pool 1 should receive <l>', ->
        checkSignoutReceived logout, tweaker
      it 'checker from pool 1 shouldn\'t receive <m>', ->
        should.not.exist message1
      it 'tweaker should be able to receive messages from pool 0 checker', ->
        checkMessageReceived messaget, checkerMessage, checker0

    describe 'checker 0 signout - signin.', ->
      signin = null
      logout = null
      before (done) ->
        checker0.end()
        tweaker.once 'ee-user-signout', (data) ->
          logout = data.xml

        test.delay 10, ->
          checker0.connect()
          tweaker.once 'ee-user', (data) ->
            signin = data.xml
          checker0.once 'ee-done', -> done()
      it 'tweaker should receive <l>', ->
        checkSignoutReceived logout, checker0
      it 'tweaker should receive <u>', ->
        checkSigninReceived signin, checker0
