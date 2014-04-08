RemoteSpotifyApp
================

A custom Spotify iOS app that allows remote control commands to be taken from a Bluetooth device.

The app currently has the following features:
 - Play tracks from user playlists randomly
 - Integration with the "Now Playing" section on the lock screen and ability to receive remote control events from the lock screen.
 - Use an [RFduino](http://www.rfduino.com/) to advance to the next track or go back to the previous track.
 - Offline playback works sometimes - there is an issue with the Spotify cache being corrupted at times.
 
Setup
===============

After cloning the project, you must run `git submodule init` followed by `git submodule update` in order to download the cocoalibspotify dependency. You will also need to get an application key from https://developer.spotify.com/technologies/libspotify/, and put it into an appkey.c file in the RemoteSpotify directory.

### RFduino

After installing the necessary software to program the RFduino and ensuring that the Arduino IDE is configured properly as detailed [here](https://github.com/RFduino/RFduino), open the /RFDuinoSketches/Remote/Remote.ino sketch and upload it onto the RFduino.

##### Parts
 - [RFduino](http://www.rfduino.com/product/rfd22102-rfduino-dip/)
 - [RGB Pushbutton Shield](http://www.rfduino.com/product/rfd22122-rgb-button-shield-for-rfduino/)
 - [USB Shield (required for programming)](http://www.rfduino.com/product/rfd22121-usb-shield-for-rfduino/)
 - [CR2032 Coin Battery Shield (optional - for use when not powered by the USB Shield)](http://www.rfduino.com/product/rfd22128-cr2032-coin-battery-shield-for-rfduino/)

License
================

Copyright (c) 2014 Alex Schimp.

Licensed under the [MIT License](http://opensource.org/licenses/MIT).
