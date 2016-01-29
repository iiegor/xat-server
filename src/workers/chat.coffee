database = require "../services/database"

parser = require "../utils/parser"
math = require "../utils/math"
builder = require "../utils/builder"
logger = new (require "../utils/logger")(name: 'Chat')

module.exports =
  joinRoom: ->
    return if @user.chat < 1 or isNaN(@user.chat) is true

    database.exec("SELECT * FROM chats WHERE id = '#{@user.chat}' LIMIT 1 ").then((data) =>
      if @user.chat is 8
        @send '<i b=";=;=;=- Cant ;=" f="932" v="1" cb="0"  />'
        @send '<w v="0 0 1"  />'
        @send '<done  />'
        return

      @chat = data[0] if @chat is null

      return false if !@chat

      ## Push the user to the rooms object
      if typeof global.Server.rooms[@user.chat] is 'object'
        global.Server.rooms[@user.chat].push @user.id
      else
        global.Server.rooms[@user.chat] = new Array @user.id

      @chat.attached = try JSON.parse(@chat.attached) catch error then {}
      @chat.onPool = @chat.onPool || 0

      ## Chat settings and info
      packet = builder.create('i')
      packet.append('b', "#{@chat.bg};=#{@chat.attached.name||''};=#{@chat.attached.id||''};=#{@chat.language};=#{@chat.radio};=#{@chat.button}")
      packet.append('f', '21233728')
      packet.append('v', '1')
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
      @send builder.create('w').append('v', "#{@chat.onPool} #{@chat.pool}").compose()

      ## Fake user for testing (send here room users)
      # f:
      # 169 - main owner
      # 170 - mod
      # 171 - member
      # 172 - owner
      # @send '<u cb="1414865425" s="1" f="169" p0="1979711487" p1="2147475455" p2="2147483647" p3="2147483647" p4="2113929211" p5="2147483647" p6="2147352575" p7="2147483647" p8="2147483647" p9="8372223" u="42" d0="151535720" q="3" N="xat" n="server(glow#02000a#r)(hat#ht)##testing..#02000a#r" a="xatwebs.co/test.png" h="" v="0"  />'

      ## Send connected users to client
      for userId in global.Server.rooms[@user.chat]
        if userId is @user.id or !global.Server.clients[userId]
          break

        user = global.Server.clients[userId]
        
        packet = builder.create('o')
        packet.append('u', user.id)
        packet.append('d0', user.d0)
        packet.append('q', '1')
        packet.append('N', user.username)
        packet.append('n', user.nickname)
        packet.append('a', user.avatar)
        packet.append('h', user.url)
        packet.append('v', '1')

        @send packet.compose()

      ## Send 
      @send '<o u="265826731" q="1" n="Returns" N="iegor" a="147" h="" v="1"  />'

      ## Broadcast the current user
      ## NOTE: Maybe this needs to be sent more earlier
      username = if not @user.guest and @user.username then "N=\"#{@user.username}\"" else ''
      @broadcast "<u cb=\"1443256921\" s=\"1\" rank=\"1\" f=\"#{@user.f}\" #{@user.pStr} u=\"#{@user.id}\" d0=\"#{@user.d0}\" d2=\"#{@user.d2}\" q=\"3\" #{username} n=\"#{@user.nickname}\" a=\"#{@user.avatar}\" h=\"#{@user.url}\" v=\"0\"  />\0"

      ## Scroll message
      @send builder.create('m').append('t', "/s#{@chat.sc}").append('d', '1010208').compose()

      ## Room messages
      database.exec("SELECT * FROM (SELECT * FROM messages WHERE id='#{@user.chat}' AND pool='#{@chat.onPool}' ORDER BY time DESC LIMIT 15) sub ORDER BY time ASC LIMIT 0,15").then((data) =>
        data.forEach((message) => @send "<m t=\"#{message.message}\" u=\"#{message.uid}\"  />")

        ## Done packet
        @send '<done  />'
      )
    )

  sendMessage: (user, message) ->
    @broadcast(builder.create('m').append('t', message).append('u', user).compose())

    database.exec("INSERT INTO messages (id, uid, message, name, registered, avatar, time, pool) values ('#{@user.chat}', '#{@user.id}', '#{message}', '#{@user.nickname}', '#{@user.username||'unregistered'}', '#{@user.avatar}', '#{math.time()}', '#{@chat.onPool}')").then((data) ->
      logger.log logger.level.DEBUG, 'New message sent'
    ).catch((err) -> logger.log logger.level.ERROR, 'Failed to send a message to the database', err)
