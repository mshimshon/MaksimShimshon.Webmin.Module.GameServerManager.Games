### Getting Started
The pipeline for game server is simple every game has its own logic to start/stop/restart/update and config... 

The script file name never changes and the folder name of the game matches LGSM naming.


### Startup Parameters
The startup parameters visible on the dashboard of blazor LGSM are defined inside game_info.json.
```editable``` is to defined if the user is allowed to change the startup paramters via GUI... if not the user will not be allowed to update them...

Hosting services can therefore flip automatically at deploy time the editable on some of the parameters given the service they offer.

### Patch Config

Not all games are having startup parameters for some config and for such games ```patch_game_config.sh``` exist and should be called upon start or restart of the server.

A good use case is a hosting provider selling player slots... the user can change the max player but upon start up, if the max player is patch it will be changed back to hosting allowed value.
