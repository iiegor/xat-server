net = require "net"
logger = require "../utils/logger"

module.exports =
  class Server
    ###
    Section: Properties
    ###
    logger: new logger(this)
    server: null
    clients: []

    ###
    Section: Construction
    ###
    constructor: (@port) ->
      global.Server = this

    ###
    Section: Private
    ###
    bind: (callback) ->
      @server = new net.Server(
        allowHalfOpen: false
        type: "tcp4"
      )

      @server.on 'connection', (socket) =>
        socket.setNoDelay true
        socket.setKeepAlive true

        @clients.push(socket)

        handler = new (require "./handler")(socket)

        socket.on 'data', (buffer) ->
          handler.read buffer.toString()

        socket.on 'end', =>
          console.log "Se ha desconectado un usuario!"
          @clients.splice(@clients.indexOf(socket), 1);

        socket.on 'error', (err) =>
          @logger.log @logger.level.ERROR, "Socket exception at server.coffee", err
          socket.destroy()

      @server.on 'error', (err) =>
        @logger.log @logger.level.ERROR, "Server exception at server.coffee", err

      @server.listen @port, -> callback true

    close: ->
      @server.close()
