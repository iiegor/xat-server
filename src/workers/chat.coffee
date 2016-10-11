database = require '../services/database'

parser = require '../utils/parser'
math = require '../utils/math'
builder = require '../utils/builder'
logger = new (require '../utils/logger')(name: 'Chat')
userBuilder = require '../packet-builders/user'
messageBuilder = require '../packet-builders/message'
chatBuilder = require '../packet-builders/chat'

Rank = require '../structures/rank'

joinRoom = (poolId, rankPass) ->
  return if @user.chat < 1

  database.execJoin('SELECT * FROM chats LEFT JOIN `ranks` ON (`chats`.id = `ranks`.chatid and `ranks`.userid = ?) WHERE `chats`.id = ? LIMIT 1', [@user.id, @user.chat]).then((data) =>
    if @user.chat is 8
      @send '<i b=";=;=;=- Cant ;=" f="932" v="1" cb="0"  />'
      @send '<w v="0 0 1"  />'
      @send '<done  />'
      return

    @chat = data[0].chats if @chat is null

    return false if !@chat

    ## Push the user to the rooms object
    if typeof global.Server.rooms[@user.chat] isnt 'object'
      global.Server.rooms[@user.chat] = {}

    global.Server.rooms[@user.chat][@user.id] = @

    @chat.attached = try JSON.parse(@chat.attached) catch error then {}
    ## if poolId undefined or 0 - should choose @chat.onPool, according to xat's protocol
    ## However, real implementation is more complicated
    ## 0 pool is default pool. In case there are more than one
    ## regular pool (regular pools appear when there are too many users in chat),
    ## chat engine should switch to less populated pool.
    @chat.onPool = poolId || @chat.onPool || 0

    @chat.rank = Rank.fromNumber(data[0].ranks.f & 7 || 0)
    @chat.rank = Rank.MAINOWNER if @chat.pass == rankPass
    @user.f = @chat.rank.toNumber() & 7

    @setSuper()

    @send chatBuilder.buildMeta(@).compose()
    @send chatBuilder.buildPowers(@).compose()

    ## Chat pools
    @send builder.create('w').append('v', "#{@chat.onPool} #{@chat.pool}").compose()

    ## Broadcast the current user
    @broadcast userBuilder.buildU(@).compose()

    ## Room messages
    database.exec('SELECT * FROM (SELECT * FROM messages WHERE id = ? AND pool = ? ORDER BY time DESC LIMIT 15) sub ORDER BY time ASC LIMIT 0,15', [ @user.chat, @chat.onPool ]).then((data) =>
      offline = new Array()
      for message in data
        continue if global.Server.rooms[@user.chat][message.uid]?.chat.onPool is @chat.onPool

        
        if offline.indexOf(message.uid) is -1
          packet = builder.create('o')
          packet.append('u', message.uid)
            .append('u', message.uid)
            .append('n', message.name)
            .append('a', message.avatar)
            .append('s', 1)
          packet.append('N', message.registered) if message.registered isnt 'unregistered'

          @send packet.compose()
          offline.push(message.uid)

      for _, client of global.Server.rooms[@user.chat]
        continue if client.id is @user.id  or client.chat.onPool isnt @chat.onPool

        packet = userBuilder.buildU(@)
        packet.append('s', '1')

        @send packet.compose()

      data.forEach((message) =>
        packet = messageBuilder.buildOldMain message

        @send packet.compose()
      )

      ## Scroll message
      # database.exec('SELECT * FROM messages WHERE id = ? AND SUBSTRING(message FROM 0 FOR 2) ORDER BY time DESC LIMIT 1', [ @user.chat ]).then((data) ->
      @send builder.create('m').append('t', "/s#{@chat.sc}").append('d', '123').compose()

      ## Done packet
      @send '<done  />'
      # )
    )
  )

changePool = (poolId) ->
  @broadcast builder.create('l').append('u', @user.id).compose()
  @chat.onPool = poolId
  joinRoom.call(@)

module.exports =
  getLink: (chat) -> global.Application.config.domain + '/room/' + chat
  joinRoom: joinRoom
  changePool: changePool

  banUser: (options) ->
    new Promise (resolve, reject) ->
      duration = parseInt options?.duration
      userId = options?.userId

      return reject() if isNaN(duration) or duration < 0
      return reject() if @chat.rank.compareTo(Rank.MODERATOR) < 0
      return reject() if @chat.rank.compareTo(Rank.MODERATOR) == 0 and (duration > 6 * 3600 or duration == 0)

      database.exec 'SELECT f FROM `ranks` WHERE `userid` = ?', [userId], (err, data) ->
        return reject(err) if err?
        return reject() if data[0]?.f? and @chat.rank.compareTo(Rank.fromNumber(data[0].f & 7))

    throw new Error('Not implemented')

  makeUser: (options) ->
    new Promise (resolve, reject) =>
      userId = options?.userId
      duration = options?.duration
      newrank = Rank.fromString options?.rank
      chatId = @chat.id

      return reject('User can\'t change ranks') if @chat.rank.compareTo(Rank.MODERATOR) < 0
      return reject('Moderator\'s rank is too low for target rank') if newrank.compareTo(@chat.rank) >= 0
      #return false if @chat.rank.compareTo(Rank.MODERATOR) == 0 and duration > 3600 * 6

      destination = global.Server.rooms[chatId][userId]
      return reject('Target user\'s rank is too high') if destination?.chat.rank? and @chat.rank.compareTo(destination.chat.rank) <= 0

      database.exec('SELECT f FROM `ranks` WHERE userid = ? AND chatid = ? LIMIT 1', [userId, chatId]).then((data) =>
        return reject('Target user\'s rank is too high') if data[0]?.f? and @chat.rank.compareTo(Rank.fromNumber(data[0].f & 7)) <= 0

        if data[0]?
          database.exec('UPDATE `ranks` SET `f` = ? WHERE userid = ? AND chatid = ?', [newrank.toNumber(), userId, chatId])
        else
          database.exec('INSERT INTO `ranks` (`userid`, `chatid`, `f`) VALUES(?, ?, ?)', [userId, chatId, newrank.toNumber()])
      ).then((data) =>
        packet = builder.create('m')
          .append('u', @user.id)
          .append('d', userId)
          .append('t', '/m')
          .append('p', newrank.toString())
          .compose()
        @broadcast packet
        @send packet

        if destination?
          destination.chat.rank = newrank
          destination.user.f = destination.user.f & ~7 | destination.chat.rank.toNumber()

          packet = builder.create('c')
            .append('u', userId)
            .append('t', "/m")
          destination.send packet.compose()

          destination.broadcast userBuilder.buildU(destination).compose()
          destination.send chatBuilder.buildMeta(destination).compose()
          destination.send chatBuilder.buildPowers(destination).compose()

        resolve()
      ).catch(reject)

  sendMessage: (user, message) ->
    time = math.time()

    database.exec('INSERT INTO messages (id, uid, message, name, registered, avatar, time, pool) values (?, ?, ?, ?, ?, ?, ?, ?)', [ @user.chat, @user.id, message, @user.nickname, @user.username || 'unregistered', @user.avatar, time, @chat.onPool ]).then((data) =>

      packet = messageBuilder.buildNewMain(
        message: message
        client: @
        time: time
        messageId: data.insertId
      )

      @broadcast packet.compose()
      logger.log logger.level.DEBUG, 'New message sent'
    ).catch((err) -> logger.log logger.level.ERROR, 'Failed to send a message to the database', err)
