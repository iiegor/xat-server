pkg = require '../package'
logger = require './utils/logger'
server = require './services/server'
database = require './services/database'
cmd = require './mixins/cmd-mixin'
config = require '../config/default'
dispatcher = require './dispatcher'

module.exports =
  class Application
    name: 'Application'

    logger: new logger(this)
    server: null

    constructor: ->
      @logger.log @logger.level.DEBUG, "You are running korex-server #{pkg.version}"
      @logger.log @logger.level.INFO, "Starting the server in #{config.env} at port #{config.port}..."

      # Handle app events
      @handleEvents()

      # Load plugins
      @loadPlugins()

      # Bootstrap the application
      @bootstrap()

    bootstrap: ->
      # TODO: First ping database and then initialize the server
      self = @

      # Initialize database service
      @logger.log @logger.level.INFO, "Checking connectivity with database..."
      database.acquire (err, db) -> database.release db

      # Initialize server service
      @server = new server(config.port)
      @server.bind ->
        self.logger.log self.logger.level.INFO, "Server started and waiting for new connections!"

    handleEvents: ->
      self = @

      # Registers all basic events of the application
      cmd.regCmd 'application:dispose', @__dispose

      # If env is dev skip the uncaught exception handler
      return if config.env == 'dev'

      ### Handle exceptions ###
      process.on 'uncaughtException', (err) ->
        self.logger.log self.logger.level.ERROR, "Uncaught exception", err.code
        self.server.close()

        colors = require 'colors'

        rl = (require 'readline').createInterface(
          input: process.stdin
          output: process.stdout
        )

        rl.question 'An uncaught exception ocurred, the server was closed. Do you want to report it?'.red + ' yes/no\n', (answer) ->
          rl.close()

          if answer in ['yes', 'y', 'ye', 'yess', 'yep']
            open = require 'open'

            title = encodeURIComponent(err.code)
            body = encodeURIComponent("""
            [Enter steps to reproduce below:]
            1. ..
            2. ..


            """ + err.stack)
            open "http://github.com/korex/korex-server/issues/new?title=#{title}&body=#{body}"

          dispatcher.dispose()

    loadPlugins: ->
      return if !config['plugins']

      # TODO: Plugin loader / handler

    __dispose: ->
      # Exit with success code
      process.exit(0)
