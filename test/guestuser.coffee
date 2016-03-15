should = require('chai').should()

test = require './test-kit'
XatUser = test.IXatUser
deploy = test.deployServer

conf = require '../config/default'


describe 'guest user', ->

  items = {}
  guest = null
  check = null
  server = null

  before (beforeDone) =>
    deploy().then (_server) =>
      server = _server
      beforeDone()

  beforeEach (beforeEachDone) =>
      guest = new XatUser(
        todo:
          w_userno: conf.guestAuthId
          w_name: 'NAME'
          w_avatar: '123'
          w_homepage: 'http://example.com'
          w_useroom: 1
      ).addExtension('user-actions')

      check = new XatUser(
        todo:
          w_userno: 50
          w_useroom: 1
          w_k1: 555
          w_name: 'tester'
          w_avatar: '555'
          w_userrev: 0
      )
      beforeEachDone()


  afterEach (afterEachDone) =>
    check.end()
    guest.end()
    afterEachDone()


  after (afterDone) =>
    server.kill()
    afterDone()


  describe 'checker', =>

    it "should receive 'u' message with id between [guestid.start, guestid.end)", (done) =>
      check.connect()
      check.on 'data', (data) =>
        if data.done?
          guest.connect()

          check.on 'data', (data) =>

            u = data.u
            if u?
              u.attributes.u.should.be.at.least conf.guestid.start
              u.attributes.u.should.be.below conf.guestid.end

              done()


    it "should receive 'u' with empty n,a,h, with v=1, cb=0 and without any other attributes", (done) =>
      check.connect()
      check.on 'data', (data) =>
        if data.done?
          guest.connect()

          check.on 'data', (data) =>
            u = data.u
            if u?
              u.attributes.n.should.equal ''
              u.attributes.a.should.equal ''
              u.attributes.h.should.equal ''
              done()



  describe 'guest', () =>
    it 'should receive done', (done) =>
      guest.connect()
      guest.on 'data', (data) =>
        if data.done?
          done()
     it "shouldn't be able to send messages", (done) =>
       guest.sendTextMessage('hello all')
       done()
