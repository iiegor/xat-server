logger = require "./util/logger"
configuration = require "./storage/configuration"

module.exports =
  class Application
    name: 'Application'

    constructor: ->
      # Register
      @Logger = new logger(this)
      @Configuration = new configuration({
        test: 'k'
        test2: 'x'
      })

      # Bootstrap
      @bootstrap()

    bootstrap: ->
