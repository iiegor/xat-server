logger = require "./util/logger"
sockets = require "./services/sockets"
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

      # Bootstrap the application
      @bootstrap()

    bootstrap: ->
      self = @

      new sockets(@Configuration['port']).bind ->
        self.Logger.log(self.Logger.level.INFO, "Server started and waiting for new connections!")

    handleEvents: ->
      # Registers all basic events of the application
      @on 'application:bootstrap', -> @bootstrap()
      @on 'application:dispose', -> @__dispose()

    __dispose: ->
      # Exit with success code
      process.exit(0)
