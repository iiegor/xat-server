startTime = Date.now()

pkg = require '../package'
server = require './services/server'
database = require './services/database'

{EventEmitter} = require 'events'

module.exports =
class Application extends EventEmitter
  ###
  Section: Properties
  ###
  logger: null
  config: null

  ###
  Section: Construction
  ###
  constructor: ->
    global.Application = this

    @config = require '../config/default'
    @logger = new (require './utils/logger')(Application)

    @logger.log @logger.level.DEBUG, "You are running #{pkg.name} #{pkg.version}"
    @logger.log @logger.level.INFO, "Starting the server in #{@config.env} at port #{@config.port}..."

    # Handle app events
    @handleEvents()

    # Bootstrap the application
    @bootstrap()

  ###
  Section: Private
  ###
  bootstrap: ->
    @logger.log @logger.level.INFO, 'Checking connectivity with database...'

    database.initialize (err) =>
      return @logger.log @logger.level.ERROR, 'No connection with the database', err if err

      server = new server(@config.port, @config.host)
      server.bind()

  # Register all application events
  handleEvents: ->
    @on 'application:started', -> @logger.log @logger.level.INFO, "Server started in #{Date.now() - startTime}ms"
    @on 'application:dispose', @dispose

    unless process.platform is 'win32'
      process.on 'SIGTERM', @dispose

  # Dispose with success code
  dispose: -> process.exit 0
