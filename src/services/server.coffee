net = require "net"

logger = require "../utils/logger"
handler = require "./handler"

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
  clients: {}
  rooms: {}

  ###
  Section: Construction
  ###
  constructor: (@port, @host) ->
    global.Server = this

  ###
  Section: Public
  ###
  bind: ->
    @server = new net.Server

    @server.on 'listening', -> global.Application.emit('application:started')

    clientId = 0
    @server.on 'connection', (socket) =>
      client = new handler
      client.id = clientId--
      clientId %= 1 << 31

      # NOTE: The client id is changed to the real one on authentication
      @clients[client.id] = client

      client.setSocket(socket)

      socket.on 'end', =>
        @logger.log @logger.level.DEBUG, "A user has been disconnected!"

        if @rooms[client.user.chat]
          clientIndex = @rooms[client.user.chat].indexOf(client.id)

          @rooms[client.user.chat].splice(clientIndex, 1) if clientIndex > -1

          #delete @rooms[client.user.chat] if @rooms[client.user.chat].length < 1

        delete @clients[client.id]

      socket.on 'error', (err) =>
        @logger.log @logger.level.ERROR, "Socket exception from #{socket.remoteAddress}", err

    @server.on 'error', (err) =>
      @logger.log @logger.level.ERROR, "Server exception at server.coffee", err

    @server.listen(@port, @host)

  getClientById: (id) -> @clients[id]

  close: -> @server.close()
