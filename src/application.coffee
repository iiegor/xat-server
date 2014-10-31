logger = require "./util/logger"
socket = require "./services/sockets"
database = require "./services/database"
{EventEmitter} = require 'events'

module.exports =
  class Application extends EventEmitter
    name: 'Application'

    constructor: ->
      # Register
      @Logger = new logger(this)
      @Configuration = require "./config/environment"
      @Sockets = new socket(@Configuration['port'])
      @Database = new database(@, require "./config/database")

      # Bootstrap
      @bootstrap()

    bootstrap: ->
      Application = this
      @Logger.log(@Logger.level.INFO, "Starting the server in #{@Configuration['env']} at port #{@Configuration['port']}...")

      @Sockets.listen (status) ->
        if status is true
          Application.Logger.log(Application.Logger.level.INFO, "Server started and waiting for new connections!")

          Application.handleEvents()
        else
          Application.Logger.log(Application.Logger.level.ERROR, "Failed to start the server!", "Exception from @Sockets.listen()")
          Application.__dispose()

    handleEvents: ->
      # Registers all basic events of the application
      @on 'application:dispose', -> @__dispose()

    __dispose: ->
      # Exit with success code
      process.exit(0)
