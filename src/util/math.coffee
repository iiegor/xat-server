module.exports =
  random: (min, max) ->
    return Math.floor(Math.random()*(max-min+1)+min)

  time: ->
    return Math.floor(new Date().getTime() / 1000);
