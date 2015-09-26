database = require '../services/database'

module.exports =
  joinRoom: (@handler, roomId) ->
    return if roomId < 1 or isNaN(roomId) is true

    database.acquire (err, db) =>
      db.query("SELECT * FROM chats WHERE id = '#{roomId}' ", (db, data) =>
        if @handler.chat is null
          @handler.chat = data[0]

        @chat = @handler.chat

        return false if !@chat

        @chat.attached = try JSON.parse(@chat.attached) catch error then {}
        @chat.onPool = @chat.onPool || 0

        # TODO: Broadcast new user to the room
        ## Chat settings and info
        @handler.send "<i b=\"#{@chat.bg};=#{@chat.attached.name||''};=#{@chat.attached.id||''};=#{@chat.language};=#{@chat.radio};=#{@chat.button}\" f=\"21233728\" v=\"1\" cb=\"2387\" />"
        ## Chat group powers
        @handler.send """
          <gp p="0|0|1163220288|1079330064|20975876|269549572|16645|4210689|1|4194304|0|0|0|"
            g180="{'m':'','d':'','t':'','v':1}" 
            g256="{'rnk':'8','dt':120,'rc':'1','v':1}" 
            g100="assistance,1lH2M4N,xatalert,1e7wfSx,screenshots,1n24XUR,colors,1e7wg8S,hat,1f3SL2X,fairtrade,1fetDl7,auction,1e7wixy,forum,1e7wg93,staff,1e7wixA,help,1e7wixC,freewebs,1e7wgpp,xattrade,1e7wixF,aide,1e7wixG,bot,1e7wfSw,bots,1e7wfSw,ayuda,1f3SM6Z,ajuda,1e7wgpu,helfen,1e7wiNZ,mosa3adeh,1e7wiO0,cambio,1e7wiO1,troca,1f3SMni,chat,1e7wiO4,game,1f3SLjs,volunteers,1e7wgFS,ticket,1e7wiO9,powerid,1gS9IAk,wikieditors,1e7wjBu,terms,1e7wjBB,pauction,1e7wjBD,userinfo,1vBWEmL,deal,1l8S1Kn,nameglow,LGXjQx,namecolor,LGXjQx,xatspace,1vBSHOP,chatinfo,1vBSWJR,avatars,19cK4gi,kiss,1vBTmjk,createkiss,1vBTmjk,prices,JbD0tN,pomocy,1bBZgoj,testtwitter,1jAUgbU,blog,1jl2UGE,newticket,1cWWbT0,social,1rzK0UV,mark,1yQP1fo" 
            g114="{'m':'Lobby','t':'Staff','rnk':'8','b':'Jail','brk':'8','v':1}" 
            g112="Welcome to the lobby! Visit assistance and help pages." 
            g246="{'rnk':'8','dt':30,'rt':'10','rc':'1','tg':1000,'v':1}" 
            g90="shit,faggot,slut,cum,nigga,niqqa,prostitute,ixat,azzhole,tits,dick,sex,fuk,fuc,thot" 
            g80="{'mb':'11','ubn':'8','mbt':24,'ss':'8','rgd':'8','prm':'14','bge':'8','mxt':60,'sme':'11','dnc':'11','bdg':'11','yl':'10','rc':'10','p':'7','ka':'7'}"
            g74="d,waiting,astonished,swt,crs,un,redface,evil,rolleyes,what,aghast,omg,smirk" 
            g106="c#sloth" />
          """
        ## Chat pools
        @handler.send "<w v=\"#{@chat.onPool} #{@chat.pool}\"  />"
        ## Fake user for testing (send here room users)
        @handler.send '<u cb="1443256921" s="1" f="170" p0="2013264863" p1="2147483647" p2="4294836215" p3="4294967287" p4="2113929215" p5="2147479551" p6="2147352575" p7="2147483647" p8="2147483647" p9="2147483647" p10="2147483647" p11="119" u="869659734" d0="16794729" d2="1690000" q="3" N="Sevda" n="Sevda(glow#d#000000)" a="http://i.cubeupload.com/FOHlkL.png#glitter#http://i.hizliresim.com/1yRXm1.jpg" h="" v="0"  />'
        @handler.send '<u cb="1443201972" s="1" f="8364" p0="1476393983" p1="2147483647" p2="4294967263" p3="4294967295" p4="2147483647" p5="2147483647" p6="2147352575" p7="2147483647" p8="2147483647" p9="2147483647" p10="2147483647" p11="127" u="23232323" d0="25165856" d2="358469415" q="3" N="FEXBot" n="$Chatbot(glow#000000#ffffff)##xat.chat#0#ffffff" a="#http://nobg" h="xat.com/Chat" v="0"  />'
        @handler.send '<u cb="1414865425" s="1" f="172" p0="1979711487" p1="2147475455" p2="2147483647" p3="2147483647" p4="2113929211" p5="2147483647" p6="2147352575" p7="2147483647" p8="2147483647" p9="8372223" u="42" d0="151535720" q="3" N="Bot" n="42(glow#02000a#r)(hat#ht)##testing..#02000a#r" a="xatwebs.co/test.png" h="" v="0"  />'
        ## Scroll message
        @handler.send "<m t=\"/s#{@chat.sc}\" d=\"1010208\"  />"
        ## Done packet
        @handler.send '<done  />'
      )

      database.release db
      