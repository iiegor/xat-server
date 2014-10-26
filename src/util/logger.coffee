module.exports =
  class Logger
    level: {
      INFO: "INFO"
      ERROR: "ERROR"
      DEBUG: "DEBUG"
    }

    constructor: (@caller) ->

    log: (level, message) ->
      return console.log "[#{@caller.name}] [?] #{message}" if typeof level == "undefined"

      switch level
        when @level.INFO
          console.info "[#{@caller.name}] [#{level}] #{message}"
        when @level.ERROR
          console.error "[#{@caller.name}] [#{level}] #{message} - #{arguments[2]}"
        when @level.DEBUG
          console.warn "[#{@caller.name}] [#{level}] #{message}"
