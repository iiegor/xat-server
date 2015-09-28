###
Available commands

@name hello
@description Send a 'Hello world'
###

module.exports =
  identifier: '~'

  process: (@handler, user, msg) ->
    return unless msg.indexOf @identifier is 0

    switch msg.slice(1)
      when 'hello'
        @handler.send "<m t=\"Hello world\" u=\"#{user}\" />"