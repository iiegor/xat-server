module.exports =
  switch: (handshake, number) ->
    handshake.send "<w v=\"#{number} 0 1 2\"  />"
    # handshake.send "<m t=\"Messages of the pool!\" u=\"1503481895\" />"
