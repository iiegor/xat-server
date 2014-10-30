handshake = require "./handshake"

module.exports =
    pool: {}
    count: 0

    add: (socket) ->
      # Register
      connection = new handshake(@, socket, @count++)
      @pool[socket] = connection

    close: (socket) ->
      delete @pool[socket]

      socket.end()
      socket.destroy()
      socket = null

      @count--
