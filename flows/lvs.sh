#!/usr/bin/env sh
# netgen LVS of an extracted cell against the PDK's schematic netlist. Args: <cell> <extracted.spice> [out]
# Runs inside polari-eda-tools with PDK_ROOT set; prints the netgen verdict lines.
set -e
CELL="$1"; EXT="$2"; OUT="${3:-lvs.out}"
SCH="$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/spice/sky130_fd_sc_hd.spice"
netgen-lvs -batch lvs "$EXT $CELL" "$SCH $CELL" "$PDK_ROOT/sky130A/libs.tech/netgen/sky130A_setup.tcl" "$OUT" > lvs.log 2>&1 || true
grep -E "Circuits match|Netlists do not match|do not match|Final result|uniquely" "$OUT" lvs.log | sort -u | head -8
