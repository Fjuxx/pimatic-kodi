# ##The plugin code

# Your plugin must export a single function, that takes one argument and returns a instance of
# your plugin class. The parameter is an envirement object containing all pimatic related functions
# and classes. See the [startup.coffee](http://sweetpi.de/pimatic/docs/startup.html) for details.
module.exports = (env) ->

  # ###require modules included in pimatic
  # To require modules that are included in pimatic use `env.require`. For available packages take 
  # a look at the dependencies section in pimatics package.json

  # Require the  bluebird promise library
  Promise = env.require 'bluebird'

  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'
  
  # Require the XBMC(kodi) API
  {TCPConnection, XbmcApi} = require 'xbmc'

  
#    silent: true      # comment out for debug!


  # ###KodiPlugin class
  class KodiPlugin extends env.plugins.Plugin

    # ####init()
    # The `init` function is called by the framework to ask your plugin to initialise.
    #  
    # #####params:
    #  * `app` is the [express] instance the framework is using.
    #  * `framework` the framework itself
    #  * `config` the properties the user specified as config for your plugin in the `plugins` 
    #     section of the config.json file 
    #     
    # 
    init: (app, @framework, @config) =>
      env.logger.info("Kodi plugin started")
      deviceConfigDef = require("./device-config-schema")

      @framework.deviceManager.registerDeviceClass("KodiPlayer", {
        configDef: deviceConfigDef.KodiPlayer, 
        createCallback: (config) => new KodiPlayer(config)
      })




  class KodiPlayer extends env.devices.Device
    _state: null
    _currentTitle: null
    _currentArtist: null
    _volume: null
    connection: null

    actions: 
      play:
        description: "starts playing"
      pause:
        description: "pauses playing"
      stop:
        description: "stops playing"
      next:
        description: "play next song"
      previous:
        description: "play previous song"
      volume:
        description: "Change volume of player"

    attributes:
      currentArtist:
        description: "the current playing track artist"
        type: "string"   
      currentTitle:
        description: "the current playing track title"
        type: "string"
      state:
        description: "the current state of the player"
        type: "string"
      volume:
        description: "the volume of the player"
        type: "string"

    template: "musicplayer"

    constructor: (@config) ->
      @name = @config.name
      @id = @config.id

      connection = new TCPConnection
        host: @config.host
        port: @config.port
        verbose: true

      @kodi = new XbmcApi
        debug: env.logger.debug

      @kodi.setConnection connection  
      #  connection: connection
      @kodi.on 'connection:open',                        -> env.logger.info 'Kodi connected'
      @kodi.on 'connection:close',                       -> env.logger.info 'Kodi Disconnected'
      @kodi.on 'connection:notification', (notification) -> 
        env.logger.debug 'Received notification:', notification

      super()

    getState: () ->
      return Promise.resolve @_state

    getCurrentTitle: () -> Promise.resolve(@_currentTitle)
    getCurrentArtist: () -> Promise.resolve(@_currentTitle)
    getVolume: ()  -> Promise.resolve(@_volume)
    play: () -> @_sendCommandAction('play')
    pause: () -> @_sendCommandAction('pause')
    stop: () -> @_sendCommandAction('stop')
    previous: () -> env.logger.debug 'previous not implemented'
    next: () -> env.logger.debug 'next not implemented'
    setVolume: (volume) -> env.logger.debug 'setVolume not implemented'

    _updateInfo: -> Promise.all([@_getStatus(), @_getCurrentSong()])

    _setState: (state) ->
      if @_state isnt state
        @_state = state
        @emit 'state', state

    _setCurrentTitle: (title) ->
      if @_currentTitle isnt title
        @_currentTitle = title
        @emit 'currentTitle', title

    _setCurrentArtist: (artist) ->
      if @_currentArtist isnt artist
        @_currentArtist = artist
        @emit 'currentArtist', artist

    _setVolume: (volume) ->
      if @_volume isnt volume
        @_volume = volume
        @emit 'volume', volume

    _getStatus: () ->
      env.logger.debug 'get status'
      #@_client.sendCommandAsync(mpd.cmd("status", [])).then( (msg) =>
      #  info = mpd.parseKeyValueMessage(msg)
      #  @_setState(info.state)
      #  @_setVolume(info.volume)
        #if info.songid isnt @_currentTrackId
      #)

    _getCurrentSong: () ->
      env.logger.debug '_getCurrentSong not implemented'
      # @_client.sendCommandAsync(mpd.cmd("currentsong", [])).then( (msg) =>
      #   info = mpd.parseKeyValueMessage(msg)
      #   @_setCurrentTitle(if info.Title? then info.Title else "")
      #   @_setCurrentArtist(if info.Name? then info.Name else "")
      # ).catch( (err) =>
      #   env.logger.error "Error sending mpd command: #{err}"
      #   env.logger.debug err
      # )

    _sendCommandAction: (action) ->
      @kodi.input.ExecuteAction action
        
      


  # Create a instance of  Kodiplugin
  kodiPlugin = new KodiPlugin
  # and return it to the framework.
  return kodiPlugin