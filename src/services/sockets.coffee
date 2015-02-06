net = require "net"

module.exports =
  class Sockets
    name: 'Sockets'

    constructor: (@port) ->

    bind: (callback) ->
      Server = new net.Server(
        allowHalfOpen: true
        type: "tcp4"
      )

      Server.on 'connection', (socket) ->
        socket.setNoDelay true
        socket.setKeepAlive true

        handler = (require "./handler")(socket)

        socket.on 'data', (buffer) ->
          handler.read buffer.toString()

        socket.on 'end', ->
          console.log "Se ha desconectado un usuario!"


      Server.listen @port, -> callback true
