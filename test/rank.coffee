should = require('chai').should()

Rank = require '../src/structures/rank'

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

    userMeta = null

    checkMake = (packet, object, subject) ->
      should.exist packet
      packet.should.have.property 'm'
      m = packet.m

      m.attributes.should.contain.keys [ 'u', 'd', 't', 'p' ]
      m.attributes.u.should.be.equal subject.todo.w_userno
      m.attributes.d.should.be.equal object.todo.w_userno
      m.attributes.t.should.be.equal '/m'

    checkMakeMember = (packet, object, subject) ->
      checkMake packet, object, subject
      packet.m.attributes.p.should.be.equal 'e'

    checkSignin = (packet, user, rank) ->
      should.exist packet
      packet.should.have.property 'u'
      u = packet.u
      u.attributes.should.contain.keys [ 'u' ]
      u.attributes.u.should.be.equal user.todo.w_userno
      if rank != Rank.GUEST or u.attributes.f?
        Rank.fromNumber(u.attributes.f & 7).should.be.equal(rank)

    checkMeta = (packet, user, rank) ->
      should.exist packet
      packet.should.have.property 'i'
      if rank != Rank.GUEST or u.attributes.r?
        Rank.fromNumber(i.attributes.r).should.be.equal(rank)

    before (done) ->
      owner = new XatUser(
        todo:
          w_userno: '50'
          w_useroom: 110
          w_k1: 'k_50'
          pass: 110 + 20000
      ).addExtension('extended-events').addExtension('user-actions')
      user = new XatUser(
        todo:
          w_userno: '51'
          w_useroom: 110
          w_k1: 'k_51'
      ).addExtension('extended-events').addExtension('user-actions')
      owner.connect()
      owner.once 'ee-done', ->
        user.connect()
        user.once 'ee-chat-meta', (data) ->
          userMeta = data.xml
        user.once 'ee-done', ->
          done()

    it 'user should be a guest', ->
      checkMeta userMeta, user, Rank.GUEST

    describe 'owner makes user a member', ->

      ownerMake = null
      ownerSignin = null
      ownerSignout = null
      userMake = null
      userMeta = null
      controlMake = null

      before (done) ->
        owner.makeMember user.todo.w_userno
        owner.once 'ee-make-user', (data) ->
          ownerMake = data.xml
        owner.once 'ee-user-signin', (data) ->
          ownerSignin = data.xml
        owner.once 'ee-user-signout', (data) ->
          ownerSignout = data.xml
        user.once 'ee-chat-meta', (data) ->
          userMeta = data.xml
        user.once 'ee-control-make-user', (data) ->
          controlMake = data.xml
        user.once 'ee-make-user', (data) ->
          userMake = data.xml
        test.delay 100, -> done()

      it 'user should receive control', ->
        should.exist controlMake
        controlMake.should.have.property 'c'
        c = controlMake.c
        c.attributes.should.contain.keys [ 'u', 't' ]
        c.attributes.u.should.be.equal user.todo.w_userno
        c.attributes.t.substr(0, 2).should.be.equal '/m'

      it 'user should receive notify', ->
        checkMakeMember userMake, user, owner

      it 'owner should receive notify', ->
        checkMakeMember ownerMake, user, owner

      it 'user should receive <i> again', ->
        checkMeta userMeta, user, Rank.MEMBER

      it 'owner should receive <u>', ->
        checkSignin ownerSignin, user, Rank.MEMBER

      it 'owner shouldn\'t receive <l>', ->
        should.not.exist ownerSignout

    describe 'owner makes himself a moderator', ->
      control = make = signin = meta = null

      before (done) ->
        owner.makeModerator owner.todo.w_userno
        owner.once 'ee-control-make-user', (data) ->
          control = data.xml
        owner.once 'ee-make-user', (data) ->
          make = data.xml
        owner.once 'ee-user-signin', (data) ->
          signin = data.xml
        owner.once 'ee-chat-meta', (data) ->
          meta = data.xml

        test.delay 100, -> done()
      it 'owner shouldn\'t be able to do so', ->
        should.not.exist control
        should.not.exist make
        should.not.exist signin
        should.not.exist meta

    describe 'owner makes user a moderator', ->
      userMeta = null
      ownerSignin = null

      before (done) ->
        owner.makeModerator user.todo.w_userno
        owner.once 'ee-user-signin', (data) ->
          ownerSignin = data.xml
        user.once 'ee-chat-meta', (data) ->
          userMeta = data.xml
        test.delay 100, done

      it 'user should receive <i r=2..', ->
        checkMeta userMeta, user, Rank.MODERATOR

      it 'owner should receive <u f=2', ->
        checkSignin ownerSignin, user, Rank.MODERATOR

      describe 'moderator ban user', ->
        victim = null

        victimUser = null
        before (done) ->
          victim = new XatUser(
            todo:
              w_userno: '52'
              w_k1: 'k_52'
              w_useroom: owner.todo.w_useroom
          ).addExtension('user-actions').addExtension('extended-events')

          vistim.connect()
          victim.once 'ee-user', (data) ->
            victimUser = data.xml if not victimUser and data.xml.u?.attributes.u == user.todo.w_userno

          victim.once 'ee-done', -> done()
