should = require('chai').should()

test = require '../src/test/test-kit'
XatUser = test.IXatUser
deploy = test.deployServer

conf = require '../config/default'


describe 'guest user', ->

  guest = null
  check = null
  server = null

  before () ->
    deploy().then (_server) ->
      server = _server
      guest = new XatUser(
        todo:
          w_userno: conf.guestAuthId
          w_name: 'NAME'
          w_avatar: '123'
          w_homepage: 'http://example.com'
          w_useroom: 100
      ).addExtension('user-actions').addExtension('extended-events')

      check = new XatUser(
        todo:
          w_userno: 50
          w_useroom: 100
          w_k1: 'k_50'
          w_name: 'tester'
          w_avatar: '555'
          w_userrev: 0
      ).addExtension('user-actions').addExtension('extended-events')



  after ->
    server.kill()


  describe 'guest connects to chat with user already connected', ->

    messages =
      all: []
      check: []
      guest: []

    before (beforeDone) ->
      check.connect()

      check.on 'data', (data) ->
        messages.check.push data
        messages.all.push data
      check.on 'ee-done', (data) ->
        guest.connect()

        guest.on 'ee-done', (data) ->
          beforeDone()

        guest.on 'data', (data) ->
          messages.guest.push data
          messages.all.push data

    after ->
      check.end()
      guest.end()

    describe 'check', ->

      it "should receive the only 'u' message with id between [guestid.start, guestid.end)", ->
        messages.check.should.contain.an.item.with.property('u')

        for message in messages.check when message.u?
          u = message.u
          u.attributes.u.should.be.within conf.guestid.start, conf.guestid.end - 1

      it "should receive 'u' with empty n,a,h, with v=1, cb=0 and without any other attributes", ->
        for message in messages.check when message.u?
          u = message.u
          u.attributes.n.should.equal ''
          u.attributes.a.should.equal ''
          u.attributes.h.should.equal ''



    describe 'guest', ->
      it 'should receive done', ->
        messages.guest.should.contain.an.item.with.property('done')

      it "shouldn't be able to send messages, should be able to receive message", (done) ->
        ts = new Date().getTime()
        checkerMessage = 'checker message' + ts
        guestMessage = 'guest message ' + ts
        guest.sendTextMessage guestMessage
        check.sendTextMessage checkerMessage
        test.delay 20, ->

          gotdone = false
          for message in messages.check
            if message.done?
              gotdone = true
            if gotdone
              message.m?.should.be.false

          [..., receivedByGuest] = (message for message in messages.guest\
                                                        when message.m? and message.m.attributes? and message.m.attributes.t == checkerMessage)
          should.exist(receivedByGuest)

          receivedByGuest = receivedByGuest.m


          receivedByGuest.should.have.property 'attributes'
          receivedByGuest.attributes.should.have.property 'u'
          receivedByGuest.attributes.u.split('_')[0].should.be.equal(check.todo.w_userno.toString())
          receivedByGuest.attributes.t.should.be.equal(checkerMessage)
          done()
