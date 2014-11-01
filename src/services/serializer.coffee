crypto = require "../util/crypto"
math = require "../util/math"
logger = require "../util/logger"

Authentication = require "../workers/authentication"
Pool = require "../workers/pool"

module.exports =
  logger: new logger(name: 'Serializer')

  packet: (handshake, packet) ->
    packetTag = crypto.getTagName(packet)

    return if packetTag is null

    switch packetTag
      when "y"
        loginKey = math.random(10000000, 99999999)
        loginShift = math.random(2, 5)
        loginTime = math.time()

        handshake.send "<y i=\"#{loginKey}\" c=\"12\" p=\"100_100_5_102\" />"
      when "j2"
        # Authenticate the client
        Authentication.process(handshake, packet)
      else
        if packetTag.indexOf('w') is 0
          # Pool packet
          @logger.log @logger.level.ERROR, "The pool packet is in development!", packetTag

          # Pool packet structure
          # <w v="3 0 1 2 3"  /> -> this changes the pool order, we need to reconnect the user, send the <i> and <gp> packet and then the pool changed. Finally request only the actual pool messages and set the user actual pool.
          Pool.switch(handshake, packetTag.split('w')[1])
        else
          @logger.log @logger.level.ERROR, "Unrecognized packet by the server!", packetTag
