logger = require "../util/logger"

module.exports =
  class Database
    name: 'Database'

    Logger: null
    Driver: null

    constructor: (@app, @config) ->
      # Register
      @Logger = new logger(this)

      # Initialize
      @initializeDriver()

    initializeDriver: ->
      Parent = @

      switch @config['driver']
        when 'mongo'
          # Soon available
          @Logger.log @Logger.level.ERROR, 'The selected driver is actually in development', "(#{@config['driver']})"

          # Dispose the application
          @app.__dispose()
        when 'mysql'
          # Configure
          @Driver = (require "mysql").createConnection(
            host: @config['host']
            user: @config['username']
            password: @config['password']
          )

          # Initialize
          @Driver.connect (err) ->
            if err
              Parent.Logger.log Parent.Logger.level.ERROR, 'An error occurred when trying to connect with the database server', err

              Parent.app.__dispose()
            else
              Parent.query("USE #{Parent.config['database']}")

              # Emit successfull connection
              Parent.app.emit('application:bootstrap')
        else
          @Logger.log @Logger.level.ERROR, 'The selected driver is not compatible', "(#{@config['driver']})"

          # Dispose the application
          @app.__dispose()

    query: (args) ->
      try
        return @Driver.query(args)
      catch ex
        return null
