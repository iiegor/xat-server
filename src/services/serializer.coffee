crypto = require "../util/crypto"
math = require "../util/math"
logger = require "../util/logger"

module.exports =
  logger: new logger(name: 'Serializer')

  packet: (handshake, packet) ->
    packetTag = crypto.getTagName(packet)

    switch packetTag
      when "y"
        loginKey = math.random(10000000, 99999999)
        loginShift = math.random(2, 5)
        loginTime = math.time()

        handshake.send "<y i=\"#{loginKey}\" c=\"12\" p=\"100_100_5_100\" />"
      when "j2"
        # Authenticate the client
        (require "../workers/authentication").process(packet)
      else
        @logger.log @logger.level.ERROR, "Unrecognized packet by the server!", packetTag
