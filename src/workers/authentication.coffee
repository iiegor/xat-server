logger = new (require "../util/logger")(name: 'Authentication')
crypto = require "../util/crypto"
chat = require "./chat"

module.exports =
  user: {}

  process: (@handler, packet) ->
    self = @

    # Check
    if @user.authenticated == true
      logger.log logger.level.DEBUG, "The user is already authenticated!"

    # Authenticate
    if @_auth(packet) == false
      logger.log logger.level.DEBUG, "Failed to authenticate the user."
      return


  _auth: (packet) ->
    # Parse the packet
    packet = crypto.getAttributes(packet)

    @user.id = packet['u']
    @user.d0 = packet['d0']
    @user.f = packet['f']
    @user.chat = packet['c']
    @user.pStr = ''

    i = 0
    while i <= 20
      @user["p#{i}v"] = null
      @user["m#{i}"] = null
      @user.pStr += "p#{i}=\"" + @user["p#{i}v"] + "\" " 
      i++


    return chat.joinRoom(@handler, @user.c)

  _logout: ->
    @handler.send '<dup />'
    @user = {}
