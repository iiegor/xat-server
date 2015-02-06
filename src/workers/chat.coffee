database = require '../services/database'

module.exports =
  chat: {}

  joinRoom: (handler, roomId) ->
    # Real chat connection
    database.acquire (err, db) ->
      db.query("SELECT * FROM chats WHERE id = '#{roomId}' ", (db, data) ->
        @chat = data[0]

        handler.send "<i b=\"#{@chat.bg};=#{@chat.attached};=1;=English;=http://87.230.56.15/;=#{@chat.button};=\" f=\"21233728\" v=\"1\" cb=\"2387\" />"
        handler.send "<gp p=\"0|0|1163220288|1079330064|20975876|269549572|16645|4210689|1|4194304|0|0|0|\" g180=\"{'m':'','d':'','t':'','v':1}\" g256=\"{'rnk':'8','dt':120,'rc':'1','v':1}\" g100=\"assistance,1lH2M4N,xatalert,1e7wfSx,screenshots,1n24XUR,colors,1e7wg8S,hat,1f3SL2X,fairtrade,1fetDl7,auction,1e7wixy,forum,1e7wg93,staff,1e7wixA,help,1e7wixC,freewebs,1e7wgpp,xattrade,1e7wixF,aide,1e7wixG,bot,1e7wfSw,bots,1e7wfSw,ayuda,1f3SM6Z,ajuda,1e7wgpu,helfen,1e7wiNZ,mosa3adeh,1e7wiO0,cambio,1e7wiO1,troca,1f3SMni,chat,1e7wiO4,game,1f3SLjs,volunteers,1e7wgFS,ticket,1e7wiO9,powerid,1gS9IAk,wikieditors,1e7wjBu,terms,1e7wjBB,pauction,1e7wjBD,userinfo,1vBWEmL,deal,1l8S1Kn,nameglow,LGXjQx,namecolor,LGXjQx,xatspace,1vBSHOP,chatinfo,1vBSWJR,avatars,19cK4gi,kiss,1vBTmjk,createkiss,1vBTmjk,prices,JbD0tN,pomocy,1bBZgoj,testtwitter,1jAUgbU,blog,1jl2UGE,newticket,1cWWbT0,social,1rzK0UV,mark,1yQP1fo\" g114=\"{'m':'Rengade','t':'Staff','rnk':'8','b':'Baneados','brk':'11','v':1}\" g112=\"Welcome to xat_test! Type !test followed by a smiley to test it out (if bot is here)\" g246=\"{'rnk':'8','dt':30,'rt':'10','rc':'1','tg':1000,'v':1}\" g90=\"shit,faggot,slut,cum,nigga,niqqa,prostitute,ixat,azzhole,tits,dick,sex,fuk,fuc,thot\" g80=\"{'mb':'11','mm':'10','mbt':24,'prm':'14','bge':'11','sme':'0','bdg':'7','ns':'11','p':'7'}\" g74=\"d,waiting,astonished,swt,crs,un,redface,evil,rolleyes,what,aghast,omg,smirk\" g106=\"#clear\"   />"
        handler.send "<w v=\"0 #{@chat.pool}\"  />"

        handler.send '<done  />'
      )

      database.release db

    ###
    Template for chat connection

    ## Chat settings
    handler.send '<i b="http://i57.tinypic.com/5r18k.jpg;=Deal;=22497272;=English;=http://87.230.56.15/;=#424242;=" f="21233728" v="1" cb="2387"  />'
    ## Chat group powers
    handler.send "<gp p=\"0|0|1163220288|1079330064|20975876|269549572|16645|4210689|1|4194304|0|0|0|\" g180=\"{'m':'','d':'','t':'','v':1}\" g256=\"{'rnk':'8','dt':120,'rc':'1','v':1}\" g100=\"assistance,1lH2M4N,xatalert,1e7wfSx,screenshots,1n24XUR,colors,1e7wg8S,hat,1f3SL2X,fairtrade,1fetDl7,auction,1e7wixy,forum,1e7wg93,staff,1e7wixA,help,1e7wixC,freewebs,1e7wgpp,xattrade,1e7wixF,aide,1e7wixG,bot,1e7wfSw,bots,1e7wfSw,ayuda,1f3SM6Z,ajuda,1e7wgpu,helfen,1e7wiNZ,mosa3adeh,1e7wiO0,cambio,1e7wiO1,troca,1f3SMni,chat,1e7wiO4,game,1f3SLjs,volunteers,1e7wgFS,ticket,1e7wiO9,powerid,1gS9IAk,wikieditors,1e7wjBu,terms,1e7wjBB,pauction,1e7wjBD,userinfo,1vBWEmL,deal,1l8S1Kn,nameglow,LGXjQx,namecolor,LGXjQx,xatspace,1vBSHOP,chatinfo,1vBSWJR,avatars,19cK4gi,kiss,1vBTmjk,createkiss,1vBTmjk,prices,JbD0tN,pomocy,1bBZgoj,testtwitter,1jAUgbU,blog,1jl2UGE,newticket,1cWWbT0,social,1rzK0UV,mark,1yQP1fo\" g114=\"{'m':'Rengade','t':'Staff','rnk':'8','b':'Baneados','brk':'11','v':1}\" g112=\"Welcome to xat_test! Type !test followed by a smiley to test it out (if bot is here)\" g246=\"{'rnk':'8','dt':30,'rt':'10','rc':'1','tg':1000,'v':1}\" g90=\"shit,faggot,slut,cum,nigga,niqqa,prostitute,ixat,azzhole,tits,dick,sex,fuk,fuc,thot\" g80=\"{'mb':'11','mm':'10','mbt':24,'prm':'14','bge':'11','sme':'0','bdg':'7','ns':'11','p':'7'}\" g74=\"d,waiting,astonished,swt,crs,un,redface,evil,rolleyes,what,aghast,omg,smirk\" g106=\"#clear\"   />"
    ## Chat pools
    handler.send '<w v="0 0 1 2 3"  />'
    ## Fake user
    handler.send '<u cb="1414865425" s="1" f="172" p0="1979711487" p1="2147475455" p2="2147483647" p3="2147483647" p4="2113929211" p5="2147483647" p6="2147352575" p7="2147483647" p8="2147483647" p9="8372223" u="42" d0="151535720" q="3" N="Paul" n="korex-server..(glow#02000a#r)(hat#ht)##testing..#02000a#r" a="xatwebs.co/test.png" h="" v="0"  />'
    ## Done packet
    handler.send '<done  />'

    ###
