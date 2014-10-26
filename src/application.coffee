logger = require "./util/logger"

module.exports =
  class Application
    name: 'Application'

    constructor: ->
      # Register
      @Logger = new logger(this)
      @Configuration = require "./config/environment"

      # Bootstrap
      @bootstrap()

    bootstrap: ->
