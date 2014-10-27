net = require "net"
Events = require "./events"

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
        new Events(socket).handle()

      ).listen @port, -> return true
