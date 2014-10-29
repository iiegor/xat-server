eventHandler = require "./events"

module.exports =
    pool: {}
    count: null

    add: (socket) ->
      # Register
      connection = new eventHandler(socket, @count++)
      @pool[socket] = connection

      console.log 'new connection from ' + socket.remoteAddress
