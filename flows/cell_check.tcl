# Polari lod-3c: DRC + parasitic extraction of ONE sky130_fd_sc_hd cell from the PDK's own .mag
set cell $env(CELL)
set lib $env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd
addpath $lib/mag
load $cell -dereference
select top cell
drc euclidean on
drc style drc(full)
drc check
drc catchup
set n [drc list count total]
puts "POLARI_DRC_COUNT $n"
foreach e [drc listall why] { puts "POLARI_DRC_WHY $e" }
# 1. the LVS netlist: devices only (what netgen compares to the schematic)
extract do local
extract no capacitance
extract no coupling
extract all
ext2spice lvs
ext2spice -o ${cell}_lvs.spice
puts "POLARI_LVS_NETLIST ${cell}_lvs.spice"
# 2. the PEX netlist: the same devices + every wiring / coupling capacitance (what the re-timing runs on)
extract do capacitance
extract do coupling
extract all
ext2spice lvs
ext2spice cthresh 0 rthresh 0
ext2spice extresist off
ext2spice -o ${cell}_pex.spice
puts "POLARI_EXTRACTED ${cell}_pex.spice"
quit -noprompt
