module.exports =
  switch: (handshake, number) ->
    handshake.send "<w v=\"#{number} 0 1 2\"  />"
