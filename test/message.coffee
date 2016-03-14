test = require './test-kit'
XatUser = test.IXatUser
deploy = test.deployServer

describe 'message', () ->

  it 'u1 should receive message sent by u2', (done) =>
    deploy().then (server) =>
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
        if data.done?
          u2.connect()

          u2.on 'data', (data) =>
            if data.done?

              u2.sendTextMessage('test!')

              u1.on 'data', (data) =>

                if data.m and data.m.attributes.t == 'test!'
                  done()
