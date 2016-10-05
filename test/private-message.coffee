test = require '../src/test/test-kit'
XatUser = test.IXatUser
deploy = test.deployServer
assert = require('chai').assert
should = require('chai').should()

describe 'private messaging', ->
  server = null
  senderConfig =
    todo:
      w_userno: 50
      w_k1: 'k_50'
      w_userrev: 0

  receiverConfig =
    todo:
      w_userno: 51
      w_k1: 'k_51'
      w_userrev: 0



  before () ->
    deploy().then (_server) ->
      server = _server

  after ->
    server.kill()

  describe 'users are in the same room', ->
    sender = null
    receiver = null
    messages =
      sender: []
      receiver: []
      all: []

    before (beforeDone) ->
      sender = new XatUser(senderConfig).addExtension('user-actions').addExtension('extended-events')
      receiver = new XatUser(receiverConfig).addExtension('extended-events')

      sender.todo.w_useroom = receiver.todo.w_useroom = 1

      sender.connect()

      sender.on 'ee-done', () ->
        receiver.connect()

      receiver.on 'ee-done', () ->
        beforeDone()

      receiver.on 'data', (data) ->
        messages.receiver.push data
        messages.all.push data

    after ->
      sender.end()
      receiver.end()


    it 'should receive "p" private message', (done) ->
      ts = new Date().getTime()
      text = 'pmp' + ts
      sender.sendPMMessage text, receiver.todo.w_userno, true
      receiver.once 'ee-private-message', (data) ->
        data = data.xml

        should.exist data.p

        p = data.p
        p.attributes.should.have.keys(['u', 't', 'E'])
        p.attributes.u.should.be.equal(sender.todo.w_userno.toString())
        p.attributes.t.should.be.equal(text)
        test.convertTimestamp.fromServer(p.attributes.E).should.be.closeTo(ts, 2 * 1000)
        done()

    it 'should receive "p" private chat message', (done) ->
      ts = new Date().getTime()
      text = 'pcp' + ts
      sender.sendPCMessage text, receiver.todo.w_userno, true
      receiver.once 'ee-private-message', (data) ->
        data = data.xml
        should.exist data.p

        p = data.p
        p.attributes.should.have.keys(['E', 'u', 't', 's', 'd'])

        test.convertTimestamp.fromServer(p.attributes.E).should.be.closeTo(ts, 2 * 1000)
        p.attributes.u.should.be.equal(sender.todo.w_userno.toString())
        p.attributes.t.should.be.equal(text)
        p.attributes.s.should.be.equal('2')
        p.attributes.d.should.be.equal(p.attributes.d)
        done()



    it 'should receive "z" private message', (done) ->
      ts = new Date().getTime()
      text = 'pmz' + ts
      sender.sendPMMessage text, receiver.todo.w_userno, false
      receiver.once 'ee-private-message', (data) ->
        data = data.xml
        should.exist data.z

        z = data.z
        z.attributes.should.have.keys(['E', 'd', 'u', 't'])

        z.attributes.u.should.be.oneOf([sender.todo.w_userno + '_' + sender.todo.w_userrev, sender.todo.w_userno.toString()])
        z.attributes.d.should.be.equal(receiver.todo.w_userno.toString())
        test.convertTimestamp.fromServer(z.attributes.E).should.be.closeTo(ts, 10 * 1000)
        z.attributes.t.should.be.equal(text)

        done()

    it 'should receive "z" private chat message', (done) ->
      ts = new Date().getTime()
      text = 'pcz' + ts
      sender.sendPCMessage text, receiver.todo.w_userno, false
      receiver.once 'ee-private-message', (data) ->
        data = data.xml
        should.exist data.z

        z = data.z
        z.attributes.should.have.keys(['E', 'd', 'u', 't', 's'])

        test.convertTimestamp.fromServer(z.attributes.E).should.be.closeTo(ts, 10 * 1000)
        z.attributes.d.should.be.equal(receiver.todo.w_userno.toString())
        z.attributes.u.should.be.oneOf([sender.todo.w_userno + '_' + sender.todo.w_userrev, sender.todo.w_userno.toString()])
        z.attributes.t.should.be.equal(text)
        z.attributes.s.should.be.equal('2')
        done()


    it "shouldn't receive messages with illegal 'u'(source) attribute", (done) ->
      text = 'illegal'
      illegalId = sender.todo.w_userno + 1
      sender._NetworkSendMsg(illegalId, text, receiver.todo.w_userno)
      test.delay 100, ->
        [..., message] = (message for message in messages.receiver when message.z?)
        assert.isFalse(message? and message.z.attributes.u.split('_')[0] == illegalId.toString())
        done()


  describe 'sender and receiver are in different chats', ->
    sender = null
    receiver = null

    messages =
      sender: []
      receiver: []
      all: []

    before (beforeDone) ->
      sender = new XatUser(senderConfig).addExtension('user-actions').addExtension('extended-events')
      receiver = new XatUser(receiverConfig).addExtension('extended-events')

      sender.todo.w_useroom = 1
      receiver.todo.w_useroom = 2

      sender.connect()
      sender.on 'ee-done', () ->
        receiver.connect()

      receiver.on 'ee-done', () ->
        beforeDone()

      receiver.on 'data', (data) ->
        messages.receiver.push data
        messages.all.push data

    after ->
      sender.end()
      receiver.end()


    it 'shouldn\'t receive "p" private message', (done) ->
      ts = new Date().getTime()
      text = 'pmp' + ts
      sender.sendPMMessage text, receiver.todo.w_userno, true
      test.delay 50, ->
        [..., p] = (message.p for message in messages.receiver when message.p?)

        assert.isFalse(p? and p.attributes.t and p.attributes.t == text)

        done()

    it 'shouldn\'t receive "p" private chat message', (done) ->
      ts = new Date().getTime()
      text = 'pcp' + ts
      sender.sendPCMessage text, receiver.todo.w_userno, true
      test.delay 50, ->
        [..., p] = (message.p for message in messages.receiver when message.p?)

        assert.isFalse(p? and p.attributes.t and p.attributes.t == text)

        done()



    it 'should receive "z" private message', (done) ->
      ts = new Date().getTime()
      text = 'pmz' + ts
      sender.sendPMMessage text, receiver.todo.w_userno, false
      receiver.once 'ee-private-message', (data) ->
        data = data.xml

        should.exist data.z

        z = data.z

        z.attributes.should.have.keys(['E', 'd', 'u', 't'])

        z.attributes.u.should.be.oneOf([sender.todo.w_userno + '_' + sender.todo.w_userrev, sender.todo.w_userno.toString()])
        z.attributes.d.should.be.equal(receiver.todo.w_userno.toString())
        test.convertTimestamp.fromServer(z.attributes.E).should.be.closeTo(ts, 10 * 1000)
        z.attributes.t.should.be.equal(text)

        done()

    it 'should receive "z" private chat message', (done) ->
      ts = new Date().getTime()
      text = 'pcz' + ts
      sender.sendPCMessage text, receiver.todo.w_userno, false
      receiver.once 'ee-private-message', (data) ->
        data = data.xml

        should.exist data.z

        z = data.z

        z.attributes.should.have.keys(['E', 'd', 'u', 't', 's'])

        test.convertTimestamp.fromServer(z.attributes.E).should.be.closeTo(ts, 10 * 1000)
        z.attributes.d.should.be.equal(receiver.todo.w_userno.toString())
        z.attributes.u.should.be.oneOf([sender.todo.w_userno + '_' + sender.todo.w_userrev, sender.todo.w_userno.toString()])
        z.attributes.t.should.be.equal(text)
        z.attributes.s.should.be.equal('2')
        done()


    it "shouldn't receive messages with illegal 'u' attribute", (done) ->
      text = 'illegal'
      illegalId = sender.todo.w_userno + 1
      sender._NetworkSendMsg(illegalId, text, receiver.todo.w_userno)
      test.delay 50, ->
        [..., message] = (message for message in messages.receiver when message.z?)
        assert.isFalse(message? and message.z.attributes.u.split('_')[0] == illegalId.toString())
        done()
