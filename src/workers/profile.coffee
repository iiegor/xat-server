database = require "../services/database"

module.exports =
  getById: (userProfileId) -> new Promise((resolve, reject) =>
    # TODO: Select only the needed data
    database.exec("SELECT * FROM users WHERE id = '#{userProfileId}' LIMIT 1 ").then((data) ->
      resolve(data[0])
    ).catch((err) -> reject(err))
  )