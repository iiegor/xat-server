logger = require './utils/logger'
sockets = require './services/sockets'
database = require './services/database'
cmd = require './mixins/cmd-mixin'

module.exports =
  class Application extends cmd
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
      # Registers all basic events of the application
      Application.regCmd 'application:dispose', @__dispose

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
