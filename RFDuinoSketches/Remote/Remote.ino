/*
This RFduino sketch demonstrates a full bi-directional Bluetooth Low
Energy 4 connection between an iPhone application and an RFduino.

This sketch works with the rfduinoLedButton iPhone application.

The button on the iPhone can be used to turn the green led on or off.
The button state of button 1 is transmitted to the iPhone and shown in
the application.
*/

#include <RFduinoBLE.h>
#include "ButtonData.h"

using namespace RemoteSpotify;

// pin 2 on the RGB shield is the red led
int ledRed = 2;
// pin 3 on the RGB shield is the green led
int ledGreen = 3;
// pin 4 on the RGB shield is the blue led
int ledBlue = 4;

// pin 5 on the RGB shield is button 1
// (button press will be shown on the iPhone app)
int nextBtn = 5;
int prevBtn = 6;

// debounce time (in ms)
int debounce_time = 10;

// maximum debounce timeout (in ms)
int debounce_timeout = 100;

int nextBtnLastPressTime = -1;

void setup() {
  Serial.begin(9600);
  // leds to indicate status
  pinMode(ledRed, OUTPUT);
  pinMode(ledGreen, OUTPUT);
  pinMode(ledBlue, OUTPUT);

  // button press will be shown on the iPhone app)
  pinMode(nextBtn, INPUT);
  pinMode(prevBtn, INPUT);

  // this is the data we want to appear in the advertisement
  // (the deviceName length plus the advertisement length must be <= 18 bytes
  RFduinoBLE.advertisementData = "rspotify";
  
  RFduinoBLE.txPowerLevel = -20;
  
  // start the BLE stack
  Serial.println("Starting BLE stack");
  RFduinoBLE.begin();
  
  // setup pinwake callbacks
  Serial.println("Configuring pinWake callbacks");
  RFduino_pinWakeCallback(nextBtn, LOW, nextBtnPressed);
  RFduino_pinWakeCallback(nextBtn, HIGH, nextBtnPressed);
  RFduino_pinWakeCallback(prevBtn, HIGH, prevBtnPressed);
  
  // turn on red led to indicate no connection
  analogWrite(ledRed, 10);
}

int nextBtnPressed(uint32_t ulPin)
{
  Serial.println("Entered button1 pinwake callback");
  if (debounce(ulPin, HIGH))
  {
    nextBtnLastPressTime = millis();
    Serial.println("Sending button1 signal");
    RFduinoBLE.send(0);
    analogWrite(ledBlue, 100);
    delay(300);
    digitalWrite(ledBlue, LOW);
  }
  else if (debounce(ulPin, LOW))
  {
    if (nextBtnLastPressTime != -1 && millis() - nextBtnLastPressTime > 3000)
      shutdown();
      
    nextBtnLastPressTime = -1;
  }
  
  return 0;  // don't exit RFduino_ULPDelay
}

int prevBtnPressed(uint32_t ulPin)
{
  Serial.println("Entered button2 pinwake callback");
  if (debounce(ulPin, HIGH))
  {
    Serial.println("Sending button2 signal");
    RFduinoBLE.send(1);
    analogWrite(ledBlue, 100);
    delay(300);
    digitalWrite(ledBlue, LOW);
  }
  
  return 0;  // don't exit RFduino_ULPDelay
}

int debounce(int btn, int state)
{ 
  int start = millis();
  int debounce_start = start;
  
  while (millis() - start < debounce_timeout)
  {
    Serial.println(digitalRead(btn));
    if (digitalRead(btn) == state)
    {
      if (millis() - debounce_start >= debounce_time)
        return 1;
    }
    else
      debounce_start = millis();
  }

  return 0;
}

void loop() {
  Serial.println("Entering ULPDelay(INFINITE) in delay_until_button");
  // switch to lower power mode until a button edge wakes us up
  RFduino_ULPDelay(INFINITE);
  Serial.println("Leaving ULPDelay(INFINITE) in delay_until_button");
  
  // if somehow we came out of the ULPDelay, clear the pinWakes so that we can sleep again
  RFduino_resetPinWake(nextBtn);
  RFduino_resetPinWake(prevBtn);
}

void RFduinoBLE_onConnect() {
  analogWrite(ledGreen, 10);
  digitalWrite(ledRed, LOW);
}

void RFduinoBLE_onDisconnect()
{
  digitalWrite(ledGreen, LOW);
  analogWrite(ledRed, 10);
}

void shutdown()
{
  digitalWrite(ledGreen, LOW);
  digitalWrite(ledRed, LOW);
  for (int i = 0; i < 5; i++)
  {
    delay(200);
    analogWrite(ledRed, 10);
    delay(200);
    digitalWrite(ledRed, LOW);
  }
  
  RFduino_systemOff();
}

