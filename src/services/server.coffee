net = require 'net'

logger = require '../utils/logger'
builder = require '../utils/builder'

Client = require './client'

module.exports =
class Server
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

    config = global.Application.config

    clientId = config.guestid.start
    @server.on 'connection', (socket) => (
      client = new Client
      client.id = clientId++
      clientId = config.guestid.start if clientId == config.guestid.end

      # NOTE: The client id is changed to the real one on authentication
      @clients[client.id] = client

      socket._end = socket.end
      socket.end = =>
        @logger.log @logger.level.DEBUG, "A user has been disconnected!"

        if @rooms[client.user.chat]
          if client.user.authenticated
            client.broadcast(builder.create('l').append('u', client.user.id).compose())

          delete @rooms[client.user.chat][client.user.id]

          #delete @rooms[client.user.chat] if @rooms[client.user.chat].length < 1

        delete @clients[client.id]

        socket._end()

      client.setSocket(socket)
    )

    @server.on 'error', (err) =>
      @logger.log @logger.level.ERROR, "Server exception at server.coffee", err

    @server.listen(@port, @host)

  getClientById: (id) -> @clients[id]

  close: -> @server.close()
