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

Currently no predicates for the mpd plugin. If you would like to do something when the state changes u could use the attribute predicate.<br>
if Kodi is playing then switch speakers on <br>
if Kodi is stopped then switch speakers off <br>


###Note's
Big thanks to the code of Pimatic
i used the pimatic-mpd plugin as base for this project.
https://github.com/pimatic/pimatic-mpd

I also changed a bit and extended the XBMC node as it was not functioning propperly/not sufficient enough.
I will be working on this as well to get it improved, any help/tips would be great!
https://github.com/Fjuxx/node-xbmc

###TO DO
- Add volume controls
- Check how it works with movies

- create new device (template)
- better support for multimedia (now focused @ music)