logger = new (require "../utils/logger")(name: 'User')
parser = require "../utils/parser"
math = require "../utils/math"
database = require "../services/database"

module.exports =
  login: (name, pw) ->
    # TODO:
    #   Fix user days packet attr.
    #   Complete all the attrs with real data.
    # INFO:
    #   d2 - married id
    database.exec("SELECT * FROM users WHERE username = '#{name}' AND loginKey = '#{pw}' LIMIT 1 ").then((data) =>
      return if data.length < 1

      user = data[0]
      days = if parseInt(user.days) > 0 then "d1=\"#{user.days}\"" else ''
      married = if parseInt(user.d2) > 0 then "d2=\"#{user.d2}\"" else ''

      str = 'd4="2209282" d5="6292512" d6="2097193" d9="262144"'

      @send "<v d0=\"#{user.d0}\" #{days} #{married} d3=\"#{user.d3}\" #{str} dx=\"#{user.xats}\" dt=\"#{Date.now()}\" i=\"#{user.id}\" n=\"#{user.username}\" k2=\"#{user.k2}\" k3=\"#{user.k3}\" k1=\"#{user.k}\"  />"
      @send '<c t="/bd"  />'
      @send "<c t=\"/b #{user.id},5,,#{user.nickname},#{user.avatar},#{user.url},0,0,0,0,0,0,0,0,0,0,0,0,0,0\"  />"
      @send '<c t="/bf"  />'
      @send '<ldone  />'
    )

  # TODO: Improve this
  process: (@handler, packet) -> new Promise (resolve, reject) =>
    @user = @handler.user

    # Authenticate
    @auth(packet, (done, err) -> if done is true then resolve() else reject(err))

  auth: (packet, callback) ->
    # Parse the packet
    packet = parser.getAttributes(packet)

    @user.id = packet['u']
    @user.d0 = packet['d0']
    @user.d3 = packet['d3']
    @user.f = packet['f']
    @user.chat = parseInt(packet['c']) || 0
    @user.guest = true
    @user.pStr = ''
    @user.k = packet['k']
    @user.k3 = packet['k3']

    i = 0
    while i <= 20
      @user["p#{i}v"] = 0
      @user["m#{i}"] = 0
      @user.pStr += "p#{i}=\"" + @user["p#{i}v"] + "\" "
      i++

    @resetDetails(@user.id, (res) =>
      if !res
        @handler.send "<logout e=\"F036\" />"
        callback(false, "Reset details failed for user with id #{@user.id}")
        return

      @user.url = packet['h']
      @user.avatar = packet['a']

      @user.nickname = packet['n']
      @user.nickname = @user.nickname.split('##')

      if @user.nickname.length > 1
        @user.nickname[1] = parser.escape(@user.nickname[1])
        @user.nickname = @user.nickname.join('##')
      else
        @user.nickname = @user.nickname[0]

      @updateDetails(callback)
    )

  resetDetails: (userId, callback) ->
    database.exec("SELECT * FROM users WHERE id = '#{userId}' AND k = '#{@user.k}' AND k3 = '#{@user.k3}' LIMIT 1 ").then((data) =>
      if data.length < 1
        callback(false)
      else if data[0].username is 'unregistered'
        @user.guest = true

        callback(true)
      else
        user = data[0]

        @user.username = user['username']
        @user.guest = false
        @user.xats = user['xats']
        @user.days = Math.floor((user['days'] - math.time()) / 86400)
        @user.k2 = user['k2']
        @user.d1 = user['days']
        @user.d2 = user['d2']

        @user.dO = user['dO'] if @getPowers()

        callback(true)
    )

  updateDetails: (callback) ->
    if @user.id != 0
      database.exec("UPDATE users SET nickname = '#{@user.nickname}', avatar = '#{@user.avatar}', url = '#{@user.url}', remoteAddress = '#{@handler.socket.remoteAddress}' WHERE id = '#{@user.id}'").then((data) =>
        @user.authenticated = true

        callback(true, null)
      )
    else
      callback(false, "Failed to updateDetails for user #{@user.id}")

  getPowers: () ->
    if @user.days < 1
      return false


    return true

  logout: ->
    @send '<dup />'
    @user = {}
    @dispose()
