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

  compose: -> "#{@packet} />"

