crypto = require '../util/crypto'
logger = require '../util/logger'
pool = require "./pool"

module.exports =
  class Events
    name: 'Events'

    connectionPool: null

    constructor: (cP, @socket, @id) ->
      @Logger = new logger(this)
      @connectionPool = cP

      @handle()

    handle: ->
      return if @socket == null

      parent = @

      @Logger.log(@Logger.level.DEBUG, "-> New user connected!")

      @socket.on 'data', (data) ->
        packet = crypto.getTagName(data.toString())

        console.log packet

      @socket.once 'close', (err) ->
        parent.__dispose()

    send: (buffer) ->
      console.log "Sending to client: #{buffer}"

    __dispose: ->
      @connectionPool.close(@socket)
