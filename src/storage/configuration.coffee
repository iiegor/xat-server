"""
Application configuration cache model
"""

module.exports =
  class ConfigurationModel
    _cache: null

    constructor: (settings={}) ->
      return if @_cache != null

      @_cache = settings

    get: (key) -> @_cache[key]
    set: (key, val) -> @_cache[key] = val
    remove: (key) -> delete @_cache[key]
