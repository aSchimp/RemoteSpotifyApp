#ifndef MultiColorLed_h
#define MultiColorLed_h

#include "Arduino.h"
#include <RFduinoBLE.h>

namespace RemoteSpotify
{
    // Represents an RGB color
    struct Color {
        uint8_t red;
        uint8_t green;
        uint8_t blue;
        Color():red(0), green(0), blue(0) { }
        Color(uint8_t r, uint8_t g, uint8_t b):red(r), green(g), blue(b) { }
    };
    
    // Manages the multi-color RGB LED on the RFduino
    class MultiColorLed
    {
        // private fields
        int redPin; // the red led pin on the RFduino
        int greenPin; // the green led pin on the RFduino
        int bluePin; // the blue led pin on the RFduino
        bool isOn; // whether or not the led is currently on
        Color color; // the current color of the led
        
        // private methods
        void UpdateOutput();
        
        public:
            // Initializes the LED on the specified RFduino pins
            MultiColorLed(int redLedPin, int greenLedPin, int blueLedPin);
            
            // Sets the color of the LED. If the LED is already on, the color will be updated right away. If it is not on, this color will be used next time the LED is turned
            // on (unless another color is specified at that point).
            void SetColor(Color newColor);
            
            // Turns the LED on, using whatever color the LED previously had.
            void TurnOn();
            
            // Turns the LED on, using the specified color.
            void TurnOn(Color newColor);
            
            // Turns the LED off.
            void TurnOff();
            
            // Blinks the LED. The onTime and offTime are in milliseconds. The cycles parameter indicates the number of times to blink the LED.
            // The color of the LED will be whatever color the LED previously had.
            void Blink(int onTime, int offTime, int cycles);
            
            // Blinks the LED. The onTime and offTime are in milliseconds. The cycles parameter indicates the number of times to blink the LED.
            // The newColor parameter sets the color of the LED.
            void Blink(int onTime, int offTime, int cycles, Color newColor);
            
            // Blinks the LED, and restores the previous state of the LED when blinking finishes. The onTime and offTime are in milliseconds. 
            // The cycles parameter indicates the number of times to blink the LED. The newColor parameter sets the color of the LED.
            void BlinkAndRestoreState(int onTime, int offTime, int cycles, Color newColor);
    };
}

#endif
