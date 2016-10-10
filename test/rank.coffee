should = require('chai').should()

test = require './lib/test-kit'
XatUser = test.IXatUser
deploy = test.deployServer

describe 'ranks', ->
  server = null

  before (done) ->
    deploy().then (_server) ->
      server = _server
      done()

  after -> server.kill()

  describe 'main owner', ->
    owner = null

    chatMeta = null

    before (done) ->
      owner = new XatUser(
        todo:
          w_userno: '50'
          w_useroom: 100
          w_k1: 'k_50'
          pass: 100 + 20000
      ).addExtension('extended-events')
      owner.connect()
      #owner.on 'data', (data) -> console.log(data)
      owner.once 'ee-chat-meta', (data) ->
        chatMeta = data.xml
      owner.once 'ee-done', -> done()

    it 'should auth successfully', ->
      should.exist chatMeta
      chatMeta.should.have.property 'i'
      i = chatMeta.i
      i.attributes.should.have.property 'r'
      i.attributes.r.should.be.equal '1'
  describe 'illegal main owner', ->
    owner = null

    chatMeta = null

    before (done) ->
      owner = new XatUser(
        todo:
          w_userno: '50'
          w_useroom: 100
          w_k1: 'k_50'
          pass: 101 + 20000
      ).addExtension('extended-events')
      owner.connect()
      #owner.on 'data', (data) -> console.log(data)
      owner.once 'ee-chat-meta', (data) ->
        chatMeta = data.xml
      owner.once 'ee-done', -> done()
    it 'shouldn\'t auth successfully', ->
      should.exist chatMeta
      chatMeta.should.have.property 'i'
      i = chatMeta.i
      if i.attributes.r?
        i.attributes.r.should.not.be.equal '1'

  describe 'make', ->
    owner = null
    user = null

    ownerMake = null
    userMake = null
    controlMake = null

    checkMake = (packet, object, subject) ->
      should.exists packet
      packet.should.have.property 'm'
      m = userMake.m

      m.attributes.should.contain.keys [ 'u', 'd', 't', 'p' ]
      m.attributes.u.should.be.equal subject.todo.w_userno
      m.attributes.d.should.be.equal object.todo.w_userno
      m.attributes.t.should.be.equal '/m'

    checkMakeMember = (packet, object, subject) ->
      checkMake packet, object, subject
      packet.m.attributes.p.should.be.equal 'e'

    before (done) ->
      owner = new XatUser(
        todo:
          w_userno: '50'
          w_useroom: 110
          w_k1: 'k_50'
          pass: 100 + 20000
      )
      user = new XatUser(
        todo:
          w_userno: '51'
          w_useroom: 110
          w_k1: 'k_51'
      )
      owner.connect()
      owner.once 'ee-done', ->
        user.connect()
        user.once 'ee-done', ->
          done()

    describe 'owner makes user a member', ->
      before (done) ->
        owner.makeMember user.todo.w_userno
        owner.once 'make-user', (data) ->
          ownerMake = data.xml
        user.once 'control-make-user', (data) ->
          controlMake = data.xml
        user.once 'make-user', (data) ->
          userMake = data.xml
        test.delay 100, -> done()

      it 'user should receive control', ->
        should.exist controlMake
        controlMake.should.have.property 'c'
        c = controlMake.c
        c.attributes.should.contain.keys [ 'u', 'm' ]
        c.attributes.u.should.be.equal user.todo.w_userno
        c.attributes.m.substr(0, 2).should.be.equal '/e'
      it 'user should receive notify', ->
        checkMakeMember userMake, owner, user
      it 'owner should receive notify', ->
        checkMakeMember ownerMake, owner, user
