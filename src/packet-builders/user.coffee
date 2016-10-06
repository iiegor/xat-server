profile = require '../workers/profile'

expandPacket = (packet, user, fillType) ->
  packet.append('u', user.id)
    .append('n', user.nickname)
    .append('a', user.avatar)
    .append('h', user.url)
    .append('q', user.q)
    .append('v', '0')
    .append('cb', '0')

  packet.append('f', user.f) if user.f > 0

  if user.registered
    packet.append('N', user.username)
    packet.append('d0', user.d0)
    packet.append('d2', user.d2) if user.d2?
    packet.appendRaw(user.pStr)

# This method works assuming user with id=userId is online.
# This method is sync.
expandPacketWithOnlineUserData = (packet, client, fillType) ->
    expandPacket(packet, client.user, fillType)

expandPacketWithUserData = (packet, userId, fillType) ->
  new Promise (resolve, reject) ->
    client = global.Server.getClientById userId
    if client?
      expandPacketWithOnlineUserData(packet, client, fillType)
      resolve(packet)
    else
      profile.getById(userId).then((data) ->
        reject() if data.length < 1
        expandPacket(packet, data[0], fillType)
        resolve(packet)
      ).catch reject

module.exports =
  expandPacketWithOnlineUserData: expandPacketWithOnlineUserData
