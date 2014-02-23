RemoteSpotifyApp
================

A custom Spotify iOS app that allows remote control commands to be taken from a Bluetooth device. The Bluetooth capabilities are yet to be implemented.

The app currently has the following features:
 - Play tracks from user playlists randomly
 - Integration with the "Now Playing" section on the lock screen and ability to receive remote control events from the lock screen.
 - Offline playback works sometimes - there is an issue with the Spotify cache being corrupted at times.
 
Setup
===============

After cloning the project, you must run `git submodule init` followed by `git submodule update` in order to download the cocoalibspotify dependency.

License
================

Copyright (c) 2014 Alex Schimp.

Licensed under the [MIT License](http://opensource.org/licenses/MIT).
