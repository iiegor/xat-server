logger = require "./util/logger"
socket = require "./services/sockets"
{EventEmitter} = require 'events'

module.exports =
  class Application extends EventEmitter
    name: 'Application'

    constructor: ->
      # Register
      @Logger = new logger(this)
      @Configuration = require "./config/environment"
      @Sockets = new socket(@Configuration['port'])

      # Bootstrap
      @bootstrap()

    bootstrap: ->
      @Logger.log(@Logger.level.INFO, "Starting the server in #{@Configuration['env']} at port #{@Configuration['port']}...")

      if @Sockets.listen()
        @Logger.log(@Logger.level.INFO, "Server started and waiting for new connections!")

        @handleEvents()
      else
        @Logger.log(@Logger.level.ERROR, "Failed to start the server!", "Exception from @Sockets.listen()")
        @__dispose()

    handleEvents: ->
      # Registers all basic events of the application
      @on 'application:quit', -> @__quit()

    __quit: ->
      # Exit killing all processes (for the future visual interface)

    __dispose: ->
      # Exit with success code
      process.exit(0)
