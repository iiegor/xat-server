chai = require 'chai'
chai.use(require 'chai-things')

fork = require('child_process').fork
path = require 'path'

assert = require 'assert'

XatUser = require('xat-client').XatUser

config = require '../../config/tests'

class ServerInstance
  server: null
  _error: null

  constructor: (server) ->
    @server = server

    # FIXME:
    #  The solution below intended to catch server crashes.
    #  It is not reliable enougth.
    #  Firstly, while server.kill isn't invoked,
    #  we can't know, has server crashed or not.
    #  Secondly, if server crashed during tests
    #  in the last file, we couldn't detect it too.
    #  In this cases, some tests may pass successfully
    #  although they crash the server, other tests
    #  may detect unusual errors.
    #
    server.on 'exit', (code, signal) =>
      if code != 0
        @_error =
          code: code
          signal: signal

  kill: =>
    assert(@_error == null, 'Server has crashed')

    @server.kill()

exports.IXatUser =
  class IXatUser extends XatUser
    constructor: (options) ->
      options.ippicker =
        pickIp: -> new Promise (resolve, reject) ->
          resolve({host: 'localhost', port: 1243})
      options.perlinNoise = -> new Promise (resolve, reject) ->
        resolve(0)

      u = new XatUser(options)
      return u

exports.deployServer = (options) -> new Promise (resolve, reject) ->
  options = options || {}

  server = fork(path.join(__dirname, '../../bin/xat-test'), [], silent: true)

  server.on 'error', (err) ->
    reject err

  wrapper = new ServerInstance(server)

  process.on 'exit', -> wrapper.kill()

  started = false
  server.stderr.on 'data', (data) ->
    console.log data.toString()

  server.stdout.on 'data', (data) ->
    if not started and data.indexOf('Server started') >= 0
      started = true
      resolve(wrapper)

exports.delay = (delay, callback) -> setTimeout callback, delay

exports.should = -> chai.should()

exports.convertTimestamp =
  fromServer: (ts) -> Number(ts)
  toServer: (ts) -> ts.toString()

