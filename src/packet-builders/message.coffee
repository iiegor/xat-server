builder = require '../utils/builder'

module.exports =
  # options:
  # message
  # client - instance of services.Client related to user-sender
  # time - timestamp of message
  # messageId - chat-unique (pool-unique?) id of message
  buildNewMain: (options) ->
    builder.create('m')
      .append('u', options.client.user.id)
      .append('t', options.message)
      .append('E', options.time)
      .append('r', options.client.chat.id)
      .append('i', options.messageId || 0)

  buildOldMain: (message) ->
    builder.create('m')
      .append('u', message.uid)
      .append('t', message.message)
      .append('i', message.mid)
      .append('s', '1')
