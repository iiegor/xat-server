BackboneEvents = require 'backbone-events-standalone'
_ = require 'underscore'

Events = {
	dispose: ->
		BackboneEvents.trigger('application:dispose')
}

_.extend(Events, BackboneEvents)

module.exports = Events
