test = require './test-kit'
XatUser = test.IXatUser
deploy = test.deployServer
assert = require('chai').assert

describe 'on-super', =>
  server = null
  sender = null
  receiver2 = null
  receiver3 = null

  messages =
    sender: []
    receiver2: []
    receiver3: []

  before (beforeDone) =>
    deploy().then (_server) =>
      server = _server

      sender = new XatUser(
        todo:
          w_userno: 50
          w_k1: 555
          w_userrev: 0
          w_useroom: 1
      ).addExtension('user-actions')

      receiver2 = new XatUser(
        todo:
          w_userno: 51
          w_k1: 1112
          w_userrev: 0
          w_useroom: 2
      ).addExtension('user-actions').addExtension('on-super')

      receiver3 = new XatUser(
        todo:
          w_userno: 51
          w_k1: 1112
          w_userrev: 0
          w_useroom: 3
      ).addExtension('user-actions').addExtension('on-super')
      
      sender.connect()
      sender.on 'data', (data) =>
        messages.sender.push data

        if data.done?
          receiver2.connect()

          receiver2.on 'data', (data) =>
            messages.receiver2.push data

            if data.done?
              receiver3.connect()

              receiver3.on 'data', (data) =>
                messages.receiver3.push data

                if data.done?
                  beforeDone()


  after =>
    server.kill()

  describe 'receiver', =>
    it 'should receive the message in the last visited chat', (done) =>
      ts = new Date().getTime()

      text = ts.toString()
      sender.sendPMMessage(text, receiver2.todo.w_userno)

      test.delay 20, =>
        [..., msg] = (_ for _ in messages.receiver2 when _.z?)
        assert.isFalse(msg? and msg.z.attributes.t == text)

        [..., msg] = (_ for _ in messages.receiver3 when _.z?)
        assert.isOk(msg? and msg.z.attributes.t == text)
        done()

    it 'should receive the message in first chat after sending k2 from it', (done) =>
      receiver2.sendK2()

      ts = new Date().getTime()
      text = ts.toString()

      #this delay is required. but why?
      test.delay 20, =>
        sender.sendPMMessage(text, receiver2.todo.w_userno)

        test.delay 10, =>
          [..., msg] = (_ for _ in messages.receiver2 when _.z?)
          assert.isOk(msg? and msg.z.attributes.t == text)

          [..., msg] = (_ for _ in messages.receiver3 when _.z?)
          assert.isFalse(msg? and msg.z.attributes.t == text)
          done()

    it 'should receive message in second chat after sending k2 from it', (done) =>
      receiver3.sendK2()

      ts = new Date().getTime()

      text = ts.toString()
      #this delay is required. but why?
      test.delay 20, =>
        sender.sendPMMessage(text, receiver2.todo.w_userno)

        test.delay 10, =>
          [..., msg] = (_ for _ in messages.receiver2 when _.z?)
          assert.isFalse(msg? and msg.z.attributes.t == text)

          [..., msg] = (_ for _ in messages.receiver3 when _.z?)
          assert.isOk(msg? and msg.z.attributes.t == text)
          done()

