logger = new (require "../utils/logger")(name: 'Authentication')
parser = require "../utils/parser"
database = require "../services/database"

module.exports =
  login: (@handler, pw, name) ->
    database.exec("SELECT * FROM users WHERE username = '#{name}' AND password = '#{pw}' LIMIT 1 ").then((data) =>
      return if data.length < 1

      user = data[0]
      days = if parseInt(user.days) > 0 then "d1=\"#{user.days}\"" else ''

      @handler.send "<v d0=\"#{user.d0}\" d3=\"#{user.d3}\" #{days} dx=\"#{user.xats}\" dt=\"1344072443\" i=\"#{user.id}\" n=\"#{user.username}\" k2=\"#{user.k2}\" k3=\"#{user.k3}\" k1=\"#{user.k}\"  />"
      @handler.send '<c t="/bd"  />'
      @handler.send "<c t=\"/b #{user.id},5,,#{user.nickname},#{user.avatar},#{user.url},0,0,0,0,0,0,0,0,0,0,0,0,0,0\"  />"
      @handler.send '<c t="/bf"  />'
      @handler.send '<ldone  />' 
    )

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
