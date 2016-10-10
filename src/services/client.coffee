parser = require '../utils/parser'
math = require '../utils/math'
logger = require '../utils/logger'
builder = require '../utils/builder'
userBuilder = require '../packet-builders/user'

User = require '../workers/user'
Chat = require '../workers/chat'
Commander = require '../workers/commander'
Profile = require '../workers/profile'

module.exports =
class Client
  ###
  Section: Properties
  ###
  id: null
  socket: null
  logger: new logger(name: 'Client')

  ###
  Section: Construction
  ###
  constructor: ->
    @user = {}
    @chat = null

  ###
  Section: Private
  ###
  read: (packet) ->
    @logger.log @logger.level.DEBUG, "-> #{packet}"

    packetTag = parser.getTagName(packet)

    # TODO:
    #  Kick when the user is spamming packets
    #  Implement <idle />
    return if packetTag is null

    isSlash = parser.getAttribute(packet, 't')?.startsWith('/') || false
    type = parser.getAttribute(packet, 't')

    switch
      when packetTag == "policy-file-request"
        @send "<?xml version=\"1.0\"?><!DOCTYPE cross-domain-policy SYSTEM \"http://www.adobe.com/xml/dtds/cross-domain-policy.dtd\"><cross-domain-policy><site-control permitted-cross-domain-policies=\"master-only\"/>#{global.Application.config.allow}</cross-domain-policy>\0"
      when packetTag == "y"
        ###
        @spec <y r="1" v="0" u="USER_ID(int)" />
        ###
        loginKey = math.random(10000000, 99999999)
        loginShift = math.random(2, 5)
        loginTime = math.time()

        @send(builder.create('y')
          .append('i', loginKey)
          .append('c', loginTime)
          .append('p', '100_100_5_102')
          .compose())
      when packetTag == "j2"
        ###
        Authenticate the client and join room
        @spec <j2 cb="0" l5="4288326302" l4="1400" l3="1267" l2="0" q="1" y="72226157" k="f13cee2b165605b4e400" k3="0" p="0" c="1" f="1" u="USER_ID(int)" d0="0" n="USERNAME(str)" a="91" h="" v="1" />
        ###
        User.process(@, packet).then(() =>
          # Delete user with fake id
          delete global.Server.clients[@id]

          # Close opened connection
          dupUser = global.Server.rooms[@user.chat]?[@user.id]

          if dupUser
            dupUser.send '<dup />'
            dupUser.socket.end()

          @id = @user.id

          pool = parseInt parser.getAttribute(packet, 'p')

          Chat.joinRoom.call(@, pool)
        ).catch((err) => @logger.log @logger.level.ERROR, err, null)
      when packetTag == "v"
        ###
        Authenticate through chat.swf
        @spec <v p="PASSWORD(str)" n="USERNAME(str)" />
        ###
        name = parser.getAttribute(packet, 'n')
        pw = parser.getAttribute(packet, 'p')

        User.login(@, name, pw)
      when packetTag == "m"
        ###
        Send message
        @spec <m t="MESSAGE(str)" u="USER_ID(int)" />
        ###
        return if not @maySendMessages()

        user = parser.getAttribute(packet, 'u')
        msg = parser.getAttribute(packet, 't')

        if msg.charAt(0) is Commander.identifier
          Commander.process(@, @user.id, msg)
        else if not isSlash
          Chat.sendMessage.call(@, @user.id, msg)

      when packetTag == "c" and type is "/K2"
        return if not @maySendMessages()

        @setSuper()
      when packetTag == "c"
        ###
        Save user profile data
        @spec <c u="2" t="/b USER_ID(int),UNKNOWN(int),,USERNAME(str),AVATAR(str),HOME(str),0,0,0,0....." />
        ###
        return if not @user.authenicated or @user.guest

        type = parser.getAttribute(packet, 't')

        return if type is '/KEEPALIVE'
        
        @logger.log @logger.level.ERROR, "Unhandled user data update packet", null
      when packetTag == "z" and isSlash
        ###
        User profile
        @spec <z d="USER_ID_PROFILE(int)" u="USER_ID_ORIGIN(int)" t="TYPE(str)" />
        ###
        return if not @maySendMessages()

        userProfileId = parseInt(parser.getAttribute(packet, 'd')) || null
        userProfile = global.Server.getClientById( userProfileId )?.user || null
        userOrigin = parseInt(parser.getAttribute(packet, 'u')?.split('_')[0])
        type = parser.getAttribute(packet, 't') || ''

        if userOrigin != @user.id or userProfileId == null
          @logger.log @logger.level.ERROR, "User #{@user.id} 'z'-packet security violation", null
          return

        if type is '/l' and userProfile != null
          ## can't just resend packet because of trailing '\0'
          packet = builder.create('z')
            .append('d', userProfileId)
            .append('u', userOrigin)
            .append('t', '/l')
          @routeZ(packet.compose(), userProfileId)
        else if type.substr(0, 2) is '/a' and userProfile != null
          packet = builder.create('z')

          status = type.substr(2)

          if status[0] == '_'
            if status.substr(1) == 'NF'
              status = '/a_NF'
            else
              status = '/a_'
          else
            status = "/a#{Chat.getChatLink @user.chat}"

          userBuilder.expandPacketWithOnlineUserData packet, @

          packet.append('t', status)
          # .append('b', '1') # what does 'b' means?
            .append('d', userProfileId)
            .append('x', @user.xats || 0)
            .append('y', @user.days || 0)

          @routeZ(packet.compose(), userProfileId)
        else if type is '/l' or type.substr(0, 2) is '/a'
          Profile.getById(userProfileId)
            .then((data) =>
              @logger.log @logger.level.ERROR, "Unhandled null userProfile", null
            )
            .catch((err) => @logger.log @logger.level.ERROR, 'Can not fetch user profile data', err)
      when packetTag == "p" or packetTag == "z"
        ###
        Private chat
        @spec <p u="FROM-USER_ID" t="MESSAGE" [s="2" d="FROM-USER_ID"] /> - user receives
        @spec <p u="TO-USER_ID" t="MESSAGE" /> - user sends
        @spec <p u="TO-USER_ID" t="MESSAGE" s="2" d="FROM-USER_ID" > - user sends
        @spec <z u="FROM-USER_ID" t="MESSAGE" [s="2"] d="TO-USER_ID" /> - user receives and sends
        ###
        ###
        Private messages now more xat compatible. But is it required?
        It looks too complicated and redudantly.
        ###
        return if not @maySendMessages()

        toID = parser.getAttribute(packet, if packetTag == 'p' then 'u' else 'd')?.split('_')[0]
        fromID = @user.id
        message = parser.getAttribute(packet, 't')
        s = parseInt(parser.getAttribute(packet, 's')) || 0

        msg = builder.create(packetTag).append('E', "#{Date.now()}").append('u', fromID).append('t', message)

        if s is 2
          msg.append('s', s)
        if packetTag == 'z' or s is 2
          msg.append('d', if packetTag == 'z' then toID else fromID)

        msg = msg.compose()

        if packetTag == 'p'
          global.Server.rooms[@user.chat]?[toID]?.send(msg)
        else
          @routeZ(msg, toID)

      when packetTag.indexOf('w') is 0
        ###
        Room pools
        @spec <w v="ACTUAL_POOL(int) POOLS(int,int..)"  />
        ###
        ###
        Change pool
        @spec <wNEWPOOL />
        ###
        Chat.changePool.call(@, parseInt packetTag.substr(1))
      else
        @logger.log @logger.level.ERROR, "Unrecognized packet by the server!", packetTag

  send: (packet) ->
    @socket.write "#{packet}\0"

    # Debug
    @logger.log @logger.level.DEBUG, "-> Sent: #{packet}"

  routeZ: (packet, toID) ->
    if (rec = global.Server.rooms[@user.chat]?[toID])
      rec.send(packet)
    else if (rec = global.Server.getClientById(toID))
      rec.send(packet)

  setSuper: ->
    ###
    NotOnSuper message
    @spec <k u="USER_ID" i="UNKNOWN (but the same as 'k' in 'y'-message)" />

    Xat behavior:

    cases:
    user A appears in chat 1 - now super is A on chat 1
    user A appears in chat 2 - now super is A on chat 2
    user A sends '/K2' from chat 1 - now super is A on chat 1
    .. and so on
    if super is A on chat 2 and user A logout from chat 2, then there is
    no super for A, even if he is still in chat 1

    What is 'super'? In case sender and receiver not in the same chat,
    'z' message routes sends to handler, which is super.
    If no super, message disappears.
    ###
    onsuper = global.Server.getClientById(@user.id)
    onsuper?.send(builder.create('k').append('u', @user.id).append('i', '32699').compose())

    global.Server.clients[@user.id] = @

  maySendMessages: ->
    return @user.authenticated and not @user.guest

  broadcast: (packet) ->
    for _, client of global.Server.rooms[@user.chat]
      continue if @user.id == client.user.id or @chat.onPool != client.chat.onPool

      console.log "Broadcasting from #{@user.id} to #{client.id}"

      client.send packet

    # Debug
    @logger.log @logger.level.DEBUG, "-> Broadcasted: #{packet}"

  setSocket: (socket) ->
    @socket = socket

    @socket.on 'data', (buffer) =>
      @read buffer.toString('utf8')

  dispose: ->
    @socket.end()
    @socket.destroy()
