# Donkey Kong Jr. - Digilent Basys 3

Donkey Kong Jr. (© 1982 Nintendo Co., Ltd.), FPGA core by gaz68 (2019, MiSTer) based on
the Donkey Kong core by Katsumi Degawa, Tang Nano 20K port by pinballwiz.org
(<https://github.com/pinballwizz/TangNano20K-DonkeyKongJr>), built here for the
Digilent Basys 3 (Artix-7 `xc7a35tcpg236-1`).

## Hardware

- Digilent Basys 3.
- VGA monitor (31 kHz), or a 15 kHz TV/CRT (sw13, not tested).
- USB keyboard on the Basys 3 USB-HID host port.
- Optional: Atari-style joystick on Pmod JXADC, Digilent PmodAMP2 on Pmod JA.

## Build

Requirements:

- Vivado 2020.2, gcc, make, unzip, openFPGALoader.
- Romset `dkongjr.zip`, supplied by the user. Roms are not part of this repository.

```
make roms        # compile make_vhdl_prom, unzip ~/roms/dkongjr.zip, generate PROM VHDL
make bitstream   # Vivado batch build of basys3/dkongjr_basys3.xpr
make load        # program the Basys 3 (SRAM), building first if the bitstream is outdated
make clean       # remove roms, PROM VHDL and Vivado outputs
```

- `ROMDIR=<dir>` or `ROMZIP=<zip>` selects the romset.
- `VIVADO=<path>` selects the Vivado binary.

## IO

| Input           | Function                                      |
|-----------------|-----------------------------------------------|
| Arrow keys      | move (keypad 8/2/4/6 also)                    |
| Left Ctrl       | jump                                          |
| 1 / 2           | start 1 player / 2 players                    |
| 5               | coin                                          |
| btnU, btnD      | coin                                          |
| btnL / btnR     | start 1 player / 2 players                    |
| btnC            | reset                                         |
| JXADC 1/2/3/4/7 | joystick right/left/down/up/jump (active low) |
| sw0-sw7         | DIP switches (down = default, see below)      |
| sw13 down       | 31 kHz VGA                                    |
| sw13 up         | 15 kHz TV, composite sync on HS (not tested)  |
| sw14 up         | PmodAMP2 gain                                 |
| sw15 up         | PmodAMP2 shutdown (mute)                      |

DIP switches (switch up inverts the default bit):

| Bits | Setting | Default         |
|------|---------|-----------------|
| 1:0  | lives   | 3               |
| 3:2  | bonus   | 10000           |
| 6:4  | coinage | 1 coin 1 credit |
| 7    | cabinet | upright         |

## Resource use

From a Vivado 2020.2 build:

| Resource  | Used       | Util.                          |
|-----------|------------|--------------------------------|
| LUTs      | 2284       | 10.98%                         |
| Registers | 1028       | 2.47%                          |
| Block RAM | 33 tiles   | 66.00%                         |
| DSPs      | 0          | 0.00%                          |
| Clock     | 24.576 MHz | WNS +15.392 ns, WHS +0.090 ns  |

## Core changes for the Basys 3 port

Changes to the core files in `src/dkongjr_verilog/` (shared with the Tang Nano 20K
project). The faults below were seen on the Basys 3 and not checked on the Tang Nano
20K.

- Garbled sprites: sprite logic on clock enables (`dkongjr_obj.v`).
- Colour bleeding, flicker: tile colour logic on clock enables (`dkongjr_vram.v`,
  `dkongjr_col_pal.v`, `dkongjr_main.v`).
- Vivado synthesis error: PROM outputs as `wire` (`dkongjr_main.v`).
- Sounds playing wrong samples: full wave ROM address on Basys 3 (`dkongjr_main.v`).

## Sound samples

- The original board makes the walk, jump, land and fall sounds with analog circuits.
  This core plays samples instead (`tools/dkj_wave.bin`, 48 KB, 8-bit unsigned,
  11 kHz).
- `dkj_wave.bin` is an 8-bit conversion of the 16-bit `releases/dkj_wave.bin` in
  gaz68's MiSTer core (<https://github.com/gaz68/Arcade-DonkeyKongJunior_MiSTer>).
- gaz68's samples are MAME's former `dkongjr` sample set (22 kHz WAVs, removed in
  MAME 0.122u2), at half the sample rate. Climb matches less closely than the others.
  That sample set is separate from the `dkongjr.zip` ROM set.
- Upstream reduces the sample ROM address to 13 bits to fit the Tang Nano 20K, so jump,
  land and fall play walk data there. The Basys 3 build uses the full address.
- Walk, land and fall still stop before the end of their sample data. The sound player
  (`dkongjr_wav_sound.v`) plays a set number of samples for each sound. For fall that
  is 0.5 s of the 1.8 s recorded. Full play lengths for the Basys 3 are planned as the
  next change.

## Third-party additions

- `tools/tools_prom_src/src/make_vhdl_prom.c`: PROM-to-VHDL converter by darfpga,
  unmodified from <https://github.com/pinballwizz/DE2-Xevious> (commit `a5d9eed`).

## License

- The additions and changes made for the Basys 3 port are MIT licensed.
- Other code keeps the terms stated in its files. The core is freeware for
  non-commercial use.
- Roms and anything generated from them (PROM VHDL, bitstreams) are not distributed.
