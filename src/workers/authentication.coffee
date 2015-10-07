logger = new (require "../utils/logger")(name: 'Authentication')
parser = require "../utils/parser"
database = require "../services/database"

module.exports =
  login: (@handler, pw, name) ->
    # TODO: Replace with real data
    @handler.send '<v d0="1056" d3="5641587" dx="1579" dt="1344072443" i="265826731" n="iegor" k2="1026729849" k3="3699176378" k1="939db96ca5561573d601"  />'
    @handler.send '<c t="/bd"  />'
    @handler.send '<c t="/b 265826731,5,,Returns,385,,0,0,0,0,0,0,0,0,0,0,0,0,0,0"  />'
    @handler.send '<c t="/bf"  />'
    @handler.send '<ldone  />'
    @handler.send '<done  />'

  process: (@handler, packet) -> new Promise((resolve, reject) =>
      @user = @handler.user

      # Check
      if @user.length > 1 and @user.authenticated == true
        logger.log logger.level.DEBUG, "The user is already authenticated!"
        @logout()
        callback(false)

      # Authenticate
      @auth(packet, (done, err) -> if done is true then resolve() else reject(err))
    )

  auth: (packet, callback) ->
    # Parse the packet
    packet = parser.getAttributes(packet)

    @user.id = packet['u']
    @user.d0 = packet['d0']
    @user.f = packet['f']
    @user.chat = packet['c']
    @user.guest = true
    @user.pStr = ''

    i = 0
    while i <= 20
      @user["p#{i}v"] = null
      @user["m#{i}"] = null
      @user.pStr += "p#{i}=\"" + @user["p#{i}v"] + "\" "
      i++

    @resetDetails(@user.id, (res) =>
      callback(false, "Reset details failed for user with id #{@user.id}") if !res

      @user.url = packet['h']
      @user.avatar = packet['a']

      @user.nickname = packet['n']
      @user.nickname = @user.nickname.split('##')

      if @user.nickname.length > 1
        @user.nickname[1] = parser.escape(@user.nickname[1])
        @user.nickname = @user.nickname.join('##')
      else
        @user.nickname = @user.nickname[0]

      ## Disabled at the moment for testing without register
      #return if @user.guest

      @updateDetails()
      @user.authenticated = true

      callback(true, null)
    )

  resetDetails: (userId, callback) ->
    database.exec("SELECT * FROM users WHERE id = '#{userId}' ").then((data) =>
      if data.length < 1
        # No user found
        @user.guest = true

        callback(true)
      else
        # User verification
        @user.guest = false

        callback(true)
    )

  updateDetails: () ->
    self = @

    if @user.id != 0
      database.exec("UPDATE users SET nickname = '#{self.user.nickname}', avatar = '#{self.user.avatar}', url = '#{self.user.url}', connectedlast = 'self.user.remoteAddress' WHERE id = '#{self.user.id}'").then((data) ->
        # ..
      )

  getPowers: () ->
    if @user.days < 1
      return true

    return true

  logout: ->
    @handler.send '<dup />'
    @user = {}
    @handler.dispose()
