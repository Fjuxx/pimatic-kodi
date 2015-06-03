# #my-plugin configuration options
# Declare your config option for your plugin here. 
module.exports = {
  title: "Kodi plugin config options"
  type: "object"
  properties:
      host:
        description: "The IP of Kodi/XBMC"
        type: "string"
        default: "192.168.178.110"
      port:
        description: "The port for Kodi/XMBC RPC (Default: 9090)"
        type: "integer"
        default: 9090
      customOpenCommands:
        description: "Custom Player.Open commands"
        type: "array"
        default: []
        format: "table"
        items:
          type: "object"
          properties:
            name:
              type: "string"
            command:
              description: "The command"
              type: "string"

}