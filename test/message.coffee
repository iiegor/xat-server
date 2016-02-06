fork = require('child_process').fork
path = require 'path'


test = require './test-kit'
XatUser = test.IXatUser

describe 'message', () ->
  @timeout(10000)

  it 'u1 should receive message sent by u2', (done) =>

    server = fork(path.join(__dirname, '../bin/xat'), [], silent: true)


    process.on 'exit', =>
      server.kill()

    started = false
    server.stdout.on 'data', (data) =>
      if not started and data.indexOf('Server started') >= 0
        started = true
        u1 = new XatUser(
          todo:
            w_useroom: 1
            w_userno: 1
            w_k1: 1
            w_k3: 3
            w_userrev: 0
        )
        u2 = new XatUser(
          todo:
            w_useroom: 1
            w_userno: 2
            w_k1: 1
            w_k3: 3
            w_userrev: 0
        )
        u2.addExtension('user-actions')
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

