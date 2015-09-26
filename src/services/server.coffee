net = require "net"
logger = require "../utils/logger"

module.exports =
  class Server
    ###
    Section: Properties
    ###
    logger: new logger(this)
    server: null

    ###
    Section: Construction
    ###
    constructor: (@port) ->

    ###
    Section: Private
    ###
    bind: (callback) ->
      self = @

      @server = new net.Server(
        allowHalfOpen: false
        type: "tcp4"
      )

      @server.on 'connection', (socket) ->
        socket.setNoDelay true
        socket.setKeepAlive true

        handler = (require "./handler")(socket)

        socket.on 'data', (buffer) ->
          handler.read buffer.toString()

        socket.on 'end', ->
          console.log "Se ha desconectado un usuario!"

        socket.on 'error', (err) ->
          self.logger.log self.logger.level.ERROR, "Socket exception at server.coffee", err
          socket.destroy()

      @server.on 'error', (err) ->
        self.logger.log self.logger.level.ERROR, "Server exception at server.coffee", err

      @server.listen @port, -> callback true

    close: ->
      @server.close()
