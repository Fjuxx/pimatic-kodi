var kodi = require('xbmc-ws');
var util = require('util');
 
kodi('192.168.178.110', 9090).then(function(connection) {
    /* Do something with the connection */
    console.log('conn');
    console.log(connection);

    var movies = connection.VideoLibrary.GetMovies(['title', 'rating', 'year'], {"start" : 0, "end": 2});

    console.log(movies);
    movies.then(function (data) {
        console.log('movies:');
        console.log(data);
    })
    connection.Application.SetMute(false).then(function(data) {
        console.log('Muted');
        console.log(data);
    })
    connection.Player.GetActivePlayers().then(function(data){
        if (data.length > 0) {
            connection.Player.GetItem({"playerid": data[0].playerid}).then(function(data) {
            console.log('resolved');
            console.log(data);
    
            }); 
        }
    });
    

    

});