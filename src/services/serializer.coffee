crypto = require "../util/crypto.coffee"
math = require "../util/math.coffee"

module.exports =
  packet: (handshake, packet) ->
    loginKey = math.random(10000000, 99999999)
    loginShift = math.random(2, 5)
    loginTime = math.time()

    handshake.send "<y i=\"#{loginKey}\" c=\"12\" p=\"100_100_5_100\" />"
