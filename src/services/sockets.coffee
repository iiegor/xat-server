net = require "net"
connectionPool = require "./pool"

module.exports =
  class Sockets
    name: 'Sockets'

    isListening: false
    socket: null

    constructor: (@port) ->

    listen: (callback) ->
      return false if @isListening

      # Server
      server = net.createServer()

      server.on 'connection', (socket) ->
        @socket = socket

        connectionPool.add(@socket)

      server.listen @port, -> callback true

    __dispose: ->
      # Dispose the connection
