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

  exec: (sql, values) -> new Promise((resolve, reject) ->
    Pool.getConnection (err, connection) ->
      reject(err) if err

      values = values || []

      connection.query(sql, values, (err, rows) ->
        connection.release()
        reject(err) if err
        resolve(rows)
      )
  )
