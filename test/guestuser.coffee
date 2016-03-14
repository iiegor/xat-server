assert = require 'assert'
test = require './test-kit'
XatUser = test.IXatUser
deploy = test.deployServer

conf = require '../config/default'

describe 'guest user', ->

  items = {}
  before (beforeDone) =>
    deploy().then (server) =>
      guest = new XatUser(
        todo:
          w_userno: conf.guestAuthId
          w_name: 'NAME'
          w_avatar: '123'
          w_homepage: 'http://example.com'
          w_useroom: 1
      )

      check = new XatUser(
        todo:
          w_userno: 50
          w_useroom: 1
          w_k1: 555
          w_name: 'tester'
          w_avatar: '555'
          w_userrev: 0
      )

      items.server = server
      items.guest = guest
      items.check = check

      check.connect()
      check.on 'data', (data) =>
        if data.done?
          items.guest.connect()
          beforeDone()
  after (afterDone) =>
    items.server.kill()
    afterDone()

  it "should receive 'u' message with id between [guestid.start, guestid.end)", (done) =>
    items.check.on 'data', (data) =>
      u = data.u
      if u? and u.attributes.u >= conf.guestid.start and u.attributes.u < conf.guestid.end
        throw new Error() if u.attributes.n isnt '' or u.attributes.a isnt '' or u.attributes.h isnt ''
        done()



  it 'should receive done', (done) =>
    items.guest.on 'data', (data) =>
      if data.done?
        done()

