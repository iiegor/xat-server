#ext = require '../ext/googleAnalytics'
cmd = require '../mixins/cmd-mixin'

module.exports = {
	trackEvent: (type, val) ->

	onError: ->
		@trackEvent 'error', err

	init: ->
		cmd.regCmd 'application:error', @onError
}