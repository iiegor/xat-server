database = require '../../src/services/database'
config = require '../../config/tests'

idRange = [config.idRange.min .. config.idRange.max]
chatRange = [config.chatRange.min .. config.chatRange.max]
#`chats`(`id`, `name`, `bg`, `language`, `desc`, `sc`, `ch`, `email`, `radio`, `pass`, `button`, `attached`, `pool`, `pools`)

Promise.all(
  for chatid in chatRange
    database.exec('DELETE FROM `messages` WHERE id = ?', chatid)
).then( ->
  for chatid in chatRange
    database.exec('DELETE FROM `ranks` WHERE chatid = ?', chatid)
).then( ->
  for chatid in chatRange
    database.exec('DELETE FROM `chats` WHERE id = ?', chatid)
).then( ->
  for userid in idRange
    database.exec('DELETE FROM `users` WHERE id = ?', userid)
).then( ->
  for chatid in chatRange
    database.exec('INSERT INTO `chats` SET ?',
      id: chatid
      name: 'test ' + chatid
      bg: 'http://xat.com/web_gear/background/xat_splash.jpg'
      language: 'en'
      desc: 'Tupucal description ' + chatid
      sc: 'Welcome to chat ' + chatid
      email: 'admin' + chatid + '@example.com'
      radio: '127.0.' + chatid / 256 + '.' + chatid % 256
      pass: chatid + 20000
      button: '#FF0000'
      attached: ''
    )
).then( ->
  for userid in idRange
    database.exec('INSERT INTO `users` SET ?',
      id: userid
      username: 'unregistered'#'username' + userid
      nickname: 'nickname' + userid
      password: '123' + userid
      avatar: userid
      url: 'http://example.com/id?' + userid
      email: 'mail' + userid + '@mail.example.com'
      k: 'k_' + userid
      k2: 'k2_' + userid
      k3: 'k3_' + userid
      bride: ''
      xats: 0
      days: 0
      enabled: 'enabled'
      dO: ''
      loginKey: ''
    )
).catch((err) ->
  console.error '[ERROR] Error while initializing database ' + JSON.stringify(err)
  process.exit(1)
).then ->
  process.exit()
