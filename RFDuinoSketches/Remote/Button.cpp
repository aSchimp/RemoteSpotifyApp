#include "Button.h"

namespace RemoteSpotify
{
    Button::Button(int btnPin)
    {
        lastPressTime = -1;
        lastHoldDuration = 0;
        pin = btnPin;
        pinMode(pin, INPUT);
    }
    
    bool Button::Debounce(int state)
    {
        bool result = debounceInternal(state);
        
        if (state == HIGH && result && lastPressTime == -1)
            lastPressTime = millis();
        else if (state == LOW && result && lastPressTime != -1)
        {
            lastHoldDuration = millis() - lastPressTime;
            lastPressTime = -1;
        }
        
        return result;
    }
    
    bool Button::debounceInternal(int state)
    {
      int start = millis();
      int debounce_start = start;
      
      while (millis() - start < debounce_timeout)
      {
        if (digitalRead(pin) == state)
        {
          if (millis() - debounce_start >= debounce_time)
            return true;
        }
        else
          debounce_start = millis();
      }
    
      return false;
    }
    
    int Button::GetPin()
    {
        return pin;
    }
    
    int Button::GetHoldDuration()
    {
        if (lastPressTime != -1)
            return millis() - lastPressTime;
        else
            return lastHoldDuration;
    }
}
