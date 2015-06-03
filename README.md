Pimatic-Kodi plugin
=======================

Pimatic plugin for controlling Kodi (XBMC) Media player

###device config example:

```json
{
  "id": "kodi-player",
  "name": "Kodi",
  "class": "KodiPlayer",
  "host": "192.168.1.2",
  "port": 9090
}
```

###device rules examples:

<b>Play music</b><br>
if smartphone is present then play Kodi

<b>Pause music</b><br>
if smartphone is absent then pause Kodi

<b>Next song</b><br>
if buttonNext is pressed then play next song on Kodi

<b>Previous song</b><br>
if buttonPrev is pressed then play previous song on Kodi

<b>Save yourself!</b><br>
if currentArtist of Kodi = "Justin Bieber" then play next song on Kodi


<b>Predictates examples</b>
if Kodi is playing then switch speakers on and dim lights to 30<br>
if Kodi is not playing then switch speakers off and dim lights to 100<br>

if Kodi is playing and kodi.type != "song" then dim lights to 30<br/>To make sure lights only dim if you are watching a movies/series.

###Custom commands
You can add custom Player.Open commands to the plugin. Player.Open can execute almost anything.
From opening Youtube movies, Soundcloud streams to simple opening a file.

example configuration for a custom command:
```json
{
  "plugin": "kodi",
  "customOpenCommands": [
    {
      "name": "nyan",
      "command": "plugin://plugin.video.youtube/?action=play_video&videoid=QH2-TGUlwu4"
    }
  ]
}
```

<b>Execute the custom command</b>
if yourrule then execute Open Command nyan on Kodi


This is just one of the example's you can do with the Player.Open command to Kodi,
This can also execute scripts in Kodi. 

You only need to find out what the script/plugin path is, and what parameter to give.


###Note's
Big thanks to the code of Pimatic
i used the pimatic-mpd plugin as base for this project.
https://github.com/pimatic/pimatic-mpd


###TO DO
- Add volume controls
- create new device (template)
- better support for multimedia (now focused @ music)