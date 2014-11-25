logger = new (require "../util/logger")(name: 'Database')
mysql = require "mysql"
settings = require "../config/database"
genericPool = require "generic-pool"

###
Package: https://github.com/coopernurse/node-pool
Documentation: http://nodejsdb.org/2011/05/connection-pooling-node-db-with-generic-pool/
###

Pool = genericPool.Pool(
  name: 'mysql'
  max: 10
  idleTimeoutMillis: 30000

  create: (callback) ->
    Connection = new mysql.createConnection(settings)
    Connection.connect()

    callback Connection

  destroy: (client) ->
    client.end()
)

exports.query = (sql) ->
  self = @

  Pool.acquire (err, db) ->
    db.query sql, (err, rows) ->
      if err
        logger.log logger.level.ERROR, 'Oops, an error ocurred', err

        process.exit 0

      console.log rows

    Pool.release db
