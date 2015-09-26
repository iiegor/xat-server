module.exports =
  switch: (handler, number) ->
    handler.send "<w v=\"#{number} #{handler.chat.pool}\"  />"
    # handler.send "<m t=\"Messages of the pool!\" u=\"1503481895\" />"
