# ATmega128 F´ LED Blinker

The [F´ Arduino LED Blinker tutorial](https://fprime.jpl.nasa.gov/latest/tutorials-arduino-led-blinker/docs/arduino-led-blinker/)
([fprime-tutorial-arduino-blinker](https://github.com/fprime-community/fprime-tutorial-arduino-blinker)), ported to
the ATmega128, an 8-bit AVR with 128 KB of flash and up to 64 KB of SRAM (using XMEM).

The `Led` component and its wiring are the tutorial's. The deployment comes from the
[ATmega128 deployment cookiecutter](https://github.com/nathancheek/fprime-atmega128-deployment-cookiecutter), an
ATmega128 version of the [Arduino deployment cookiecutter](https://github.com/fprime-community/fprime-arduino-deployment-cookiecutter)
the tutorial uses.

For a deployment with a lighter communications stack and more features, see
[fprime-atmega128-demo](https://github.com/nathancheek/fprime-atmega128-demo).

## Changes from the Arduino LED Blinker tutorial

The ATmega128 deployment cookiecutter makes these changes from the Arduino deployment cookiecutter:

* Enables the 64 KB external SRAM at startup
* Puts the F´ ground link on UART1, so UART0 stays the programming and console port
* Drives the rate groups from a 100 ms Timer1 tick, with a 10 Hz group that polls the ground link and a 1 Hz group for
  telemetry, commands and the `Led` component
* Drops the text logger and system resources components
* Turns off object names, registration, port tracing, port serialization, text logging and `toString`, and uses file
  ID asserts, to fit in flash

## Framing

The deployment uses CCSDS framing and works with the stock F´ GDS.

The UART driver blocks while it sends, and at 115200 baud F´'s default 1024-byte TM frame takes about 89 ms. The
cookiecutter shrinks the frame to 128 bytes (about 11 ms) by overriding `ComCfg.TmFrameFixedSize`, and turns on packet
spanning so packets can continue into the next frame. It also sends partly filled frames from the 10 Hz rate group,
since the aggregator otherwise waits for a frame to fill. F´ GDS reads the frame size from the dictionary and
reassembles packets that span frames.

## Hardware

* ATmega128 with [MegaCore](https://github.com/MCUdude/MegaCore) and a bootloader that uploads over UART0 (for
  example urboot)
* 7.3728 MHz external crystal
* 64 KB of external SRAM on the XMEM interface
* A serial adapter on UART0 for programming and console output, and another on UART1 for the F´ ground link

## Getting started

Clone the project with its submodules, then set up a virtual environment:

```sh
git clone --recurse-submodules https://github.com/nathancheek/fprime-atmega128-blinker.git
cd fprime-atmega128-blinker
python3 -m venv fprime-venv
. fprime-venv/bin/activate
pip install -r requirements.txt
```

Then follow the [arduino-cli installation guide](https://github.com/fprime-community/fprime-arduino/blob/main/docs/arduino-cli-install.md)
and install MegaCore:

```sh
arduino-cli core install MegaCore:avr --additional-urls https://mcudude.github.io/MegaCore/package_MCUdude_MegaCore_index.json
```

Building, flashing and running F´ GDS are covered in the
[deployment's README](LedBlinker/LedBlinkerDeployment/README.md).
