logger = require "../util/logger"
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
  Pool.acquire (err, db) ->
    return console.error "Connection error: #{err}" if err

    db.query sql, (err, rows) ->
      throw console.log err if err

      console.log rows

    Pool.release db
