net = require "net"
logger = require "../utils/logger"

{EventEmitter} = require "events"
_ = require "underscore"

module.exports =
  class Server
    _.extend @prototype, EventEmitter.prototype

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
        socket.handler = new (require "./handler")(socket)

        socket.on 'data', (buffer) ->
          socket.handler.read buffer.toString()

        socket.on 'end', =>
          @logger.log @logger.level.DEBUG, "A user has been disconnected!"
          @clients.splice(@clients.indexOf(socket), 1);

        socket.on 'error', (err) =>
          @logger.log @logger.level.ERROR, "Socket exception at server.coffee", err
          socket.destroy()

      @server.on 'error', (err) =>
        @logger.log @logger.level.ERROR, "Server exception at server.coffee", err

      @server.listen @port, -> callback true

    getClientById: (id) ->
      for client in @clients
        return client if client.handler.user.id is id

    close: ->
      @server.close()
