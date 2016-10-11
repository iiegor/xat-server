builder = require '../utils/builder'

Rank = require '../structures/rank'

module.exports =
  buildMeta: (client) ->
    ## Chat settings and info
    ## r: 1 - (All main owner) / 2 - (All moderator) / 3 - (All member) / 4 (All owner)
    ## v: 1 - (Normal) / 3 - (w_VIP) / 4 - (w_ALLP) / other - (All unregistered)
    packet = builder.create('i')
    packet.append('b', "#{client.chat.bg};=#{client.chat.attached.name || ''};=#{client.chat.attached.id || ''};=#{client.chat.language};=#{client.chat.radio};=#{client.chat.button}")
    packet.append('r', client.chat.rank.toNumber()) if client.chat.rank != Rank.GUEST
    packet.append('f', '21233728')
    packet.append('v', '3')
    packet.append('cb', '2387')

  buildPowers: (client) ->
    packet = builder.create('gp')
    packet.append('p', '0|0|1163220288|1079330064|20975876|269549572|16645|4210689|1|4194304|0|0|0|')
    packet.append('g180', "{'m':'','d':'','t':'','v':1}")
    packet.append('g256', "{'rnk':'8','dt':120,'rc':'1','v':1}")
    packet.append('g100', 'assistance,1lH2M4N,xatalert,1e7wfSx')
    packet.append('g114', "{'m':'Lobby','t':'Staff','rnk':'8','b':'Jail','brk':'8','v':1}")
    packet.append('g112', 'Welcome to the lobby! Visit assistance and help pages.')
    packet.append('g246', "{'rnk':'8','dt':30,'rt':'10','rc':'1','tg':1000,'v':1}")
    packet.append('g90', 'shit,faggot,slut,cum,nigga,niqqa,prostitute,ixat,azzhole,tits,dick,sex,fuk,fuc,thot')
    packet.append('g80', "{'mb':'11','ubn':'8','mbt':24,'ss':'8','rgd':'8','prm':'14','bge':'8','mxt':60,'sme':'11','dnc':'11','bdg':'11','yl':'10','rc':'10','p':'7','ka':'7'}")
    packet.append('g74', 'd,waiting,astonished,swt,crs,un,redface,evil,rolleyes,what,aghast,omg,smirk')
    packet.append('g106', 'c#sloth')
