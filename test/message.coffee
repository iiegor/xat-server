test = require './lib/test-kit'
XatUser = test.IXatUser
deploy = test.deployServer

should = require('chai').should()

describe 'message', ->
  server = null

  before (beforeDone) ->
    deploy().then (_server) ->
      server = _server
      beforeDone()
    return

  after ->
    server.kill()

  describe 'basic', ->
    u1 = null
    u2 = null
    messages =
      u1: []
      u2: []
      all: []
    before (beforeDone) ->
      u1 = new XatUser(
        todo:
          w_userno: 51
          w_useroom: 100
          w_k1: 'k_51'
          w_userrev: 0
      )

      u2 = new XatUser(
        todo:
          w_useroom: 100
          w_userno: 50
          w_k1: 'k_50'
          w_userrev: 0
      ).addExtension('user-actions')

      u1.connect()
      u1.on 'data', (data) ->
        messages.u1.push data
        if data.done?
          u2.connect()
          u2.on 'data', (data) ->
            messages.u2.push data
            if data.done?
              beforeDone()

    describe 'user 1', ->
      it 'should receive message sent by user 2', (done) ->
        u2.sendTextMessage('test!')
        test.delay 10, ->
          gotdone = false
          messageReceived = false
          for message in messages.u1
            gotdone = true if message.done?
            if gotdone and message.m?
              messageReceived = true
              m = message.m
              m.attributes.t.should.be.equal('test!')
              m.attributes.u.should.be.oneOf([u2.todo.w_userno + '_' + u2.todo.w_userrev, String(u2.todo.w_userno)])

          messageReceived.should.be.true
          done()

  describe 'evil', ->
    u1 = null
    u2 = null
    message = 'evil uid case ' + new Date().getTime()
    received = null

    before (done) ->
      u1 = new XatUser(
        todo:
          w_userno: '50'
          w_useroom: 100
          w_userrev: 0
          w_k1: 'k_50'
      ).addExtension('extended-events')
      u2 = new XatUser(
        todo:
          w_userno: '51'
          w_useroom: 100
          w_userrev: 0
          w_k1: 'k_51'
      ).addExtension('extended-events')
      u1.connect()
      u1.once 'ee-done', ->
        u2.connect()
        u2.once 'ee-done', ->
          u1.send "<m t=\"#{message}\" u=\"52\">"
          u2.once 'ee-text-message', (data) ->
            received = data.xml
          test.delay 100, -> done()
    after ->
      u1.end()
      u2.end()

    it 'shouldn\'t receive <m> with illegal "u"', ->
      should.not.exist received
