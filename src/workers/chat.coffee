database = require '../services/database'

parser = require '../utils/parser'
math = require '../utils/math'
builder = require '../utils/builder'
logger = new (require '../utils/logger')(name: 'Chat')

module.exports =
  getLink: (chat) -> global.Application.config.domain + '/room/' + chat

  joinRoom: ->
    return if @user.chat < 1

    @user.pool = @user.pool || 0

    database.exec('SELECT * FROM chats WHERE id = ? LIMIT 1', [@user.chat]).then((data) =>
      if @user.chat is 8
        @send '<i b=";=;=;=- Cant ;=" f="932" v="1" cb="0"  />'
        @send '<w v="0 0 1"  />'
        @send '<done  />'
        return

      @chat = data[0] if @chat is null

      return false if !@chat

      ## Push user to the room
      if typeof global.Server.rooms[@user.chat] isnt 'object'
        global.Server.rooms[@user.chat] = {}
      
      global.Server.rooms[@user.chat][@user.id] = @

      @chat.attached = try JSON.parse(@chat.attached) catch error then {}

      ## Chat settings and info
      ## r: 1 - (All main owner) / 2 - (All moderator) / 3 - (All member) / 4 (All owner)
      ## v: 1 - (Normal) / 3 - (w_VIP) / 4 - (w_ALLP) / other - (All unregistered)
      packet = builder.create('i')
      packet.append('b', "#{@chat.bg};=#{@chat.attached.name || ''};=#{@chat.attached.id || ''};=#{@chat.language};=#{@chat.radio};=#{@chat.button}")
      packet.append('f', '21233728')
      packet.append('v', '3')
      packet.append('cb', '2387')
      @send packet.compose()

      ## Chat group powers
      packet = builder.create('gp')
      packet.append('p', '0|0|1163220288|1079330064|20975876|269549572|16645|4210689|1|4194304|0|0|0|')
      packet.append('g180', "{'m':'','d':'','t':'','v':1}")
      packet.append('g256', "{'rnk':'8','dt':120,'rc':'1','v':1}")
      packet.append('g100', 'assistance,1lH2M4N,xatalert,1e7wfSx')
      packet.append('g114', "{'m':'Lobby','t':'Staff','rnk':'8','b':'Jail','brk':'8','v':1}")
      packet.append('g112', 'Welcome to the lobby! Visit assistance and help pages.')
      packet.append('g246', "{'rnk':'8','dt':30,'rt':'10','rc':'1','tg':1000,'v':1}")
      packet.append('g90', 'shit,faggot,slut,cum,nigga,niqqa,prostitute,ixat,azzhole,tits,dick,sex,fuk,fuc,thot')
      packet.append('g80', "{'mb':'11','ubn':'8','mbt':24,'ss':'8','rgd':'8','prm':'14','bge':'8','mxt':60,'sme':'11','dnc':'11','bdg':'11','yl':'10','rc':'10','p':'7','ka':'7'}")
      packet.append('g74', 'd,waiting,astonished,swt,crs,un,redface,evil,rolleyes,what,aghast,omg,smirk')
      packet.append('g106', 'c#sloth')
      @send packet.compose()

      ## Chat pools
      @send builder.create('w').append('v', "#{@user.pool} #{@chat.pool}").compose()

      ## Broadcast the current user
      packet = builder.create('u')
      packet.append('cb', '1443256921')
        .append('s', '1')
        .append('f', @user.f)
        .append('u', @user.id)
        .append('n', @user.nickname)
        .append('q', '3')
        .append('a', @user.avatar)
        .append('h', @user.url)
        .append('cb', '1443256921')
        .append('v', '0')

      if @user.registered
        packet.append('N', @user.username)
        packet.append('d0', @user.d0)
        packet.append('d2', @user.d2) if @user.d2
        packet.appendRaw(@user.pStr)

      @broadcast packet.compose()

      ## Room messages
      database.exec('SELECT * FROM (SELECT * FROM messages WHERE id = ? AND pool = ? ORDER BY time DESC LIMIT 15) sub ORDER BY time ASC LIMIT 0,15', [@user.chat, @user.pool]).then((data) =>
        offline = new Array()
        for message in data
          continue if global.Server.rooms[@user.chat][message.uid]?.pool is @user.pool

          packet = builder.create('o')
          packet.append('u', message.uid)
            .append('u', message.uid)
            .append('n', message.name)
            .append('a', message.avatar)
          packet.append('N', message.registered) if message.registered isnt 'unregistered'
          
          if offline.indexOf(message.uid) is -1
            @send packet.compose()
            offline.push(message.uid)

        for _, client of global.Server.rooms[@user.chat]
          continue if @user.id == client.id or @user.pool != client.user.pool

          user = client.user

          packet = builder.create('u')
          packet.append('cb', '1414865425')
          packet.append('s', '1')
          packet.append('f', user.f)
          packet.append('u', user.id)
          packet.append('q', '3')
          packet.append('n', user.nickname)
          packet.append('a', user.avatar)
          packet.append('h', user.url)
          packet.append('v', '0')

          if user.registered
            packet.append('N', user.username)
            packet.append('d0', user.d0)
            packet.append('d2', user.d2) if user.d2
            packet.appendRaw(user.pStr)

          @send packet.compose()

        data.forEach((message) =>
          packet = builder.create('m')
          packet.append('E', message.time)
            .append('u', message.uid)
            .append('t', message.message)
            .append('s', '1')

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

  sendMessage: (message) ->
    @broadcast builder.create('m').append('t', message).append('u', @user.id).compose()

    database.exec('INSERT INTO messages (id, uid, message, name, registered, avatar, time, pool) values (?, ?, ?, ?, ?, ?, ?, ?)', [@user.chat, @user.id, message, @user.nickname, @user.username || 'unregistered', @user.avatar, math.time(), @user.pool]).then((data) ->
      logger.log logger.level.DEBUG, 'New message sent'
    ).catch((err) -> logger.log logger.level.ERROR, 'Failed to send a message to the database', err)
