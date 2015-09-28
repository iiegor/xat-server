parser = require "../utils/parser"
math = require "../utils/math"
logger = require "../utils/logger"

Authentication = require "../workers/authentication"
Chat = require "../workers/chat"
Commander = require "../workers/commander"

{EventEmitter} = require 'events'
_ = require 'underscore'

module.exports =
class Handler
  _.extend @prototype, EventEmitter.prototype

  ###
  Section: Properties
  ###
  logger: new logger(name: 'Handler')
  user: {}
  chat: null

  ###
  Section: Construction
  ###
  constructor: (@socket) ->

  ###
  Section: Private
  ###
  read: (packet) ->
    @logger.log @logger.level.DEBUG, "-> #{packet}"

    packetTag = parser.getTagName(packet)

    # TODO: Kick when the user is spamming packets
    return if packetTag is null

    switch packetTag
      when "policy-file-request"
        @send "<?xml version=\"1.0\"?><!DOCTYPE cross-domain-policy SYSTEM \"http://www.adobe.com/xml/dtds/cross-domain-policy.dtd\"><cross-domain-policy><site-control permitted-cross-domain-policies=\"master-only\"/>#{global.Application.config.allow}</cross-domain-policy>\0"          
      when "y"
        ###
        @spec <y r="1" v="0" u="USER_ID(int)" />
        ###
        loginKey = math.random(10000000, 99999999)
        loginShift = math.random(2, 5)
        loginTime = math.time()

        @send "<y i=\"#{loginKey}\" c=\"12\" p=\"100_100_5_102\" />"

        # If the remote address already exists close the OLD socket
        # NOTE: Probably doing this non-blocking will be better
        for client in global.Server.clients
          return if client is @socket

          client.write '<dup />\0' if client.remoteAddress is @socket.remoteAddress
      when "j2"
        ###
        Authenticate the client and join room
        @spec <j2 cb="0" l5="4288326302" l4="1400" l3="1267" l2="0" q="1" y="72226157" k="f13cee2b165605b4e400" k3="0" p="0" c="1" f="1" u="USER_ID(int)" d0="0" n="USERNAME(str)" a="91" h="" v="1" />
        ###
        Authentication.process(@, packet, (res) =>
          Chat.joinRoom(@, @user.chat) if res
        )
      when "m"
        ###
        Send message
        @spec <m t="MESSAGE(str)" u="USER_ID(int)" />
        ###
        user = parser.getAttribute(packet, 'u')
        msg = parser.getAttribute(packet, 't')

        # TODO: Don't process command messages
        Chat.sendMessage(@, user, msg)
        Commander.process(@, user, msg)
      when "z"
        ###
        User profile
        @spec <z d="USER_ID_PROFILE(int)" u="USER_ID_ORIGIN(int)" t="TYPE(str)" />
        ###
        userProfile = parser.getAttribute(packet, 'd')
        userOrigin = parser.getAttribute(packet, 'u')
        type = parser.getAttribute(packet, 't')

        # TODO: Move this to a new worker?
        if type is '/l'
          room = "t=\"/a_Nofollow\"" # t=\"/a_on GROUP\"
          @send "<z b=\"1\" d=\"#{@user.id}\" u=\"#{userProfile}\" #{room} po=\"0\" p0=\"2013264863\" p1=\"2147483647\" p2=\"4294836215\" x=\"12\" y=\"13\" q=\"3\" N=\"USERNAME\" n=\"NICKNAME\" a=\"1\" h=\"http://google.com\" v=\"2\" />"
        else if type is '/a'
          return
        else
          @send "<z u=\"#{@user.id}\" t=\"#{type}\" s=\"#{parser.getAttribute(packet, 's')}\" d=\"#{userProfile}\" />"
      else
        if packetTag.indexOf('w') is 0
          ###
          Room pools
          @spec <w v="ACTUAL_POOL(int) POOLS(int,int..)"  />
          ###
          @chat.onPool = packetTag.split('w')[1]
          Chat.joinRoom(@, @user.chat)
        else
          # NOTE: In a future we can emit a message with the unrecognized packet so a plugin will be able to handle it.
          @logger.log @logger.level.ERROR, "Unrecognized packet by the server!", packetTag

  send: (packet) ->
    @socket.write "#{packet}\0"

    # Debug
    @logger.log(@logger.level.DEBUG, "-> Sent: #{packet}")

  broadcast: (packet, sender={}) ->
    for client in global.Server.clients
      return if client is sender

      client.write "#{packet}\0"
  
  dispose: ->
    @socket.end()
    @socket.destroy()
