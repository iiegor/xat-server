test = require './test-kit'
XatUser = test.IXatUser
deploy = test.deployServer

describe 'private messaging', =>
  sender = null
  receiver = null
  server = null

  before (beforeDone) =>
    deploy().then (_server) =>
      server = _server
      sender = new XatUser(
        todo:
          w_userno: 50
          w_k1: 555
          w_userrev: 0
      ).addExtension('user-actions')

      receiver = new XatUser(
        todo:
          w_userno: 51
          w_k1: 1112
          w_userrev: 0
      )
      beforeDone()

  after =>
    server.kill()

  describe 'users are in the same room', =>
    messages =
      sender: []
      receiver: []
      all: []

    before (beforeDone) =>
      sender.todo.w_useroom = receiver.todo.w_useroom = 1
      sender.connect()
      sender.on 'data', (data) =>
        messages.sender.push data
        messages.all.push data
        
        if data.done?
          receiver.connect()
          receiver.on 'data', (data) =>
            messages.receiver.push data
            messages.all.push data
            if data.done?
              beforeDone()


    it 'should receive "p" private message', =>
      ts = new Date().getTime()
      text = 'pmp' + ts
      sender.sendPMMessage text, receiver.todo.w_userno, true
      test.delay 20, =>
        messages.receiver.should.contains.an.item.with.property('p')

        [..., message] = message for message in messages.receiver when message.p?
        p = message.p
        p.attributes.should.have.keys(['u', 't', 'E'])
        p.attributes.u.should.be.equal(sender.todo.w_userno.toString())
        p.attributes.t.should.be.equal(text)
        test.timestamp.fromServer(p.attributes.E).should.be.closeTo(ts, 10 * 1000)

    it 'should receive "p" private chat message', =>
      ts = new Date().getTime()
      text = 'pcp' + ts
      sender.sendPCMessage text, receiver.todo.w_userno, true
      test.delay 20, =>
        messages.should.contains.an.item.with.property('p')
        [..., message] = message for message in messages.receiver when message.p?
        p = message.p
        p.attributes.should.have.keys(['E', 'u', 't', 's', 'd'])

        test.timestamp.fromServer(p.attributes.E).should.be.closeTo(ts, 10 * 1000)
        p.attributes.u.should.be.equal(sender.todo.w_userno.toString())
        p.attributes.t.should.be.equal(text)
        p.attributes.s.should.be.equal('2')
        p.attributes.d.should.be.equal(p.attributes.d)



    it 'should receive "z" private message', =>
      ts = new Date().getTime()
      text = 'pmz' + ts
      sender.sendPMMessage text, receiver.todo.w_userno, false
      test.delay 20, =>
        messages.receiver.should.contains.an.item.with.property('z')
        [..., message] = message for message in messages.receiver when message.z?
        z = message.z
        z.attributes.should.have.keys(['E', 'd', 'u', 't'])

        z.attributes.u.should.be.oneOf([sender.todo.w_userno + '_' + sender.todo.w_userrev, sender.todo.w_userno.toString()])
        z.attributes.d.should.be.equal(receiver.todo.w_userno.toString())
        test.timestamp.fromServer(z.attributes.E).should.be.closeTo(ts, 10 * 1000)
        z.attributes.t.should.be.equal(text)

    it 'should receive "z" private chat message', =>
      ts = new Date().getTime()
      text = 'pcz' + ts
      sender.sendPCMessage text, receiver.todo.w_userno, false
      test.delay 20, =>
        messages.receiver.should.contains.an.item.with.property('z')
        [..., message] = message for message in messages.receiver when message.z?
        z = message.z
        z.attributes.should.have.keys(['E', 'd', 'u', 't', 's'])

        test.timestamp.fromServer(z.attributes.E).should.be.closeTo(ts, 10 * 1000)
        z.attributes.d.should.be.equal(receiver.todo.w_userno.toString())
        z.attributes.u.should.be.oneOf([sender.todo.w_userno + '_' + sender.todo.w_userrev, sender.todo.w_userno.toString()])
        z.attributes.t.should.be.equal(text)
        z.attributes.s.should.be.equal('2')


    it "shouldn't receive messages with illegal 'u' attribute", =>
      0.should.be.equal(1) #not implemented
