et = require 'elementtree'

###
Crypto file
In this case the function of this file is parse packets.
###

module.exports =
  getTagName: (packet) ->
    try
      packet = et.parse(packet)
      return packet._root.tag
    catch ex
      return null

  getAttributes: (packet) ->
    packet = et.parse(packet)

    return packet._root.attrib

  getAttribute: (packet) ->
    return et.parse(packet)._root_attrib[packet]

  getRoot: (packet) ->
    return et.parse(packet)._root
