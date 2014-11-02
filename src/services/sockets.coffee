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

        @socket.write("<?xml version=\"1.0\"?>\0")
        @socket.write("<!DOCTYPE cross-domain-policy SYSTEM \"http://www.macromedia.com/xml/dtds/cross-domain-policy.dtd\">\0")
        @socket.write("<cross-domain-policy>\0")
        @socket.write("<allow-access-from domain=\"*\" to-ports=\"*\"/>\0")
        @socket.write("</cross-domain-policy>\0")

        connectionPool.add(@socket)

      server.listen @port, -> callback true
