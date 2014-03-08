#include "MultiColorLed.h"

namespace RemoteSpotify
{
    MultiColorLed::MultiColorLed(int redLedPin, int greenLedPin, int blueLedPin)
    {
        redPin = redLedPin;
        greenPin = greenLedPin;
        bluePin = blueLedPin;
        pinMode(redPin, OUTPUT);
        pinMode(greenPin, OUTPUT);
        pinMode(bluePin, OUTPUT);
        
        isOn = false;
        color = Color();
    }
    
    void MultiColorLed::SetColor(Color newColor)
    {
        color = newColor;
        UpdateOutput();
    }
    
    void MultiColorLed::TurnOn()
    {
        isOn = true;
        UpdateOutput();
    }
    
    void MultiColorLed::TurnOn(Color newColor)
    {
        isOn = true;
        color = newColor;
        UpdateOutput();
    }
    
    void MultiColorLed::TurnOff()
    {
        isOn = false;
        UpdateOutput();
    }
    
    void MultiColorLed::Blink(int onTime, int offTime, int cycles)
    {
        for (int i = 0; i < cycles; i++)
        {
            TurnOn();
            delay(onTime);
            TurnOff();
            if (i < cycles - 1) delay(offTime);
        }
    }
    
    void MultiColorLed::Blink(int onTime, int offTime, int cycles, Color newColor)
    {
        SetColor(newColor);
        for (int i = 0; i < cycles; i++)
        {
            TurnOn();
            delay(onTime);
            TurnOff();
            if (i < cycles - 1) delay(offTime);
        }
    }
    
    void MultiColorLed::BlinkAndRestoreState(int onTime, int offTime, int cycles, Color newColor)
    {
        // save current state
        Color prevColor = color;
        bool wasOn = isOn;
        
        // blink
        Blink(onTime, offTime, cycles, newColor);
        
        // restore previous state
        color = prevColor;
        isOn = wasOn;
        UpdateOutput();
    }
    
    void MultiColorLed::UpdateOutput()
    {
        if (isOn)
        {
            analogWrite(redPin, color.red);
            analogWrite(greenPin, color.green);
            analogWrite(bluePin, color.blue);
        }
        else
        {
            analogWrite(redPin, 0);
            analogWrite(greenPin, 0);
            analogWrite(bluePin, 0);
        }
    }
}
