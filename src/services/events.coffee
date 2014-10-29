crypto = require '../util/crypto'
logger = require '../util/logger'

module.exports =
  class Events
    name: 'Events'

    constructor: (socket, id) ->
      @Logger = new logger(this)

      @handle(socket)

    handle: (socket) ->
      return if socket == null

      @Logger.log(@Logger.level.DEBUG, "-> New user connected!")

      socket.on 'data', (data) ->
        packet = crypto.getTagName(data.toString())

        console.log packet

    send: (buffer) ->
