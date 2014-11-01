logger = require '../util/logger'
pool = require "./pool"
serializer = require "./serializer"

module.exports =
  class Handshake
    name: 'Handshake'

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
        # Remove this!!
        parent.Logger.log parent.Logger.level.DEBUG, "-> #{data.toString()}"

        # Serialize the packet
        serializer.packet(parent, data.toString())

      @socket.once 'close', (err) ->
        parent.Logger.log(parent.Logger.level.DEBUG, "-> User disconnected!")
        parent.__dispose()

    send: (buffer) ->
      # Write
      @socket.write(buffer + '\0')

      # Log sent data
      @Logger.log(@Logger.level.DEBUG, "-> Sent: #{buffer}")

    __getSocket: ->
      return @socket

    __dispose: ->
      @connectionPool.close(@socket)
