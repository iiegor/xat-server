config = require '../../config/database'
mysql = require 'mysql'

###
Package documentation: https://github.com/felixge/node-mysql
###

Pool = mysql.createPool(
  connectionLimit: 10
  host: config.mysql.server
  user: config.mysql.user
  password: config.mysql.password
  database: config.mysql.database
)

module.exports =
  # Ping database
  initialize: (cb) ->
    Pool.getConnection (err) -> cb err

  # Execute sql
  exec: (sql=null) -> new Promise((resolve, reject) ->
    Pool.getConnection (err, connection) ->
      reject(err) if err

      # Execute query
      if sql is null
        resolve()
      else
        connection.query(sql, (err, rows) -> resolve(rows))

      # Release connection
      connection.release()
  )