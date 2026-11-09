# Donkey Kong Jr. - Digilent Basys 3

Donkey Kong Jr. (1982 Nintendo), FPGA core by gaz68 (2019, MiSTer) based on the Donkey
Kong core by Katsumi Degawa, based on Tang Nano 20K port by pinballwiz.org
(<https://github.com/pinballwizz/TangNano20K-DonkeyKongJr>).

## Hardware

- Digilent Basys 3 (Artix-7 `xc7a35tcpg236-1`).
- VGA monitor (31 kHz), or a 15 kHz TV/CRT (sw13, not tested).
- USB keyboard on the Basys 3 USB-HID host port.
- Optional: Atari-style joystick on Pmod JA, Digilent PmodAMP2 on Pmod JXADC.

## Build

Requirements:

- Vivado 2020.2, gcc, make, unzip, openFPGALoader.
- Romset `dkongjr.zip`.

```
make roms        # compile make_vhdl_prom, unzip ~/roms/dkongjr.zip, generate PROM VHDL
make bitstream   # Vivado batch build of basys3/dkongjr_basys3.xpr
make load        # program the xc7 in JTAG mode (jumper JP1 in the JTAG position)
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
| JA 1/2/3/4/7    | joystick right/left/down/up/jump (active low) |
| sw0-sw7         | DIP switches (down = default, see below)      |
| sw10-sw11       | sound options (down = default, see Sound)     |
| sw13 down       | 31 kHz VGA                                    |
| sw13 up         | 15 kHz TV, composite sync on HS (not tested)  |
| sw14 up         | scanlines, alternate lines at 50 %, 31 kHz    |
| sw15 up         | audio off (PmodAMP2 shutdown)                 |

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
| LUTs      | 3420       | 16.44%                         |
| Registers | 1435       | 3.45%                          |
| Block RAM | 33 tiles   | 66.00%                         |
| DSPs      | 0          | 0.00%                          |
| Clock     | 24.576 MHz | WNS +14.012 ns, WHS +0.068 ns  |

The core runs on the one 24.576 MHz clock. The slower clocks of the original design
are clock enables (core parameter `CLK_CE`).

## Core changes for the Basys 3 port

Changes to the core files in `src/dkongjr_verilog/` (shared with the Tang Nano 20K
project):

- Garbled sprites: sprite logic on clock enables (`dkongjr_obj.v`).
- Colour bleeding, flicker: tile colour logic on clock enables (`dkongjr_vram.v`,
  `dkongjr_col_pal.v`, `dkongjr_main.v`).
- Vivado synthesis error: PROM outputs as `wire` (`dkongjr_main.v`).
- Tile and sound CPU timing races: clock enables (`dkongjr_vram.v`, `i8035ip.v`, T48
  `clock_ctrl.vhd`, `t48_core.vhd`).
- Long implementation runs (timing repair between clocks): all remaining logic on
  clock enables (`dkongjr_main.v`, `dkongjr_adec.v`, `dkongjr_bram.v`, `dkongjr_dma.v`,
  `dkongjr_hv_count.v`, `dkongjr_sound.v`, `dkongjr_vram.v`, Z80 `T80as.vhd`).
- Wrong, missing, cut short or never-ending sounds, music without decay: sound options
  (`dkongjr_main.v`, `dkongjr_wav_sound.v`, new `dkongjr_wav_dma.v`, `dkongjr_dac.sv`,
  `dkongjr_iir_filter.v`), see Sound.

## Sound

Walk, jump, land and fall are played from samples (`tools/dkj_wave.bin`, 8-bit,
11 kHz) in place of the original board's analog sound circuits. The samples are MAME's
former `dkongjr` sample set (removed in MAME 0.122u2, separate from the `dkongjr.zip`
ROM set), at half rate, as used in the gaz68 MiSTer core
(<https://github.com/gaz68/Arcade-DonkeyKongJunior_MiSTer>).

The Basys 3 build restores the sound handling of that core, selectable with switches
(down = default):

| Switch | Down (default)          | Up         |
|--------|-------------------------|------------|
| sw11   | music/effects filter on | filter off |
| sw10   | music/effects decay on  | decay off  |

- Four-channel sample player (always used): sounds can overlap (e.g. walking during a
  jump), full sample ROM address and full sample lengths. The fall sound stops when the
  fall ends. The core's one-channel player option (`I_SND_OPT(0)`) is tied off in the
  Basys 3 top.

## Third-party additions

- `tools/tools_prom_src/src/make_vhdl_prom.c` (darfpga): PROM-to-VHDL converter,
  unmodified, from <https://github.com/pinballwizz/DE2-Xevious>.
- Sound, in `src/dkongjr_verilog/`, from the gaz68 MiSTer core
  <https://github.com/gaz68/Arcade-DonkeyKongJunior_MiSTer>:
  - `dkongjr_wav_dma.v` (gaz68): four-channel sample player, `dkongjr_wav_sound.v`
    there, module renamed, volume multiply optional.
  - `dkongjr_dac.sv` (gaz68): digital sound decay.
  - `dkongjr_iir_filter.v` (Gregory Hogan, MIT): low-pass filter.
  - All multiplies are kept out of DSP blocks.

## License

- The additions and changes made for the Basys 3 port are MIT licensed.
- Other code keeps the terms stated in its files. The core is freeware for
  non-commercial use.
- Roms and anything generated from them (PROM VHDL, bitstreams) are not distributed.
