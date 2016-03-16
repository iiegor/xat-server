test = require './test-kit'
XatUser = test.IXatUser
deploy = test.deployServer

describe 'message', =>
  u1 = null
  u2 = null
  server = null

  messages =
    u1: []
    u2: []
    all: []
  before (beforeDone) =>
    deploy().then (_server) =>
      server = _server
      u1 = new XatUser(
        todo:
          w_userno: 51
          w_useroom: 1
          w_k1: 1112
          w_userrev: 0
      )

      u2 = new XatUser(
        todo:
          w_useroom: 1
          w_userno: 50
          w_k1: 555
          w_userrev: 0
      ).addExtension('user-actions')

      u1.connect()
      u1.on 'data', (data) =>
        messages.u1.push data
        if data.done?
          u2.connect()
          u2.on 'data', (data) =>
            messages.u2.push data
            if data.done?
              beforeDone()

  after =>
    server.kill()

  describe 'user 1', =>
    it 'should receive message sent by user 2', (done) =>
     u2.sendTextMessage('test!')
     test.delay 10, =>
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

