database = require "../services/database"

###
Available commands

@name hello
@description Send a 'Hello world'

@name clear all messages
@description Empty the 'messages' table
###

module.exports =
  identifier: '~'

  process: (@handler, user, msg) ->
    # TODO: Need to check the user rank and probably other details to verify the identity of the user
    return unless msg.indexOf @identifier is 0

    switch msg.slice(1)
      when 'hello'
        @handler.send "<m t=\"Hello world\" u=\"#{user}\" />"
      when 'clear all messages'
        database.exec('TRUNCATE TABLE messages').then((data) => @handler.send "<m t=\"Messages cleared\" u=\"#{user}\" />")