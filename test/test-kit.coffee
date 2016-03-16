chai = require('chai')
chai.use(require('chai-things'))

fork = require('child_process').fork
path = require('path')

XatUser = require('xat-client').XatUser


class ServerInstance
  server: null
  constructor: (server) ->
    @server = server

  kill: ->
    @server.kill()


module.exports.IXatUser =
  class IXatUser extends XatUser
    constructor: (options) ->
      options.ippicker =
        pickIp: -> new Promise (resolve, reject) ->
          resolve({ host: 'localhost', port: 1243 })
      options.perlinNoise = -> new Promise (resolve, reject) ->
        resolve(0)

      return new XatUser(options)

module.exports.deployServer = -> new Promise (resolve, reject) ->
  server = fork(path.join(__dirname, '../bin/xat'), [], silent: true)

  server.on 'error', (err) -> reject err

  wrapper = new ServerInstance(server)

  process.on 'exit', -> server.kill()

  started = false
  server.stdout.on 'data', (data) ->
    if not started and data.indexOf('Server started') >= 0
      started = true
      resolve(wrapper)


module.exports.delay = (delay, callback) -> setTimeout callback, delay

module.exports.should = -> chai.should()

module.exports.timestamp =
  fromServer: (ts) -> Number(ts)
  toServer: (ts) -> ts.toString()
