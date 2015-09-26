parser = require "../utils/parser"
math = require "../utils/math"
logger = require "../utils/logger"

Authentication = require "../workers/authentication"
Chat = require "../workers/chat"

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
    @handleEvents()

  ###
  Section: Private
  ###
  read: (packet) ->
    # Debug
    @logger.log @logger.level.DEBUG, "-> #{packet}"

    packetTag = parser.getTagName(packet)

    return if packetTag is null

    switch packetTag
      when "policy-file-request"
        @send "<?xml version=\"1.0\"?><!DOCTYPE cross-domain-policy SYSTEM \"http://www.adobe.com/xml/dtds/cross-domain-policy.dtd\"><cross-domain-policy><site-control permitted-cross-domain-policies=\"master-only\"/>#{global.Application.config.allow}</cross-domain-policy>\0"
        
        # If the remote address already exists close the OLD socket
        for client in global.Server.clients
          client.write '<dup />\0' if client.remoteAddress is @socket.remoteAddress
      when "y"
        loginKey = math.random(10000000, 99999999)
        loginShift = math.random(2, 5)
        loginTime = math.time()

        @send "<y i=\"#{loginKey}\" c=\"12\" p=\"100_100_5_102\" />"
      when "j2"
        # Authenticate the client and join room
        Chat.joinRoom(@, @user.chat) if Authentication.process(@, packet) == true
      when "m"
        # Send message
        msg = parser.getAttribute(packet, 't')
      else
        if packetTag.indexOf('w') is 0
          # Pool packet
          @logger.log @logger.level.ERROR, "The pool packet is in development!", packetTag

          # Pool packet structure
          # <w v="2 0 1 2"  /> -> this changes the pool order, we need to reconnect the user, send the <i> and <gp> packet and then the pool changed. Finally request only the actual pool messages and set the user actual pool.
          @chat.onPool = packetTag.split('w')[1]
          Chat.joinRoom(@, @user.chat)
        else
          @logger.log @logger.level.ERROR, "Unrecognized packet by the server!", packetTag

  handleEvents: ->
    @socket.on 'end', => @user.authenticated = false

  send: (packet) ->
    @socket.write "#{packet}\0"

    # Debug
    @logger.log(@logger.level.DEBUG, "-> Sent: #{packet}")

  broadcast: (packet, sender={}) ->
    for client in global.Server.clients
      return if client is sender

      client.write "#{packet}\0"

  getSocket: -> @socket
  
  dispose: ->
    @socket.end()
    @socket.destroy()
