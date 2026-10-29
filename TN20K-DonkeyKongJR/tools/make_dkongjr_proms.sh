#!/bin/bash
# Generate the PROM VHDL from the dkongjr.zip romset into ../proms/ (port of
# make_dkongjr_proms.bat):
#   1. compile make_vhdl_prom into tools_prom_src/bin/
#   2. unzip ROMZIP (comma-separated) or ${ROMDIR:-~/roms}/dkongjr.zip into unzip/
#   3. write the PROM VHDL and the stamp .done into ../proms/
# make_vhdl_prom names the entity after the output file, so it writes into unzip/ and
# the result is moved. ../proms/ROMWAV.vhd is upstream and not generated here.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
PROM_DIR="$HERE/../proms"
UNZIP="$HERE/unzip"
TOOL="$HERE/tools_prom_src/bin/make_vhdl_prom"

if [ -n "${ROMZIP:-}" ]; then
    IFS=, read -r -a romzips <<< "$ROMZIP"
else
    romzips=("${ROMDIR:-$HOME/roms}/dkongjr.zip")
fi
for z in "${romzips[@]}"; do
    if [ ! -f "$z" ]; then
        echo "error: romset not found: $z (set ROMDIR or ROMZIP)" >&2
        exit 1
    fi
done

mkdir -p "$(dirname "$TOOL")" "$UNZIP" "$PROM_DIR"
gcc -w "$HERE/tools_prom_src/src/make_vhdl_prom.c" -lm -o "$TOOL"

for z in "${romzips[@]}"; do
    unzip -q -o "$z" -d "$UNZIP"
done
cd "$UNZIP"

prom() {
    "$TOOL" "$1" "$2"
    mv -f "$2" "$PROM_DIR/$2"
}

cat dkj.5b dkj.5c dkj.5e > dkongjr_cpu.bin
prom dkongjr_cpu.bin CPUROM.vhd

prom dkj.3n ROM3N.vhd
prom dkj.3p ROM3P.vhd

prom v_7c.bin ROM7C.vhd
prom v_7d.bin ROM7D.vhd
prom v_7e.bin ROM7E.vhd
prom v_7f.bin ROM7F.vhd

prom c-2e.bpr pal1_rom.vhd
prom c-2f.bpr pal2_rom.vhd
prom v-2n.bpr col_rom.vhd

prom c_3h.bin snd_rom.vhd

touch "$PROM_DIR/.done"   # stamp for the Makefile bitstream prerequisite
echo "PROM VHDL in $PROM_DIR:"
ls -1 "$PROM_DIR"
