// Some code adapted from the Adafruit Neopixel Strand-test, 
// the bleuart_datamode.ino and geekyjacket by Eric Oesterle & Neil Heather

#include <Arduino.h>
#include <SPI.h>
#if not defined (_VARIANT_ARDUINO_DUE_X_) && not defined (_VARIANT_ARDUINO_ZERO_)
#include <SoftwareSerial.h>
#endif

#include "Adafruit_BLE.h"
#include "Adafruit_BluefruitLE_SPI.h"
#include "Adafruit_BluefruitLE_UART.h"

#include "BluefruitConfig.h"

#include <Adafruit_NeoPixel.h>

// ones to choose random strip for:
// bouncing balls

// Communication "protocol":
// 'r' = red
// 'b' = blue
// 'y' = yellow
// 'g' = green
// 'w' = white
// 's' = sparkles
// 't' = twinkle
// 'm' = march, a set of (currently 10) pixels march down the strip.
// 'n' = running lights
// 'e' = meteor rain
// 'h' = breathe
// 'f' = fire     (https://github.com/i-protoss/wave)??
// 'a' = bouncing balls
// 'o' = rainbow
//  'l' = light spill, that is, spill down the pixel strip and stay on with a given color.
// Any other character sets all pixels to off.
uint8_t currentMode = 'l';
uint32_t currentColor = 4278190080; // white
uint8_t receivedInput = 'o';


// The board pins that are connected to Neopixel strips.
static int PIN_NUMBERS[5] = { 5, 6, 10, 11, 12 };
#define STRIPLEN 15 // Length of LED strips
#define NUM_PINS 5 // the number of pins that are connected to neopixel strips.
#define DEFAULT_BRIGHTNESS 50 // BRIGHTNESS to about 1/5 (max = 255)
#define GREEN_BITMASK 0x00ff0000UL
#define RED_BITMASK 0x0000ff00UL
#define BLUE_BITMASK 0x000000ffUL
#define WHITE_BITMASK 0xff000000UL


/// SPECIAL NOTE!!!!! Although the Adafruit Neopixel library claims it's in RGBW order, based on my experimentation
/// it would seem it is actually in GRBW order (!!!!!!) Take care!!!
Adafruit_NeoPixel strip = Adafruit_NeoPixel(STRIPLEN, PIN_NUMBERS[0], NEO_RGBW);
// Argument 1 = Number of pixels in NeoPixel strip
// Argument 2 = Arduino pin number (most are valid)
// Argument 3 = Pixel type flags, add together as needed:
//   NEO_KHZ800  800 KHz bitstream (most NeoPixel products w/WS2812 LEDs)
//   NEO_KHZ400  400 KHz (classic 'v1' (not v2) FLORA pixels, WS2811 drivers)
//   NEO_GRB     Pixels are wired for GRB bitstream (most NeoPixel products)
//   NEO_RGB     Pixels are wired for RGB bitstream (v1 FLORA pixels, not v2)
//   NEO_RGBW    Pixels are wired for RGBW bitstream (NeoPixel RGBW products)

/*=========================================================================
    APPLICATION SETTINGS

      FACTORYRESET_ENABLE       Perform a factory reset when running this sketch
     
                                Enabling this will put your Bluefruit LE module
                              in a 'known good' state and clear any config
                              data set in previous sketches or projects, so
                                running this at least once is a good idea.
     
                                When deploying your project, however, you will
                              want to disable factory reset by setting this
                              value to 0.  If you are making changes to your
                                Bluefruit LE device via AT commands, and those
                              changes aren't persisting across resets, this
                              is the reason why.  Factory reset will erase
                              the non-volatile memory where config data is
                              stored, setting it back to factory default
                              values.
         
                                Some sketches that require you to bond to a
                              central device (HID mouse, keyboard, etc.)
                              won't work at all with this feature enabled
                              since the factory reset will clear all of the
                              bonding data stored on the chip, meaning the
                              central device won't be able to reconnect.
    MINIMUM_FIRMWARE_VERSION  Minimum firmware version to have some new features
    MODE_LED_BEHAVIOUR        LED activity, valid options are
                              "DISABLE" or "MODE" or "BLEUART" or
                              "HWUART"  or "SPI"  or "MANUAL"
    -----------------------------------------------------------------------*/
#define FACTORYRESET_ENABLE         1
#define MINIMUM_FIRMWARE_VERSION    "0.6.6"
#define MODE_LED_BEHAVIOUR          "MODE"
/*=========================================================================*/


/* ...hardware SPI, using SCK/MOSI/MISO hardware SPI pins and then user selected CS/IRQ/RST */
Adafruit_BluefruitLE_SPI ble(BLUEFRUIT_SPI_CS, BLUEFRUIT_SPI_IRQ, BLUEFRUIT_SPI_RST);



// A small helper
void error(const __FlashStringHelper*err) {
  Serial.println(err);
  while (1);
}

// setup() function -- runs once at startup --------------------------------
void setup(void)
{ 
  delay(500);

  strip.begin();
  for (int pin_index = 0; pin_index < NUM_PINS; pin_index++) {
    strip.setPin(PIN_NUMBERS[pin_index]);
    strip.show(); // Turn off all pixels to start.
    strip.setBrightness(DEFAULT_BRIGHTNESS);
  }

  Serial.begin(115200);
  /* Initialise the module */
  Serial.print(F("Initialising the Bluefruit LE module: "));

  if ( !ble.begin(VERBOSE_MODE) )
  {
    error(F("Couldn't find Bluefruit, make sure it's in CoMmanD mode & check wiring?"));
  }
  Serial.println( F("OK!") );

  if ( FACTORYRESET_ENABLE )
  {
    /* Perform a factory reset to make sure everything is in a known state */
    Serial.println(F("Performing a factory reset: "));
    if ( ! ble.factoryReset() ) {
      error(F("Couldn't factory reset"));
    }
  }

  /* Disable command echo from Bluefruit */
  ble.echo(false);

  ble.verbose(false);  // debug info is a little annoying after this point!

  /* Wait for connection */
  while (! ble.isConnected()) {
    delay(500);
  }

  Serial.println(F("******************************"));

  // LED Activity command is only supported from 0.6.6
  if ( ble.isVersionAtLeast(MINIMUM_FIRMWARE_VERSION) )
  {
    // Change Mode LED Activity
    Serial.println(F("Change LED activity to " MODE_LED_BEHAVIOUR));
    ble.sendCommandCheckOK("AT+HWModeLED=" MODE_LED_BEHAVIOUR);
  }

  // Set module to DATA mode
  Serial.println( F("Switching to DATA mode!") );
  ble.setMode(BLUEFRUIT_MODE_DATA);

  Serial.println(F("******************************"));

}

/**************************************************************************/
/*!
    @brief  Constantly poll for new command or response data
*/
/**************************************************************************/

uint16_t offset = 0;
long firstPixelHue = 0;

// Rainbow cycle along whole strip. Pass delay time (in ms) between frames.
void rainbow() {
  // Hue of first pixel runs 5 complete loops through the color wheel.
  // Color wheel has a range of 65536 but it's OK if we roll over, so
  // just count from 0 to 5*65536. Adding 256 to firstPixelHue each time
  // means we'll make 5*65536/256 = 1280 passes through this outer loop:
  for(long firstPixelHue = 0; firstPixelHue < 2*65536; firstPixelHue += 256) {
    for (int pin_index = 0; pin_index < NUM_PINS; pin_index++) {
      int pinNum = PIN_NUMBERS[pin_index];
      strip.setPin(pinNum);
    
      for(int i=0; i<strip.numPixels(); i++) { // For each pixel in strip...
        // Offset pixel hue by an amount to make one full revolution of the
        // color wheel (range of 65536) along the length of the strip
        // (strip.numPixels() steps):
        int pixelHue = firstPixelHue + (i * 65536L / strip.numPixels());
        // strip.ColorHSV() can take 1 or 3 arguments: a hue (0 to 65535) or
        // optionally add saturation and value (brightness) (each 0 to 255).
        // Here we're using just the single-argument hue variant. The result
        // is passed through strip.gamma32() to provide 'truer' colors
        // before assigning to each pixel:
        strip.setPixelColor(i, strip.gamma32(strip.ColorHSV(pixelHue)));
      }
      strip.show(); // Update strip with new contents
      delay(1);  // Pause for a moment
    }
  }
}

void fire(int cooling, int sparking, int speedDelay) {
  static byte heat[STRIPLEN];
  int cooldown;
  
  // Step 1.  Cool down every cell a little
  for( int i = 0; i < STRIPLEN; i++) {
    cooldown = random(0, ((cooling * 10) / STRIPLEN) + 2);
    
    if(cooldown>heat[i]) {
      heat[i]=0;
    } else {
      heat[i]=heat[i]-cooldown;
    }
  }
  
  // Step 2.  Heat from each cell drifts 'up' and diffuses a little
  for( int k= STRIPLEN - 1; k >= 2; k--) {
    heat[k] = (heat[k - 1] + heat[k - 2] + heat[k - 2]) / 3;
  }
    
  // Step 3.  Randomly ignite new 'sparks' near the bottom
  if( random(255) < sparking ) {
    int y = random(7);
    heat[y] = heat[y] + random(160,255);
    //heat[y] = random(160,255);
  }

  // Step 4.  Convert heat to LED colors
  for (int pin_index = 0; pin_index < NUM_PINS; pin_index++) {
    int pinNum = PIN_NUMBERS[pin_index];
    strip.setPin(pinNum);
    for( int j = 0; j < STRIPLEN; j++) {
      setPixelHeatColor(j, heat[j] );
    }
    strip.show();
  }

  delay(speedDelay);
}

void breathe(int timeDelay) {
  float speedFactor = 0.008;
  
  // Make the lights breathe
  for (int i = 0; i < 1000; i++) {
    // Intensity will go from 10 - MaximumBrightness in a "breathing" manner
    float intensity = 255 /2.0 * (1.0 + sin(speedFactor * i));
    for (int pin_index = 0; pin_index < NUM_PINS; pin_index++) {
      int pinNum = PIN_NUMBERS[pin_index];
      strip.setPin(pinNum);

      strip.setBrightness(intensity);
      
      for (int ledNumber=0; ledNumber<STRIPLEN; ledNumber++) {
        strip.setPixelColor(ledNumber, currentColor);
      }
      strip.show();
    }
    //Wait a bit before continuing to breathe
    delay(timeDelay);
  }
}

void setPixelHeatColor (int pixelIndex, byte temperature) {
  // Scale 'heat' down from 0-255 to 0-191
  byte t192 = round((temperature/255.0)*191);
 
  // calculate ramp up from
  byte heatramp = t192 & 0x3F; // 0..63
  heatramp <<= 2; // scale up to 0..252

  // specified color breakdown
  uint8_t r, g, b;
  r = (currentColor & RED_BITMASK) >> 8;
  g = (currentColor & GREEN_BITMASK) >> 16;
  b = (currentColor & BLUE_BITMASK);

  // This makes the fire come from the tips of the hair. 
  // To come from the "roots", just set pixelToSet to pixelIndex.
  int pixelToSet = STRIPLEN - pixelIndex; 
  // A total hack to support differnet color fires:
  if (g >= 128 & r == 0 && b == 0) {
    // green fire.
    // figure out which third of the spectrum we're in:
    if( t192 > 0x80) {                     // hottest
      strip.setPixelColor(pixelToSet, 255, 255, heatramp, 0);
    } else if( t192 > 0x40 ) {             // middle
      strip.setPixelColor(pixelToSet, 255, heatramp, 0, 0);
    } else {                               // coolest
      strip.setPixelColor(pixelToSet, heatramp, 0, 0, 0);
    }
  } else if (r >= 128 & g == 0 && b == 0) {
    // red spectrum fire. 
    if( t192 > 0x80) {                     // hottest
      strip.setPixelColor(pixelToSet, 255, 255, heatramp, 0);
    } else if( t192 > 0x40 ) {             // middle
      strip.setPixelColor(pixelToSet, heatramp, 255, 0, 0);
    } else {                               // coolest
      strip.setPixelColor(pixelToSet, 0, heatramp, 0, 0);
    }
  } else if (b >= 128 & r == 0 && g == 0) {
    // blue spectrum fire.
    if( t192 > 0x80) {                     // hottest
      strip.setPixelColor(pixelToSet, 255, 255, heatramp, 0);
    } else if( t192 > 0x40 ) {             // middle
      strip.setPixelColor(pixelToSet, 0, heatramp, 255, 0);
    } else {                               // coolest
      strip.setPixelColor(pixelToSet, 0, 0, heatramp, 0);
    }
  } else if (r >= 128 & g >= 128 && b == 0) {
    // "yellow" spectrum fire.
    if( t192 > 0x80) {                     // hottest
      strip.setPixelColor(pixelToSet, 255, 255, heatramp, 0);
    } else if( t192 > 0x40 ) {             // middle
      strip.setPixelColor(pixelToSet, heatramp, 255, 0, 0);
    } else {                               // coolest
      strip.setPixelColor(pixelToSet, heatramp, heatramp, 0, 0);
    }
  } else {
    // white-ish fire.
    if( t192 > 0x80) {                     // hottest
      strip.setPixelColor(pixelToSet, 0, 0, 0, 255);
    } else if( t192 > 0x40 ) {             // middle
      strip.setPixelColor(pixelToSet, 0, 0, heatramp, 255);
    } else {                               // coolest
      strip.setPixelColor(pixelToSet, 0, 0, 0, heatramp);
    }
  } 
}

void meteorRain(byte meteorSize, byte meteorTrailDecay, boolean meteorRandomDecay, int SpeedDelay) {  
  for (int pin_index = 0; pin_index < NUM_PINS; pin_index++) {
      int pinNum = PIN_NUMBERS[pin_index];
      strip.setPin(pinNum);
    strip.clear();
    strip.show();
  }

  byte r, g, b, w;
  r = (currentColor & RED_BITMASK) >> 8;
  g = (currentColor & GREEN_BITMASK) >> 16;
  b = (currentColor & BLUE_BITMASK);
  w = (currentColor & WHITE_BITMASK) >> 24;
  
  for(int i = 0; i < STRIPLEN+STRIPLEN; i++) { 
    for (int pin_index = 0; pin_index < NUM_PINS; pin_index++) {
      int pinNum = PIN_NUMBERS[pin_index];
      strip.setPin(pinNum);
      // fade brightness all LEDs one step
      for(int j=0; j<STRIPLEN; j++) {
        if( (!meteorRandomDecay) || (random(10)>5) ) {
          fadeToBlack(j, meteorTrailDecay );        
        }
      }
      
      // draw meteor
      for(int j = 0; j < meteorSize; j++) {
        if( ( i-j <STRIPLEN) && (i-j>=0) ) {
          strip.setPixelColor(i-j, g, r, b, w); //red, green, blue);
        } 
      }
     
      strip.show();
    }
    delay(SpeedDelay);
  }
}

// used by meteorrain
void fadeToBlack(int ledNo, byte fadeValue) {
    // NeoPixel
    uint32_t oldColor;
    uint8_t r, g, b, w;
    int value;
    
    oldColor = strip.getPixelColor(ledNo);
    r = (oldColor & RED_BITMASK) >> 8;
    g = (oldColor & GREEN_BITMASK) >> 16;
    b = (oldColor & BLUE_BITMASK);
    w = (oldColor & WHITE_BITMASK) >> 24;
    // TODO: these are going to have to change.
    //r = (oldColor & 0x00ff0000UL) >> 16;
    //g = (oldColor & 0x0000ff00UL) >> 8;
    //b = (oldColor & 0x000000ffUL);

    r=(r<=10)? 0 : (int) r-(r*fadeValue/256);
    g=(g<=10)? 0 : (int) g-(g*fadeValue/256);
    b=(b<=10)? 0 : (int) b-(b*fadeValue/256);
    w=(w<=10)? 0 : (int) w-(w*fadeValue/256);
    
    strip.setPixelColor(ledNo, g, r, b, w);
}

void twinkle(int count, int speedDelay) {
  strip.clear();
  
  for (int i=0; i<count; i++) {
    for (int pin_index = 0; pin_index < NUM_PINS; pin_index++) {
      int pinNum = PIN_NUMBERS[pin_index];
      strip.setPin(pinNum); 
      strip.setPixelColor(random(STRIPLEN), currentColor);
      strip.show();
    }
     delay(speedDelay);
   }
  
  delay(speedDelay);
}

void bouncingBalls(int ballCount) {
  float Gravity = -9.81;
  int StartHeight = 1;
  
  float Height[ballCount];
  float ImpactVelocityStart = sqrt( -2 * Gravity * StartHeight );
  float ImpactVelocity[ballCount];
  float TimeSinceLastBounce[ballCount];
  int   Position[ballCount];
  long  ClockTimeSinceLastBounce[ballCount];
  float Dampening[ballCount];
  boolean ballBouncing[ballCount];
  boolean ballsStillBouncing = true;
  
  for (int i = 0 ; i < ballCount ; i++) {   
    ClockTimeSinceLastBounce[i] = millis();
    Height[i] = StartHeight;
    Position[i] = 0; 
    ImpactVelocity[i] = ImpactVelocityStart;
    TimeSinceLastBounce[i] = 0;
    Dampening[i] = 0.90 - float(i)/pow(ballCount,2);
    ballBouncing[i]=true; 
  }

  while (ballsStillBouncing) {
    for (int pin_index = 0; pin_index < NUM_PINS; pin_index++) {
      int pinNum = PIN_NUMBERS[pin_index];
      strip.setPin(pinNum); 
      for (int i = 0 ; i < ballCount ; i++) {
        TimeSinceLastBounce[i] =  millis() - ClockTimeSinceLastBounce[i];
        Height[i] = 0.5 * Gravity * pow( TimeSinceLastBounce[i]/1000 , 2.0 ) + ImpactVelocity[i] * TimeSinceLastBounce[i]/1000;
    
        if ( Height[i] < 0 ) {                      
          Height[i] = 0;
          ImpactVelocity[i] = Dampening[i] * ImpactVelocity[i];
          ClockTimeSinceLastBounce[i] = millis();
    
          if ( ImpactVelocity[i] < 0.01 ) {
            ballBouncing[i]=false;
          }
        }
        Position[i] = round( Height[i] * (STRIPLEN - 1) / StartHeight);
      }
  
      ballsStillBouncing = false; // assume no balls bouncing
      for (int i = 0 ; i < ballCount ; i++) {
        strip.setPixelColor(STRIPLEN - Position[i], currentColor);
        if ( ballBouncing[i] ) {
          ballsStillBouncing = true;
        }
      }
      
      strip.show();
      strip.clear();
    }
  }
}

void pixelLine(int color, int numLeds, bool clearStrip, int delayTime) {
  if (clearStrip) strip.clear();
  for (uint16_t i = 0; i < numLeds; i++) {
    strip.setPixelColor(i + offset, color);
  }
  delay(delayTime);
}

void sparkle() {
  // if colorUpdate is true, we need to set all the other strands we didn't set to the solid new color.
  for (int pin_index = 0; pin_index < NUM_PINS; pin_index++) {
    int pinNum = PIN_NUMBERS[pin_index];
    strip.setPin(pinNum);
    strip.clear();

    strip.setPixelColor(random(STRIPLEN), currentColor);
    strip.setPixelColor(random(STRIPLEN), currentColor);
    strip.setPixelColor(random(STRIPLEN), currentColor);
    strip.setPixelColor(random(STRIPLEN), currentColor);
    delay(50);
    strip.show();
  }
}

void runningLights(int timeDelay) {
  int cur_pos=0;
  uint8_t r, g, b, w;
  r = (currentColor & RED_BITMASK) >> 8;
  g = (currentColor & GREEN_BITMASK) >> 16;
  b = (currentColor & BLUE_BITMASK);
  w = (currentColor & WHITE_BITMASK) >> 24;
  
  for(int i=0; i<STRIPLEN*2; i++)
  {
    cur_pos++; // = 0; //Position + Rate;
    for (int pin_index = 0; pin_index < NUM_PINS; pin_index++) {
      int pinNum = PIN_NUMBERS[pin_index];
      strip.setPin(pinNum);
      for(int i=0; i<STRIPLEN; i++) {
        // sine wave, 3 offset waves make a rainbow!
        //float level = sin(i+cur_pos) * 127 + 128;
        //strip.setPixelColor((i,level,0,0, 0);
        //float level = sin(i+cur_pos) * 127 + 128;
        float value = (sin(i+cur_pos) * 127 + 128)/255;
        strip.setPixelColor(i,value*r,
                              value*g,
                              value*b,
                              value*w);
      }
      
      strip.show();
    }
    delay(timeDelay);
  }
}

void wholeStripColor() {
  for( int i = 0; i < STRIPLEN; i++) {
    strip.setPixelColor(i, currentColor);
  }
}

void drawPixels() {
  // Show the current color tag in the Serial Monitor.
  Serial.println("");
  Serial.print("Current mode: ");
  Serial.println((char)currentMode);
  Serial.print("Current color (if applicable): ");
  Serial.println(currentColor);

  updatePixels();
}

void pollBluetooth() {
  // Check for user input
  char n, inputs[BUFSIZE + 1];

  if (Serial.available())
  {
    n = Serial.readBytes(inputs, BUFSIZE);
    inputs[n] = 0;
    // Send characters to Bluefruit
    Serial.print("Sending: ");
    Serial.println(inputs);

    // Send input data to host via Bluefruit
    ble.print(inputs);
  }

  // Echo received data
  while ( ble.available() )
  {
    int command = ble.read();

    Serial.print((char)command);

    receivedInput = command;

    // Hex output too, helps w/debugging!
    Serial.print(" [0x");
    if (command <= 0xF) Serial.print(F("0"));
    Serial.print(command, HEX);
    Serial.print("] ");
  }
}

void updatePixels() {
  uint8_t newMode = 0;
  uint32_t newColor = 0;
  bool colorUpdate = false; // only used for some effects that are applied to a subset of strips.
  switch (receivedInput) {
    case 'r':
      newColor = strip.Color(0, 255, 0, 0);
      break;
    case 'y':
      newColor = strip.Color(255, 255, 0, 0);
      break;
    case 'g':
      newColor = strip.Color(255, 0, 0, 0);
      break;
    case 'b':
      newColor = strip.Color(0, 0, 255, 0);
      break;
    case 'w':
      newColor = strip.Color(255, 255, 255, 255);
      break;
    default:
      // assume everything else is a "mode" signifier.
      newMode = receivedInput;
  }
  if (newMode != 0 && newMode != currentMode) {
    currentMode = newMode;
    // clear everything if changing modes.
    for (int pin_index = 0; pin_index < NUM_PINS; pin_index++) {
      int pinNum = PIN_NUMBERS[pin_index];
      strip.setPin(pinNum);
      strip.clear();
      strip.setBrightness(DEFAULT_BRIGHTNESS);
      strip.show();
    }
    offset = 0;
  }
  if (newColor != 0 && newColor != currentColor) {
    currentColor = newColor;
    colorUpdate = true;
  }

  if (currentMode == 's') {
    sparkle();
  } else if (currentMode == 'o') {
    rainbow();
  } else if (currentMode == 'e') {
    meteorRain(4, 10, true, 75);
  } else if (currentMode == 'f') {
    // Fire - Cooling rate, Sparking rate, speed delay
    fire(90,120,15);
  } else if (currentMode == 't') {
    // Twinkle - Color (red, green, blue), count, speed delay, only one twinkle (true/false) 
    twinkle(10, 100);
  } else if (currentMode == 'a') {
    bouncingBalls(3);
  } else if (currentMode == 'n') {
    runningLights(50);
  } else if (currentMode == 'h') {
    breathe(1);
  } else if (currentMode == 'l') {
    for (int pin_index = 0; pin_index < NUM_PINS; pin_index++) {
      int pinNum = PIN_NUMBERS[pin_index];
      strip.setPin(pinNum);
      pixelLine(currentColor, 1, false, 50);
      strip.show();
    }
    offset = (offset + 1) % (STRIPLEN);
  } else if (currentMode == 'm') {
    for (int pin_index = 0; pin_index < NUM_PINS; pin_index++) {
      int pinNum = PIN_NUMBERS[pin_index];
      strip.setPin(pinNum);
      pixelLine(currentColor, 10, true, 80);
      strip.show();
    }
    // Add one to the offset, and set it back to 0 when
    // we reach the end.
    offset = (offset + 1) % (STRIPLEN);
  }
  
}

void loop(void)
{
  pollBluetooth();
  drawPixels();
}
