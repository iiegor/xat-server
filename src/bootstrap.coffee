logger = require "./util/logger"
sockets = require "./services/sockets"
database = require "./services/database"
{EventEmitter} = require 'events'

module.exports =
  class Application extends EventEmitter
    name: 'Application'

    logger: new logger(this)
    configuration: require "./config/environment"

    constructor: ->
      @logger.log(@logger.level.INFO, "Starting the server in #{@configuration['env']} at port #{@configuration['port']}...")

      # Handle app events
      @handleEvents()

      # Bootstrap the application
      @bootstrap()

    bootstrap: ->
      self = @

      new sockets(@configuration['port']).bind ->
        self.logger.log(self.logger.level.INFO, "Server started and waiting for new connections!")

    handleEvents: ->
      self = @

      # Registers all basic events of the application
      @on 'application:bootstrap', -> @bootstrap()
      @on 'application:dispose', -> @__dispose()

      ### Uncaught exception
      process.on('uncaughtException', (err) ->
        if self.configuration['env'] is not 'dev'
          err = "Uncaught exception!"

        self.logger.log self.logger.level.ERROR, err
      )
      ###

    __dispose: ->
      # Exit with success code
      process.exit(0)
