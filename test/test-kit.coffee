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
