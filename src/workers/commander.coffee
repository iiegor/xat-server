###
Available commands

@name hello
@description Send a 'Hello world'
###

module.exports =
  process: (@handler, user, msg) ->
    if msg is '~hello'
      @handler.send "<m t=\"Hello world\" u=\"#{user}\" />"