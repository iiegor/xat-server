crypto = require "../util/crypto"
chat = require "./chat"

module.exports =
  user: {}

  process: (@handshake, packet) ->
    # Define
    packet = crypto.getAttributes(packet)

    # Set
    @user = packet
    @resetDetails(@user.u)

    chat.joinRoom(this, @user.c)

  resetDetails: (id) ->

  logout: ->
    @handshake.send '<dup />'
    @user = {}

  reconnect: ->
    @handshake.__dispose()
