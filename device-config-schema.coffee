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
  }
}