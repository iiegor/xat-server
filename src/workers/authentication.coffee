crypto = require "../util/crypto"
chat = require "./chat"

module.exports =
  user: {}

  process: (@handler, packet) ->
    # Define
    packet = crypto.getAttributes(packet)

    # Set
    @user = packet
    @resetDetails(@user.u)

    chat.joinRoom(@handler, @user.c)

  resetDetails: (id) ->

  logout: ->
    @handler.send '<dup />'
    @user = {}

  reconnect: ->
