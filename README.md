# Carter's Computer Architecture Repo

## Overview

This repo contains System Verilog code and other coursework written as part of
the the Fall 2025 offering of Computer Architecture course at Olin College of 
Engineering taught by Brad Minch.

This course uses the iceBlinkPico, a small, breadboard-friendly dev board based
on the iCE40UP5K FPGA and designed by Brad. The design files, board, and all
example projects included in the `examples` folder are available in the original
[iceBlinkPico repository](https://github.com/bminch/iceBlinkPico/).

Compiling code in this repository for the iceBlinkPico requires the
`oss-cad-suite` bundle of digital logic design tools. Download this suite from
the [oss-cad-suite repository](https://github.com/YosysHQ/oss-cad-suite-build)
and ensure that the included binaries are added to the system `PATH`.

Everything seems to 'just work' on macOS Sequoia, and it theoretically should
do the same on Windows & Linux.

## Included Projects

### Mini-Project 1 (MP1): Colorwheel
This project rotates through the HSV colorwheel in 60 degree increments using the
built-in RGB LED of the iceBlinkPico.
