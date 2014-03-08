#ifndef Button_h
#define Button_h

#include "Arduino.h"
#include <RFduinoBLE.h>

namespace RemoteSpotify
{
    class Button
    {
        // constants
        static const int debounce_time = 10; // debounce time (in ms)
        static const int debounce_timeout = 100; // maximum debounce timeout (in ms)
        
        // private fields
        int pin; // the button pin on the RFduino
        int lastPressTime; // stores the time of the last detected HIGH signal on the button pin
        int lastHoldDuration; // stores the number of milliseconds between the last HIGH signal and the succeeding LOW signal
        
        // private methods
        bool debounceInternal(int state);
        
        public:
            // Initializes the button on the specified RFduino pin
            Button(int btnPin);
            
            // Checks if the button state matches the parameter 'state', after debouncing
            bool Debounce(int state);
            
            // Gets the button pin on the Rfduino
            int GetPin();
            
            // Gets the number of milliseconds between the last HIGH signal and the succeeding LOW signal. If the button is still pressed, it will return the number of milliseconds
            // that the button has been pressed so far. Note that the button state is only read when the Debounce method is called, so this duration is only accurate if the Debounce
            // method is called often when the button state might be changing.
            int GetHoldDuration();
    };
}

#endif
