logger = require "./util/logger"

module.exports =
  class Application
    name: 'Application'

    constructor: ->
      Logger = new logger(this)
      Logger.log(Logger.level.ERROR, "hello", "ex")
