database = require '../services/database'

module.exports =
  getById: (userProfileId, fields) -> new Promise((resolve, reject) ->
    if fields instanceof Array
      sql = 'SELECT ?? FROM users WHERE id = ? LIMIT 1'
      values = [fields, userProfileId]
    else
      sql = 'SELECT * FROM users WHERE id = ? LIMIT 1'
      values = [userProfileId]
    database.exec(sql, values).then((data) ->
      resolve(data[0])
    ).catch((err) -> reject(err))
  )
