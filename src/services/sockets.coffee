net = require "net"
connectionPool = require "./pool"

module.exports =
  class Sockets
    name: 'Sockets'

    socket: null

    constructor: (@port) ->

    listen: (callback) ->
      # Server
      server = net.createServer()

      server.on 'connection', (socket) ->
        @socket = socket

        connectionPool.add(@socket)

      server.listen @port, -> callback true
