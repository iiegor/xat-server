mysql = require "mysql"
config = require "../../config/database"
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
    Connection = new mysql.createConnection({
    	host: config.mysql.server
    	user: config.mysql.user
    	password: config.mysql.password
    	database: config.mysql.database
    })
    Connection.connect()

    callback Connection

  destroy: (client) ->
    client.end()
)

module.exports =
  exec: (sql=null) ->
    new Promise((resolve, reject) ->
      Pool.acquire (err, db) ->
        reject(err) if err

        # Execute
        if sql is null
          resolve()
        else
          db.query(sql, (db, data) -> resolve(data))

        # Release
        Pool.release db
    )
