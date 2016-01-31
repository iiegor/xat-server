###
Usage:
  packet = packet.create('tagName')
  packet.append('attrName', 'attrData')
  packet.compose()
###

module.exports =
class Packet
  ###
  Section: Static
  ###
  @create: (tag) -> new Packet(tag)

  ###
  Section: Construction
  ###
  constructor: (tag) ->
    @packet = "<#{tag}"

  ###
  Section: Public
  ###
  append: (key, value) ->
    @packet += " #{key}=\"#{value}\""

    return @

  appendRaw: (str) ->
    @packet += " #{str}"

    return @

  compose: -> "#{@packet} />"

