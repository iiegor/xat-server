chalk = require 'chalk'
fs = require 'fs'

module.exports =
class Logger
  level: {
    INFO: 'INFO'
    ERROR: 'ERROR'
    DEBUG: 'DEBUG'
  }

  constructor: (@caller) ->

  log: (level, message) ->
    return console.log "[#{@caller.name}] [?] #{message}" if typeof level == "undefined"

    switch level
      when @level.INFO
        console.info chalk.cyan("[#{@caller.name}]") + chalk.green("[#{level}] ") + "#{message}"
      when @level.ERROR
        console.error chalk.cyan("[#{@caller.name}]") + chalk.red("[#{level}] ") + "#{message} - ", arguments[2]
        @write """
          #{new Date()}
          ERROR: #{@caller.name} #{message}
          MESSAGE: #{arguments[2]}
          \n
          """ if global.Application.config['env'] isnt 'dev'
      when @level.DEBUG
        console.log chalk.cyan("[#{@caller.name}]") + chalk.gray("[#{level}] ") + "#{message}" if global.Application.config['env'] is 'dev'

  write: (exception) -> fs.appendFile global.Application.config.logfile, exception