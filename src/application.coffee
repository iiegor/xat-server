logger = require "./util/logger"
socket = require "./services/sockets"
database = require "./services/database"
{EventEmitter} = require 'events'

module.exports =
  class Application extends EventEmitter
    name: 'Application'

    Logger: new logger(this)
    Configuration: require "./config/environment"

    constructor: ->
      @Logger.log(@Logger.level.INFO, "Starting the server in #{@Configuration['env']} at port #{@Configuration['port']}...")

      # Handle app events and connect to database
      @handleEvents()
      @Database = new database(@, require "./config/database")

    bootstrap: ->
      Application = this
      Sockets = new socket(@Configuration['port'])

      Sockets.listen (status) ->
        if status is true
          Application.Logger.log(Application.Logger.level.INFO, "Server started and waiting for new connections!")
        else
          Application.Logger.log(Application.Logger.level.ERROR, "Failed to start the server!", "Exception from Sockets.listen()")
          Application.__dispose()

    handleEvents: ->
      # Registers all basic events of the application
      @on 'application:bootstrap', -> @bootstrap()
      @on 'application:dispose', -> @__dispose()

    __dispose: ->
      # Exit with success code
      process.exit(0)
