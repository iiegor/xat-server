et = require "elementtree"

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

  getAttribute: (packet, attr) ->
    return @getAttributes(packet)[attr]

  getRoot: (packet) ->
    return et.parse(packet)._root

  escape: (str) ->
    return String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;')
