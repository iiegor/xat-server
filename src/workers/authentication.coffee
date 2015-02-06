logger = new (require "../util/logger")(name: 'Authentication')
parser = require "../util/parser"
chat = require "./chat"
database = require "../services/database"

module.exports =
  user: {}

  process: (@handler, packet) ->
    self = @

    # Check
    if @user.authenticated == true
      logger.log logger.level.DEBUG, "The user is already authenticated!"
      return @_logout()

    # Authenticate
    if @_auth(packet) == false
      logger.log logger.level.DEBUG, "Failed to authenticate the user."
      return


  _auth: (packet) ->
    # Parse the packet
    packet = parser.getAttributes(packet)

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

    if !@_resetDetails(@user.id)
      logger.log logger.level.DEBUG, "Reset details failed for user with id #{@user.id}"
      return

    @user.homepage = packet['h']
    @user.avatar = packet['a']

    @user.authenticated = true

    return chat.joinRoom(@handler, @user.chat)

  _resetDetails: (userId, callback) ->
    return true

  _logout: ->
    @handler.send '<dup />'
    @user = {}
    @handler.disconnect()
