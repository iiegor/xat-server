BackboneEvents = require 'backbone-events-standalone'
_ = require 'underscore'

module.exports = {
	getCmds: ->
		@_cmds or (@_cmds = [])
		@_cmds
	
	regCmd: (e, t) ->
		if !_.isFunction(t)
			throw Error('handler is not a function')
		
		@getCmds().push(
			cmd: e
			handler: t
		)

		BackboneEvents.on(e, t)
		return
	
	unregCmd: (e, t) ->
		BackboneEvents.off(e, t)
		@_cmds = _.reject(@_cmds, _.matches(
			cmd: e
			handler: t
		))
		return
	
	registerCmds: ->
		@_cmds and @getCmds().forEach((e) ->
			BackboneEvents.on e.cmd, e.handler
			return
		)
		return
	
	unregisterCmds: ->
		@_cmds and @getCmds().forEach((e) ->
			BackboneEvents.off e.cmd, e.handler
			return
		)

		delete @_cmds
		return
	
	componentDidMount: ->
		@registerCmds()
		return
	
	componentWillUnmount: ->
		@unregisterCmds()
		return
}
