database = require '../services/database'

###
Available commands

@name hello
@description Send a 'Hello world'

@name clear all messages
@description Empty the 'messages' table
###

module.exports =
  identifier: '!'

  process: (@client, message) ->
    # TODO: Need to check the user rank and probably other details to verify the identity of the user
    return unless message.indexOf @identifier is 0

    switch message.slice(1)
      when 'hello'
        @client.send "<m t=\"Hello world\" u=\"#{@client.user.id}\" />"
      when 'clear all messages'
        database.exec('TRUNCATE TABLE messages').then((data) => @client.send "<m t=\"Messages cleared\" u=\"#{@client.user.id}\" />")