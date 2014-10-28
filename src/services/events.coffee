crypto = require '../util/crypto'
logger = require '../util/logger'

module.exports =
  class Events
    name: 'Events'

    socket: null

    constructor: (@socket) ->
      @Logger = new logger(this)

    handle: ->
      return if @socket == null

      @Logger.log(@Logger.level.DEBUG, "-> New user connected!")

      parent = @socket

      @socket.on 'data', (data) ->
        packet = crypto.getTagName(data.toString())

        console.log packet
