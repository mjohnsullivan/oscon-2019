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

// Communication "protocol":
// 'r' = red
// 'b' = blue
// 'y' = yellow
// 'g' = green
// 'w' = white
// 's' = sparkles
// 'm' = march, a set of (currently 10) pixels march down the strip.
// 'e' = meteor rain
// 'f' = fire
// 'o' = rainbow
//  'l' = light spill, that is, spill down the pixel strip and stay on with a given color.
// Any other character sets all pixels to off.
uint8_t currentMode = 'l';
uint32_t currentColor = 0;
uint8_t receivedInput = 'o';
unsigned long RED_BITMASK = 0x00ff0000UL;
unsigned long GREEN_BITMASK = 0x0000ff00UL;
unsigned long BLUE_BITMASK = 0x000000ffUL;
unsigned long WHITE_BITMASK = 0xff000000UL;


// The board pins that are connected to Neopixel strips.
static int PIN_NUMBERS[5] = { 5, 6, 10, 11, 12 };
#define STRIPLEN 15 // Length of LED strips
#define NUM_PINS 5 // the number of pins that are connected to neopixel strips.


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
    strip.setBrightness(50); // Set BRIGHTNESS to about 1/5 (max = 255)
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
  for(long firstPixelHue = 0; firstPixelHue < 5*65536; firstPixelHue += 256) {
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
  for( int j = 0; j < STRIPLEN; j++) {
    setPixelHeatColor(j, heat[j] );
  }

  strip.show();
  delay(speedDelay);
}

void setPixelHeatColor (int pixelIndex, byte temperature) {
  // Scale 'heat' down from 0-255 to 0-191
  byte t192 = round((temperature/255.0)*191);
 
  // calculate ramp up from
  byte heatramp = t192 & 0x3F; // 0..63
  heatramp <<= 2; // scale up to 0..252

  // specified color breakdown
  uint8_t r, g, b, w;
  r = (currentColor & RED_BITMASK) >> 16;
  g = (currentColor & GREEN_BITMASK) >> 8;
  b = (currentColor & BLUE_BITMASK);
  w = (currentColor & WHITE_BITMASK);

  // A total hack to support differnet color fires:
  if (r >= 128 & g == 0 && b == 0) {
    // red fire.
    // figure out which third of the spectrum we're in:
    if( t192 > 0x80) {                     // hottest
      strip.setPixelColor(pixelIndex, 255, 255, heatramp, 0);
    } else if( t192 > 0x40 ) {             // middle
      strip.setPixelColor(pixelIndex, 255, heatramp, 0, 0);
    } else {                               // coolest
      strip.setPixelColor(pixelIndex, heatramp, 0, 0, 0);
    }
  } else if (g >= 128 & r == 0 && b == 0) {
    // green spectrum fire. 
    if( t192 > 0x80) {                     // hottest
      strip.setPixelColor(pixelIndex, 255, 255, heatramp, 0);
    } else if( t192 > 0x40 ) {             // middle
      strip.setPixelColor(pixelIndex, 0, 255, heatramp, 0);
    } else {                               // coolest
      strip.setPixelColor(pixelIndex, 0, heatramp, 0, 0);
    }
  } else if (b >= 128 & r == 0 && b == 0) {
    // blue spectrum fire.
    if( t192 > 0x80) {                     // hottest
      strip.setPixelColor(pixelIndex, 255, 255, heatramp, 0);
    } else if( t192 > 0x40 ) {             // middle
      strip.setPixelColor(pixelIndex, 0, heatramp, 255, 0);
    } else {                               // coolest
      strip.setPixelColor(pixelIndex, 0, 0, heatramp, 0);
    }
  } else if (r >= 128 & g >= 128 && b == 0) {
    // "yellow" spectrum fire.
    if( t192 > 0x80) {                     // hottest
      strip.setPixelColor(pixelIndex, 255, 255, heatramp, 0);
    } else if( t192 > 0x40 ) {             // middle
      strip.setPixelColor(pixelIndex, heatramp, heatramp, 0, 0);
    } else {                               // coolest
      strip.setPixelColor(pixelIndex, heatramp, 0, 0, 0);
    }
  } else if (w > 0) {
    // white-ish fire.
    if( t192 > 0x80) {                     // hottest
      strip.setPixelColor(pixelIndex, 0, 0, heatramp, 255);
    } else if( t192 > 0x40 ) {             // middle
      strip.setPixelColor(pixelIndex, 0, heatramp, 0, 255);
    } else {                               // coolest
      strip.setPixelColor(pixelIndex, 0, 0, 0, heatramp);
    }
  } else {
    // some weird fallback attempting to incorporate the values, still red-ish:
    if( t192 > 0x80) {                     // hottest
      strip.setPixelColor(pixelIndex, r, g, heatramp, 0);
    } else if( t192 > 0x40 ) {             // middle
      strip.setPixelColor(pixelIndex, r, heatramp, 0, 0);
    } else {                               // coolest
      strip.setPixelColor(pixelIndex, heatramp, 0, 0, 0);
    }
  }
}

void meteorRain(byte meteorSize, byte meteorTrailDecay, boolean meteorRandomDecay, int speedDelay) {  
  strip.clear();
  
  for(int i = 0; i < STRIPLEN+STRIPLEN; i++) {
    for (int pin_index = 0; pin_index < NUM_PINS; pin_index++) { ///
      int pinNum = PIN_NUMBERS[pin_index]; ///
      strip.setPin(pinNum); ///
    
      // fade brightness all LEDs one step
      for(int j=0; j<STRIPLEN; j++) {
        if( (!meteorRandomDecay) || (random(10)>5) ) {
          fadeToBlack(j, meteorTrailDecay );        
        }
      }
      
      // draw meteor
      for(int j = 0; j < meteorSize; j++) {
        if( ( i-j <STRIPLEN) && (i-j>=0) ) {
          strip.setPixelColor(i-j, currentColor);
        } 
      }
    }
   
    strip.show();
    delay(speedDelay);
  }
}

// used by meteorrain
void fadeToBlack(int neoPixelIndex, byte fadeValue) {
    uint32_t oldColor;
    uint8_t r, g, b;
    int value;
    
    oldColor = strip.getPixelColor(neoPixelIndex);
    r = (oldColor & RED_BITMASK) >> 16;
    g = (oldColor & GREEN_BITMASK) >> 8;
    b = (oldColor & BLUE_BITMASK);

    r=(r<=10)? 0 : (int) r-(r*fadeValue/256);
    g=(g<=10)? 0 : (int) g-(g*fadeValue/256);
    b=(b<=10)? 0 : (int) b-(b*fadeValue/256);
    
    strip.setPixelColor(neoPixelIndex, r,g,b, 0); 
}

void pixelLine(int color, int numLeds, bool clearStrip, int delayTime) {
  if (clearStrip) strip.clear();
  for (uint16_t i = 0; i < numLeds; i++) {
    strip.setPixelColor(i + offset, color);
  }
  delay(delayTime);
}

void sparkle(int color) {
  strip.clear();

  strip.setPixelColor(random(STRIPLEN), color);
  strip.setPixelColor(random(STRIPLEN), color);
  strip.setPixelColor(random(STRIPLEN), color);
  strip.setPixelColor(random(STRIPLEN), color);
  delay(50);
}

void drawPixels() {
  // Show the current color tag in the Serial Monitor.
  Serial.println("");
  Serial.print("Current mode: ");
  Serial.println(currentMode);
  Serial.print("Current color (if applicable): ");
  Serial.println(currentColor);

  switch (receivedInput) {
    case 'w':
      rainbow();
    default: 
      updatePixels();
  }
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
  // TODO: might need to  clear strip if we are switching the mode.
  
  switch (receivedInput) {
    case 'r':
      Serial.println("red");
      currentColor = strip.Color(0, 128, 0, 0);
      break;
    case 'y':
      currentColor = strip.Color(128, 128, 0, 0);
      break;
    case 'g':
      currentColor = strip.Color(128, 0, 0, 0);
      break;
    case 'b':
      currentColor = strip.Color(0, 0, 128, 0);
      break;
    case 'w':
      currentColor = strip.Color(255, 255, 255, 255);
      break;
    default:
      // assume everything else is a "mode" signifier.
      currentMode = receivedInput;
  }

  if (currentMode == 's') {
    // for performance reasons (otherwise our little board can't keep up) 
    // we do this loop in here, rather than at the highest level.
    for (int pin_index = 0; pin_index < NUM_PINS; pin_index++) {
      int pinNum = PIN_NUMBERS[pin_index];
      strip.setPin(pinNum);
      sparkle(currentColor);
      strip.show();
    }
  } else if (currentMode = 'e') {
    meteorRain(10, 64, true, 30);
  } else if (currentMode = 'f') {
    // Fire - Cooling rate, Sparking rate, speed delay
    fire(55,120,15);
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
      pixelLine(currentColor, 10, true, 150);
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
