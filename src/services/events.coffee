crypto = require '../util/crypto'

module.exports =
  class Events
    name: 'Events'

    socket: null

    constructor: (@socket) ->
    handle: ->
      return if @socket == null

      console.log '-> Nuevo usuario conectado'
      parent = @socket

      @socket.on 'data', (data) ->
        packet = crypto.getTagName(data.toString())

        console.log packet
