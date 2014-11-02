database = require "../services/database"
crypto = require "../util/crypto"

chat = require "./chat"

module.exports =
  user: {}

  process: (@handshake, packet) ->
    # Define
    packet = crypto.getAttributes(packet)

    # Set
    @user = packet
    @user.authenticated = true

    chat.joinRoom(this, @user.c)

  logout: ->
    @handshake.send '<dup />'
    @user = {}

  reconnect: ->
    @handshake.__dispose()
