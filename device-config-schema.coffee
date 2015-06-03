module.exports ={
  title: "pimatic-Kodi device config schemas"
  KodiPlayer: {
    title: "KodiPlayer config options"
    type: "object"
    extensions: ["xLink"]
    properties:
      port:
        description: "The port of Kodi/XBMC"
        type: "number"
      host:
        description: "The address of Kodi/XBMC"
        type: "string"
          properties:
      CustomOpenCommands:
        description: "Custom Player.Open commands to send."
        type: "array"
        default: []
        format: "table"
        items:
          type: "object"
          properties:
            name:
              description: "The name of the command"
              type: "string"
            command:
              description: "The command"
              type: "string"
  }
}
