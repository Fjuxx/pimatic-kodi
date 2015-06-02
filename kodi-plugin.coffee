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
  # {TCPConnection, XbmcApi} = require 'xbmc'

  KodiApi = require 'xbmc-ws'
  
  VERBOSE = false

  M = env.matcher
  _ = env.require('lodash')


  


  
#    silent: true      # comment out for debug!


  # ###KodiPlugin class
  class KodiPlugin extends env.plugins.Plugin

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

      @framework.ruleManager.addActionProvider(new KodiPauseActionProvider(@framework))
      @framework.ruleManager.addActionProvider(new KodiPlayActionProvider(@framework))
      #@framework.ruleManager.addActionProvider(new MpdVolumeActionProvider(@framework))
      @framework.ruleManager.addActionProvider(new KodiPrevActionProvider(@framework))
      @framework.ruleManager.addActionProvider(new KodiNextActionProvider(@framework))
      @framework.ruleManager.addPredicateProvider(new PlayingPredicateProvider(@framework))


  class KodiPlayer extends env.devices.Device
    _state: "stopped"
    _type: ""
    _currentTitle: null
    _currentArtist: null
    _volume: null
    
    kodi : null
    

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
      type:
        description: "The current type of the player"
        type: "string"
      volume:
        description: "the volume of the player"
        type: "string"


    template: "musicplayer"

    constructor: (@config) ->
      @name = @config.name
      @id = @config.id

      _state = 'stopped'

      KodiApi(@config.host,@config.port).then (connection) =>
        @kodi = connection
        env.logger.info 'Kodi connected'
        env.logger.debug @kodi
        # @kodi.on 'error' , 'close', =>
        #   env.logger.info 'Kodi Disconnected, Attempting reconnect'
        #   #make reconnect

        @kodi.Player.OnPause (data) =>
          env.logger.debug 'Kodi Paused'
          @_setState 'paused'
          return

        @kodi.Player.OnStop =>
          env.logger.debug 'Kodi Paused'
          @_setState 'stopped'
          return

        @kodi.Player.OnPlay (data) =>
          if data?.data?.item?
            @_parseItem(data.data.item)
          env.logger.debug 'Kodi Playing'
          @_setState 'Playing'
          return

        

      # @kodi.on 'connection:open',                        => 
      #   env.logger.info 'Kodi connected'
      #   @_updateInfo()        
      # @kodi.on 'connection:close',                       => 
      #   setTimeout () =>
      #     env.logger.info 'Kodi Disconnected, Attempting reconnect'
      #     connection = new TCPConnection
      #       host: @config.host
      #       port: @config.port
      #       verbose: VERBOSE
      #     @kodi.setConnection connection 
      #   , 60000
      # @kodi.on 'connection:notification', (notification) => 
      #   env.logger.debug 'Received notification:', notification
      # @kodi.on 'notification:play', (data) =>
      #   @_setState 'playing'
      #   env.logger.debug 'onPlay data: ', data.params.data.item
      #   @_parseItem data.params.data.item

      # @kodi.on 'notification:pause', =>
      #   @_setState 'paused'
      # @kodi.on 'api:playerStopped', =>
      #   @_setState 'stopped'
      #   @_setCurrentTitle("")
      #   @_setCurrentArtist("")
        
      super()

    getState: () ->
      return Promise.resolve @_state

    getCurrentTitle: () -> Promise.resolve(@_currentTitle)
    getCurrentArtist: () -> Promise.resolve(@_currentTitle)
    getVolume: ()  -> Promise.resolve(@_volume)
    getType: () -> Promise.resolve(@_type)
    play: () -> @kodi.Player.PlayPause()
    pause: () -> @kodi.Player.PlayPause()
    stop: () -> @kodi.Player.Stop()
    previous: () -> @kodi.Player.Previous()
    next: () -> @kodi.Player.Next() 
    setVolume: (volume) -> env.logger.debug 'setVolume not implemented'

    _updateInfo: -> Promise.all([@_updatePlayer()])

    _setState: (state) ->
      if @_state isnt state
        @_state = state
        @emit 'state', state
    _setType: (type) ->
      if @_type isnt type
        @_type = type
        @emit 'type', type

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

    _updatePlayer: () ->
      env.logger.debug '_updatePlayer'
      @kodi.Player.GetActivePlayers().then (players) =>
        if players.length > 0
          @kodi.Player.GetItem({"playerid":players[0].playerid,"properties":["title","artist"]}).then (data) =>
            env.logger.debug data
            info = data.item
            @_setCurrentTitle(if info.title? then info.title else if info.label? then info.label else "")
            @_setCurrentArtist(if info.artist? then info.artist else "")
            @_setType(info.type)

    _sendCommandAction: (action) ->
      @kodi.input.ExecuteAction action

    _parseItem: (itm) ->
      if itm?
        artist = itm.artist?[0] ? itm.artist
        title = itm.title
        type = itm.type ? ''
        @_setType type  
        env.logger.debug title

        if type == 'song' || (title? && artist?)
          @_setCurrentTitle(if title? then title else "")
          @_setCurrentArtist(if artist? then artist else "")
        #else

        @_updateInfo()

  # Pause play volume actions
  class KodiPauseActionProvider extends env.actions.ActionProvider 
  
    constructor: (@framework) -> 
    # ### executeAction()
    ###
    This function handles action in the form of `execute "some string"`
    ###
    parseAction: (input, context) =>

      retVar = null

      kodiPlayers = _(@framework.deviceManager.devices).values().filter( 
        (device) => device.hasAction("play") 
      ).value()

      if kodiPlayers.length is 0 then return

      device = null
      match = null

      onDeviceMatch = ( (m, d) -> device = d; match = m.getFullMatch() )

      m = M(input, context)
        .match('pause ')
        .matchDevice(kodiPlayers, onDeviceMatch)
        
      if match?
        assert device?
        assert typeof match is "string"
        return {
          token: match
          nextInput: input.substring(match.length)
          actionHandler: new KodiPauseActionHandler(device)
        }
      else
        return null

  class KodiPauseActionHandler extends env.actions.ActionHandler

    constructor: (@device) -> #nop

    executeAction: (simulate) => 
      return (
        if simulate
          Promise.resolve __("would pause %s", @device.name)
        else
          @device.pause().then( => __("paused %s", @device.name) )
      )
  
  class KodiPlayActionProvider extends env.actions.ActionProvider 
  
    constructor: (@framework) -> 
    # ### executeAction()
    ###
    This function handles action in the form of `execute "some string"`
    ###
    parseAction: (input, context) =>

      retVar = null

      kodiPlayers = _(@framework.deviceManager.devices).values().filter( 
        (device) => device.hasAction("play") 
      ).value()

      if kodiPlayers.length is 0 then return

      device = null
      match = null

      onDeviceMatch = ( (m, d) -> device = d; match = m.getFullMatch() )

      m = M(input, context)
        .match('play ')
        .matchDevice(kodiPlayers, onDeviceMatch)
        
      if match?
        assert device?
        assert typeof match is "string"
        return {
          token: match
          nextInput: input.substring(match.length)
          actionHandler: new KodiPlayActionHandler(device)
        }
      else
        return null

  class KodiPlayActionHandler extends env.actions.ActionHandler

    constructor: (@device) -> #nop

    executeAction: (simulate) => 
      return (
        if simulate
          Promise.resolve __("would play %s", @device.name)
        else
          @device.play().then( => __("playing %s", @device.name) )
      )


  class KodiNextActionProvider extends env.actions.ActionProvider 

    constructor: (@framework) -> 
    # ### executeAction()
    ###
    This function handles action in the form of `execute "some string"`
    ###
    parseAction: (input, context) =>

      retVar = null
      volume = null

      kodiPlayers = _(@framework.deviceManager.devices).values().filter( 
        (device) => device.hasAction("play") 
      ).value()

      if kodiPlayers.length is 0 then return

      device = null
      valueTokens = null
      match = null

      onDeviceMatch = ( (m, d) -> device = d; match = m.getFullMatch() )

      m = M(input, context)
        .match(['play next', 'next '])
        .match(" song ", optional: yes)
        .match("on ")
        .matchDevice(kodiPlayers, onDeviceMatch)

      if match?
        assert device?
        assert typeof match is "string"
        return {
          token: match
          nextInput: input.substring(match.length)
          actionHandler: new KodiNextActionHandler(device)
        }
      else
        return null
        
  class KodiNextActionHandler extends env.actions.ActionHandler
    constructor: (@device) -> #nop

    executeAction: (simulate) => 
      return (
        if simulate
          Promise.resolve __("would play next track of %s", @device.name)
        else
          @device.next().then( => __("play next track of %s", @device.name) )
      )      

  class KodiPrevActionProvider extends env.actions.ActionProvider 

    constructor: (@framework) -> 
    # ### executeAction()
    ###
    This function handles action in the form of `execute "some string"`
    ###
    parseAction: (input, context) =>

      retVar = null
      volume = null

      kodiPlayers = _(@framework.deviceManager.devices).values().filter( 
        (device) => device.hasAction("play") 
      ).value()

      if kodiPlayers.length is 0 then return

      device = null
      valueTokens = null
      match = null

      onDeviceMatch = ( (m, d) -> device = d; match = m.getFullMatch() )

      m = M(input, context)
        .match(['play previous', 'previous '])
        .match(" song ", optional: yes)
        .match("on ")
        .matchDevice(kodiPlayers, onDeviceMatch)

      if match?
        assert device?
        assert typeof match is "string"
        return {
          token: match
          nextInput: input.substring(match.length)
          actionHandler: new KodiNextActionHandler(device)
        }
      else
        return null
        
  class KodiPrevActionHandler extends env.actions.ActionHandler
    constructor: (@device) -> #nop

    executeAction: (simulate) => 
      return (
        if simulate
          Promise.resolve __("would play previous track of %s", @device.name)
        else
          @device.previous().then( => __("play previous track of %s", @device.name) )
      ) 
  class PlayingPredicateProvider extends env.predicates.PredicateProvider
    constructor: (@framework) ->

    parsePredicate: (input, context) ->  
      kodiDevices = _(@framework.deviceManager.devices).values()
        .filter((device) => device.hasAttribute( 'state')).value()

      device = null
      state = null
      negated = null
      match = null

      M(input, context)
        .matchDevice(kodiDevices, (next, d) =>
          next.match([' is', ' reports', ' signals'])
            .match([' playing', ' stopped',' paused', ' not playing'], (m, s) =>
              if device? and device.id isnt d.id
                context?.addError(""""#{input.trim()}" is ambiguous.""")
                return
              device = d
              state = s.trim() # is one of  'playing', 'stopped', 'paused', 'not playing'
              match = m.getFullMatch()
            )
      )
      
      if match?
        assert device?
        assert state?
        assert typeof match is "string"
        return {
          token: match
          nextInput: input.substring(match.length)
          predicateHandler: new PlayingPredicateHandler(device, state)
        }
      else
        return null   

  class PlayingPredicateHandler extends env.predicates.PredicateHandler

    constructor: (@device, @state) ->

    setup: -> 
      @playingListener = (p) => 
        env.logger.debug "checking for: #{@state} == #{p}"
        if (@state is p)
          @emit 'change', (@state is p)
        else if @state is "not playing"
          @emit 'change', (p isnt "playing")
      @device.on 'state', @playingListener
      super()
    getValue: -> 
      return @device.getUpdatedAttributeValue('state').then( 
        (p) => (if (@state is p) then not p else p)
      )
    destroy: -> 
      @device.removeListener "state", @playingListener
      super()
    getType: -> 'state' 


  # Create a instance of  Kodiplugin
  kodiPlugin = new KodiPlugin
  # and return it to the framework.
  return kodiPlugin