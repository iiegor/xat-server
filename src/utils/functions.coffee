module.exports =
    ## Usage
    # array =
    # a: 'b'
    # c: 'd'
    # e: 'f'
    # CreatePacketFrom('array',[type of packet],[array])
    ##
    ## TODO
    # Make it accept different type of data and check for empty value
    ##
    CreatePacketFrom: (type,name,data) ->
      switch type
        when 'array'
          str = "<#{name}"
          for k,v of data
            str += " #{k}=\"#{v}\""
          str += " />"
          return str
