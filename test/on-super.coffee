test = require '../src/test/test-kit'
XatUser = test.IXatUser
deploy = test.deployServer
assert = require('chai').assert
should = require('chai').should()


# This tests intend to test server's behavior
# when user sit in more than one chat.
# The most important task for server is to determine
# destination of 'z'-packets.
#
# FIXME:
#   Sometimes some of this tests fails. Strange...
describe 'on-super', ->
  server = null

  before () ->
    deploy().then (_server) ->
      server = _server

  after ->
    server.kill()

  describe 'when sender and receiver in different chats', ->
    sender = null
    receiver2 = null
    receiver3 = null

    messages =
      sender: []
      receiver2: []
      receiver3: []

    before (beforeDone) ->
      sender = new XatUser(
        todo:
          w_userno: 50
          w_k1: 'k_50'
          w_userrev: 0
          w_useroom: 100
      ).addExtension('user-actions')

      receiver2 = new XatUser(
        todo:
          w_userno: 51
          w_k1: 'k_51'
          w_userrev: 0
          w_useroom: 101
      ).addExtension('user-actions').addExtension('on-super').addExtension('extended-events')

      receiver3 = new XatUser(
        todo:
          w_userno: 51
          w_k1: 'k_51'
          w_userrev: 0
          w_useroom: 102
      ).addExtension('user-actions').addExtension('on-super').addExtension('extended-events')

      sender.connect()
      sender.on 'data', (data) ->
        messages.sender.push data

        if data.done?
          receiver2.connect()

          receiver2.on 'data', (data) ->
            messages.receiver2.push data

            if data.done?
              receiver3.connect()

              receiver3.on 'data', (data) ->
                messages.receiver3.push data

                if data.done?
                  beforeDone()

    after ->
      sender.end()
      receiver2.end()
      receiver3.end()

    describe 'receiver', ->
      it "should receive 'k'-packet in first chat", =>
        messages.receiver2.should.contains.an.item.with.property('k')
      it "should receive 'k'-packet with appropriate content", =>
        [y] = (_.y for _ in messages.receiver2 when _.y?)

        assert.isDefined y
        k =
          k:
            attributes:
              d: receiver2.todo.w_userno
              i: y.attributes.i


        [..., actual] = (_ for _ in messages.receiver2 when _.k?)

        assert.equal actual, k, 'packets are not equal. Actual is ' + JSON.stringify(actual) + ' while ' + JSON.stringify(k) + ' expected'

      it 'should receive private message in the last visited chat', (done) ->
        ts = new Date().getTime()

        text = ts.toString()
        sender.sendPMMessage(text, receiver2.todo.w_userno)

        test.delay 20, ->
          [..., msg] = (_ for _ in messages.receiver2 when _.z?)
          assert.isFalse(msg? and msg.z.attributes.t == text)

          [..., msg] = (_ for _ in messages.receiver3 when _.z?)
          assert.isOk(msg? and msg.z.attributes.t == text)
          done()

      it 'should receive the message in first chat after sending k2 from it', (done) ->
        receiver2.sendK2()

        ts = new Date().getTime()
        text = ts.toString()

        receiver3.once 'ee-not-on-super', () ->
          sender.sendPMMessage(text, receiver2.todo.w_userno)

          test.delay 50, ->
            [..., msg] = (_ for _ in messages.receiver2 when _.z?)
            assert.isOk(msg? and msg.z.attributes.t == text)

            [..., msg] = (_ for _ in messages.receiver3 when _.z?)
            assert.isFalse(msg? and msg.z.attributes.t == text)
            done()

      it 'should receive message in second chat after sending k2 from it', (done) ->
        receiver3.sendK2()

        ts = new Date().getTime()

        text = ts.toString()
        #delay is required. but why?
        receiver2.once 'ee-not-on-super', () ->
          sender.sendPMMessage(text, receiver2.todo.w_userno)

          test.delay 50, ->
            [..., msg] = (_ for _ in messages.receiver2 when _.z?)
            assert.isFalse(msg? and msg.z.attributes.t == text)

            [..., msg] = (_ for _ in messages.receiver3 when _.z?)
            assert.isOk(msg? and msg.z.attributes.t == text)
            done()

  describe 'when sender and receiver in same chat', ->
    sender = null
    receiver1 = null
    receiver2 = null

    messages =
      sender: []
      receiver1: []
      receiver2: []

    before (beforeDone) ->
      sender = new XatUser(
        todo:
          w_userno: 50
          w_k1: 'k_50'
          w_userrev: 0
          w_useroom: 100
      ).addExtension('user-actions')

      receiver1 = new XatUser(
        todo:
          w_userno: 51
          w_k1: 'k_51'
          w_userrev: 0
          w_useroom: 100
      ).addExtension('user-actions').addExtension('on-super')

      receiver2 = new XatUser(
        todo:
          w_userno: 51
          w_k1: 'k_51'
          w_userrev: 0
          w_useroom: 101
      ).addExtension('user-actions').addExtension('on-super')

      sender.connect()
      sender.on 'data', (data) ->
        messages.sender.push data

        if data.done?
          receiver1.connect()

          receiver1.on 'data', (data) ->
            messages.receiver1.push data

            if data.done?
              receiver2.connect()

              receiver2.on 'data', (data) ->
                messages.receiver2.push data

                if data.done?
                  beforeDone()


    describe 'receiver', ->
      it 'should receive message in sender\'s chat, no matter is it on super or not', (done) ->
        text = new Date().getTime().toString()

        sender.sendPMMessage(text, receiver1.todo.w_userno)
        test.delay 20, ->
          [..., z] = (_.z for _ in messages.receiver1 when _.z?)
          assert.isOk(z? and z.attributes.t == text)

          [..., z] = (_.z for _ in messages.receiver2 when _.z?)
          assert.isFalse(z? and z.attributes.t == text)
          done()

      it 'even if K2 has been sent exactly', (done) ->
        text = new Date().getTime().toString()
        receiver2.sendK2()

        test.delay 50, ->
          sender.sendPMMessage(text, receiver1.todo.w_userno)

          test.delay 50, ->
            [..., z] = (_.z for _ in messages.receiver1 when _.z?)
            assert.isOk(z? and z.attributes.t == text)

            [..., z] = (_.z for _ in messages.receiver2 when _.z?)
            assert.isFalse(z? and z.attributes.t == text)

            done()
