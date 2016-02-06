fork = require('child_process').fork
path = require('path')

XatUser = require('xat-client').XatUser

module.exports.IXatUser =
  class IXatUser extends XatUser
    constructor: (options) ->
      options.ippicker =
        pickIp: => new Promise (resolve, reject) =>
          resolve({ host: 'localhost', port: 1243 })
      options.perlinNoise = => new Promise (resolve, reject) =>
          resolve(0)

      return new XatUser(options)

module.exports.deployServer = => new Promise (resolve, reject) =>
  server = fork(path.join(__dirname, '../bin/xat'), [], silent: true)

  server.on 'error', (err) => reject err

  process.on 'exit', => server.kill()

  started = false
  server.stdout.on 'data', (data) =>
    if not started and data.indexOf('Server started') >= 0
      started = true
      resolve()
