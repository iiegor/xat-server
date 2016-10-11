mysql = require 'mysql'
config = require '../../config/database'

###
Package documentation: https://github.com/mysqljs/mysql
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

  # Query execution
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
