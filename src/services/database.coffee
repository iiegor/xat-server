mysql = require 'mysql'
config = require '../../config/database'

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

_exec = (options, values) -> new Promise((resolve, reject) ->
  Pool.getConnection (err, connection) ->
    return reject(err) if err

    values = values || []

    connection.query(options, values, (err, rows) ->
      connection.release()
      return reject(err) if err
      resolve(rows)
    )
)

module.exports =
  # Ping database
  initialize: (cb) ->
    Pool.getConnection (err) -> cb err
  exec: (sql, values) -> _exec({ sql: sql }, values)
  execJoin: (sql, values) -> _exec({ sql: sql, nestTables: true}, values)
