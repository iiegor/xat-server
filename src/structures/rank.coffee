module.exports =
class Rank
  _number: null
  map = [0, 4, 2, 1, 3]
  strmap = ['r', null, 'm', 'e', 'M']
  rankPool = [new Rank(0), new Rank(1), new Rank(2), new Rank(3), new Rank(4)]

  @GUEST = rankPool[0]
  @MEMBER = rankPool[3]
  @MODERATOR = rankPool[2]
  @OWNER = rankPool[4]
  @MAINOWNER = rankPool[1]

  ## For internal use.
  constructor: (@_number) ->

  toNumber: -> @_number

  toString: -> strmap[@_number]

  ## Normal way to convert number to rank.
  @fromNumber: (number) ->
    return rankPool[number]
  @fromString: (str) ->
    return rankPool[strmap.indexOf str]

  compareTo: (rank) -> map[@_number] - map[rank._number]
