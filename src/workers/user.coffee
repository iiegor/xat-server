logger = new (require "../utils/logger")(name: 'User')
parser = require "../utils/parser"
math = require "../utils/math"
database = require "../services/database"
builder = require "../utils/builder"

module.exports =
  login: (name, pw) ->
    # TODO:
    #   Fix user days packet attr.
    #   Complete all the attrs with real data.
    # INFO:
    #   d2 - married id
    database.exec('SELECT * FROM users WHERE username = ? AND loginKey = ? LIMIT 1', [name, pw]).then((data) =>
      return if data.length < 1

      user = data[0]
      v = builder.create('v')
      v.append('d1', user.days) if parseInt(user.days) > 0
      v.append('d2', user.d2) if parseInt(user.d2) > 0

      v.append('d4', 2209282)
        .append('d5', '6292512')
        .append('d6', '2097193')
        .append('d9', '262144')
        .append('d0', user.d0)
        .append('d3', user.d3)
        .append('dx', user.xats)
        .append('dt', Date.now())
        .append('i', user.id)
        .append('n', user.username)
        .append('k2', user.k2)
        .append('k3', user.k3)
        .append('k1', user.k)

      @send v.compose()
      @send builder.create('c').append('t', '/bd').compose()
      @send builder.create('c').append('t', "/b #{user.id},5,,#{user.nickname},#{user.avatar},#{user.url},0,0,0,0,0,0,0,0,0,0,0,0,0,0").compose()
      @send builder.create('c').append('t', 'bf').compose()
      @send builder.create('ldone').compose()
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
        @handler.send builder.create('logout').append('e', 'F036').compose()
        @handler.dispose()
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
    database.exec('SELECT * FROM users WHERE id = ? AND k = ? AND k3 = ? LIMIT 1', [userId, @user.k, @user.k3]).then((data) =>
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
        @user.d0 = user['d0']
        @user.d1 = user['days']
        @user.d2 = user['d2']
        @user.d3 = user['d3']
        @user.dt = user['dt']

        @user.dO = user['dO'] if @getPowers()

        callback(true)
    )

  updateDetails: (callback) ->
    if @user.id != 0
      database.exec('UPDATE users SET nickname = ?, avatar = ?, url = ?, remoteAddress = ? WHERE id = ?', [@user.nickname, @user.avatar, @user.url, @handler.socket.remoteAddress, @user.id]).then((data) =>
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
    @send builder.create('dup').compose()
    @user = {}
    @dispose()
