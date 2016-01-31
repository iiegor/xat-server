database = require "../services/database"

module.exports =
  getById: (userProfileId) -> new Promise((resolve, reject) ->
    # TODO: Select only the needed data
    database.exec('SELECT * FROM users WHERE id = ? LIMIT 1', [userProfileId]).then((data) ->
      resolve(data[0])
    ).catch((err) -> reject(err))
  )
