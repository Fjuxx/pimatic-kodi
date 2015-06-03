

  {TCPConnection, XbmcApi} = require 'xbmc'

  connection = new TCPConnection
    host:    '192.168.178.111'
    port:    9090
    verbose: true
  xbmc = new XbmcApi
  xbmc.setConnection connection

  xbmc.on 'connection:open',                        -> 
    console.log 'Connection is open'
 # xbmc.on 'connection:data', (data)                 -> console.log 'Received data:',         data
 # xbmc.on 'connection:notification', (notification) -> console.log 'Received notification:', notification
#    xbmc.player.mixin xbmc
  setTimeout ( ->
    console.log 'PlayPause'
    xbmc.player.playPause().then(->
      console.log 'done')
  
  ), 1000

 # setTimeout  (-> xbmc.message '2s: Hello World'), 2000
 # setTimeout  (-> xbmc.input.ExecuteAction 'playpause'), 5000
 # setTimeout  (-> xbmc.send 'Player.PlayPause', 
 #                    playerid: 0) , 6000

  # setTimeout (=> 
  #   dfd = xbmc.send 'Player.GetActivePlayers'
  #   dfd.then (data) =>
  #     playerId =  data.result?.playerid ? data.result[0]?.playerid ? data.player?.playerid 
  #     console.log data.result[0]?.playerid
  #     #console.log data
  #     console.log playerId
  #     dfd = xbmc.send 'Player.PlayPause',
  #       playerid: playerId
  #     dfd.then (data) =>
  #       console.log 'done'), 5000

  # setTimeout (=> 
  #   xbmc.player.getActivePlayers (data) ->
  #     playerId = data.result?.playerid ? data.result[0]?.playerid ? data.player?.playerid
  #     dfd = xbmc.player.api.send 'Player.PlayPause',
  #       playerid: playerId), 3000
  
  
