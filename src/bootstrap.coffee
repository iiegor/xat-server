pkg = require '../package'
logger = require './utils/logger'
server = require './services/server'
database = require './services/database'
config = require '../config/default'

{EventEmitter} = require 'events'
_ = require 'underscore'

module.exports =
  class Application
    _.extend @prototype, EventEmitter.prototype

    ###
    Section: Properties
    ###
    logger: new logger(this)

    ###
    Section: Construction
    ###
    constructor: ->
      @logger.log @logger.level.DEBUG, "You are running #{pkg.name} #{pkg.version}"
      @logger.log @logger.level.INFO, "Starting the server in #{config.env} at port #{config.port}..."

      global.Application = this

      # Handle app events
      @handleEvents()

      # Load plugins
      @loadPlugins()

      # Bootstrap the application
      @bootstrap()

    ###
    Section: Private
    ###
    bootstrap: ->
      # TODO: First ping database and then initialize the server
      # Initialize database service
      @logger.log @logger.level.INFO, "Checking connectivity with database..."
      database.acquire (err, db) -> database.release db

      # Initialize server service
      server = new server(config.port)
      server.bind =>
        @logger.log @logger.level.INFO, "Server started and waiting for new connections!"

    handleEvents: ->
      # Register all application events
      @on 'application:dispose', @dispose

    loadPlugins: ->
      return

      # TODO: Plugin loader / handler
      # plugins = pkg.packageDependencies

    dispose: ->
      # Exit with success code
      process.exit(0)
