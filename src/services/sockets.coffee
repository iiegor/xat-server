net = require "net"

module.exports =
  class Sockets
    name: 'Sockets'

    isListening: false
    server: null

    constructor: (@port) ->

    listen: ->
      return false if @isListening

      # Server
      net.createServer((socket) ->
        console.log "-> New client connected!"

        socket.on "data", (data) ->
          console.log data.toString()
          
      ).listen @port, -> return true
