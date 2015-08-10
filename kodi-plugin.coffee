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
  EventEmitter = require('events').EventEmitter

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

      @framework.ruleManager.addActionProvider(
        new KodiExecuteOpenActionProvider(@framework,@config)
      )
      @framework.ruleManager.addPredicateProvider(new PlayingPredicateProvider(@framework))

  class ConnectionProvider extends EventEmitter
    connection : null
    connected : false
    _host : ""
    _port : 0
    _emitter : null

    constructor: (host,port) ->
      @_host = host
      @_port = port

    getConnection: =>
      return new Promise((resolve, reject) =>
        if @connected
          resolve @connection
        else
          # make a new connection
          KodiApi(@_host,@_port).then((newConnection) =>
            @connected = true
            @connection = newConnection
            @emit 'newConnection'
            
            @connection.on "error", (() =>
              @connected = false
              @connection = null
            )
            @connection.on "close", (() =>
              @connected = false
              @connection = null
            )
            resolve @connection
          ).catch( (error) =>
            env.logger.debug 'connection rejected'
            env.logger.debug error
          )
      )

  class KodiPlayer extends env.devices.AVPlayer
    _type: ""
    _connectionProvider : null
    
    kodi : null

    constructor: (@config) ->
      @name = @config.name
      @id = @config.id

      @_state = 'stopped'

      @actions = _.cloneDeep @actions
      @attributes =  _.cloneDeep @attributes

      @actions.executeOpenCommand =
        description: "Execute custom Player.Open command"

      @attributes.type =
        description: "The current type of the player"
        type: "string"

      @_connectionProvider = new ConnectionProvider(@config.host, @config.port)

      @_connectionProvider.on 'newConnection', =>
        @_connectionProvider.getConnection().then (connection) =>
          connection.Player.OnPause (data) =>
            env.logger.debug 'Kodi Paused'
            @_setState 'paused'
            return

          connection.Player.OnStop =>
            env.logger.debug 'Kodi Paused'
            @_setState 'stopped'
            @_setCurrentTitle ''
            @_setCurrentArtist ''
            return

          connection.Player.OnPlay (data) =>
            if data?.data?.item?
              @_parseItem(data.data.item)
            env.logger.debug 'Kodi Playing'
            @_setState 'playing'
            return
      @_updateInfo()
      setInterval => 
        @_updateInfo()
      , 60000

      super()
    
    getType: () -> Promise.resolve(@_type)
    play: () -> 
      @_connectionProvider.getConnection().then (connection) =>
        connection.Player.GetActivePlayers().then (players) =>
          if players.length > 0
            connection.Player.PlayPause({"playerid":players[0].playerid})
    pause: () -> 
      @_connectionProvider.getConnection().then (connection) =>
        connection.Player.GetActivePlayers().then (players) =>
          if players.length > 0
            connection.Player.PlayPause({"playerid":players[0].playerid})
    stop: () -> 
      @_connectionProvider.getConnection().then (connection) =>
        connection.Player.GetActivePlayers().then (players) =>
          if players.length > 0
            connection.Player.Stop({"playerid":players[0].playerid})
    previous: () -> 
      @_connectionProvider.getConnection().then (connection) =>
        connection.Player.GetActivePlayers().then (players) =>
          if players.length > 0
            connection.Player.GoTo({"playerid":players[0].playerid,"to":"previous"})
    next: () -> 
      @_connectionProvider.getConnection().then (connection) =>
        connection.Player.GetActivePlayers().then (players) =>
          if players.length > 0
            connection.Player.GoTo({"playerid":players[0].playerid,"to":"next"})
    setVolume: (volume) -> env.logger.debug 'setVolume not implemented'

    executeOpenCommand: (command) =>
      env.logger.debug command
      
      @_connectionProvider.getConnection().then (connection) =>
        connection.Player.Open({
          item: { file : command}
          })

    _updateInfo: -> Promise.all([@_updatePlayer()])

    _setType: (type) ->
      if @_type isnt type
        @_type = type
        @emit 'type', type

    _updatePlayer: () ->
      env.logger.debug '_updatePlayer'
      @_connectionProvider.getConnection().then (connection) =>
        connection.Player.GetActivePlayers().then (players) =>
          if players.length > 0
            connection.Player.GetItem(
              {"playerid":players[0].playerid,"properties":["title","artist"]}
            ).then (data) =>
              env.logger.debug data
              info = data.item
              @_setType(info.type)
              @_setCurrentTitle(
                if info.title? then info.title else if info.label? then info.label else ""
              )
              @_setCurrentArtist(if info.artist? then info.artist else "")
          else
            @_setCurrentArtist ''
            @_setCurrentTitle ''

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

  class KodiExecuteOpenActionProvider extends env.actions.ActionProvider
    constructor: (@framework,@config) ->
    # ### executeAction()
    ###
    This function handles action in the form of `execute "some string"`

    ###
    parseAction: (input, context) =>
      retVar = null

      kodiPlayers = _(@framework.deviceManager.devices).values().filter( 
        (device) => device.hasAction("executeOpenCommand") 
      ).value()
      if kodiPlayers.length is 0 then return

      device = null
      match = null
      state = null
      #get command names
      commandNames = []
      for command in @config.customOpenCommands
        commandNames.push(command.name)
      onDeviceMatch = ( (m , d) -> device = d; match = m.getFullMatch() )   

      m = M(input, context)
        .match('execute Open Command ')
        .match(commandNames, (m,s) -> state = s.trim();)
        .match(' on ')
        .matchDevice(kodiPlayers, onDeviceMatch)
        
      if match?
        assert device?
        assert (state) in commandNames
        assert typeof match is "string"
        return {
          token: match
          nextInput: input.substring(match.length)
          actionHandler: new KodiExecuteOpenActionHandler(device,@config,state)
        }
      else
        return null

  class KodiExecuteOpenActionHandler extends env.actions.ActionHandler

    constructor: (@device,@config,@name) -> #nop

    executeAction: (simulate) => 
      if simulate
        for command in @config.customOpenCommands
          if command.name is @name
            return Promise.resolve __("would execute %s", command.command)
      else
        for command in @config.customOpenCommands
          env.logger.debug "checking for: #{command.name} == #{@name}"
          if command.name is @name
            return @device.executeOpenCommand(
              command.command).then( => __("executed %s", @device.name)
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
        if (@state.trim() is p.trim())
          @emit 'change', (@state.trim() is p.trim())
        else if @state is "not playing" and (p.trim() isnt "playing")
          @emit 'change', (p.trim() isnt "playing")
      @device.on 'state', @playingListener
      super()
    getValue: -> 
      return @device.getUpdatedAttributeValue('state').then( 
        (p) => #(if (@state.trim() is p.trim()) then not p else p)
          if (@state.trim() is p.trim())
            return (@state.trim() is p.trim())
          else if @state is "not playing" and (p.trim() isnt "playing")
            return (p.trim() isnt "playing")
      )
    destroy: -> 
      @device.removeListener "state", @playingListener
      super()
    getType: -> 'state' 


  # Create a instance of  Kodiplugin
  kodiPlugin = new KodiPlugin
  # and return it to the framework.
  return kodiPlugin