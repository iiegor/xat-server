logger = new (require "../utils/logger")(name: 'Authentication')
parser = require "../utils/parser"
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
    self = @

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

    @_resetDetails(@user.id, (res) ->
      if !res
        logger.log logger.level.DEBUG, "Reset details failed for user with id #{@user.id}"
        return

      self.user.url = packet['h']
      self.user.avatar = packet['a']

      self.user.nickname = packet['n']
      self.user.nickname = self.user.nickname.split('##')

      if self.user.nickname.length > 1
        self.user.nickname[1] = parser.escape(self.user.nickname[1])
        self.user.nickname = self.user.nickname.join('##')
      else
        self.user.nickname = self.user.nickname[0]

      ## Disabled at the moment for testing without register
      #return if self.user.guest

      self._updateDetails()
      self.user.authenticated = true

      return chat.joinRoom(self, self.user.chat)
    )

  _resetDetails: (userId, callback) ->
    self = @

    database.acquire (err, db) ->
      db.query("SELECT * FROM users WHERE id = '#{userId}' ", (db, data) ->
        if data.length < 1
          # No user found
          self.user.guest = true

          callback(true)
        else
          # User verification
          self.user.guest = false

          callback(true)
      )

      database.release db

  _updateDetails: () ->
    self = @

    if @user.id != 0
      database.acquire (err, db) ->
        db.query("UPDATE users SET nickname = '#{self.user.nickname}', avatar = '#{self.user.avatar}', url = '#{self.user.url}', connectedlast = 'self.user.remoteAddress' WHERE id = '#{self.user.id}'", (db, data) ->
          # ...
        )

        database.release db


  _getPowers: () ->
    if @user.days < 1
      return true

    return true

  _logout: ->
    @handler.send '<dup />'
    @user = {}
    @handler.disconnect()
