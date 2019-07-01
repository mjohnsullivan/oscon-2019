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

// Communication protocol:
// 'r' = red
// 'b' = blue
// 'y' = yellow
// 'g' = green
// 's' = sparkles
// 'w' = rainbow
// Any other character sets all pixels to off.
// TODO(efortuna): start with rainbow on.
uint8_t currentMode = 'b';

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

void pixelLine(int color) {
  strip.clear();
  // Show a chosen color on 10 pixels. This 10-pixel segment
  // moves across the strip, using an offset.
  // The Adafruit_NeoPixel library is forgiving: when this
  // offset causes some of the pixels to move off the end of the
  // strip, we don't get a range error. Yay.
  for (uint16_t i = 0; i < 10; i++) {
    strip.setPixelColor(i + offset, color);
  }
  delay(150);
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

  switch (currentMode) {
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

    currentMode = command;

    // Hex output too, helps w/debugging!
    Serial.print(" [0x");
    if (command <= 0xF) Serial.print(F("0"));
    Serial.print(command, HEX);
    Serial.print("] ");
  }
}

void updatePixels() {
  
  uint32_t aCol = strip.Color(0, 0, 0, 0);  

  // When change colors/animations based on a single character
  // coming over Bluetooth LE UART from the mobile device.
  // red: 'r', yellow: 'y', green: 'g', and blue: 'b'
  //
  // We also have a special sparkly white pattern: 's'.
  //
  // Any other character sets all pixels to off.
  switch (currentMode) {
    case 'r':
      Serial.println("red");
      aCol = strip.Color(0, 128, 0, 0);
      break;
    case 'y':
      aCol = strip.Color(128, 128, 0, 0);
      break;
    case 'g':
      aCol = strip.Color(128, 0, 0, 0);
      break;
    case 'b':
      aCol = strip.Color(0, 0, 128, 0);
      break;
    default:
      Serial.println("default");
      aCol = strip.Color(0, 0, 0, 0);
      break;
  }

  if (currentMode == 's') {
    // for performance reasons (otherwise our little board can't keep up) 
    // we do this loop in here, rather than at the highest level.
    for (int pin_index = 0; pin_index < NUM_PINS; pin_index++) {
      int pinNum = PIN_NUMBERS[pin_index];
      strip.setPin(pinNum);
      sparkle(strip.Color(255, 255, 255, 255));
      strip.show();
    }
  } else {
    for (int pin_index = 0; pin_index < NUM_PINS; pin_index++) {
      int pinNum = PIN_NUMBERS[pin_index];
      strip.setPin(pinNum);
      pixelLine(aCol);
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
  // it's too slow to do all simultaneously. so  fill it up, and then pick a random one to do the effect to. then fill it up again.
  // or have all off and do effect to.
  //TODO
  //pixelLine(strip.Color(0, 0, 128, 0));
  //strip.show();
  drawPixels();
}
