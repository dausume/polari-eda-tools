# Polari lod-3f: magic on a ROUTED design's merged GDS (OpenROAD-flow-scripts' 6_1_merged.gds — the PDK's cells + our
# placement and routing): the full sky130A DRC deck on the whole design (taps and wells are in the rows now, so no
# "context rule" is excused), then a hierarchical extraction for LVS (cells kept as subcircuits).
# env: GDS (file in the work dir), TOP (the top cell name), PDK_ROOT
set gds $env(GDS)
set top $env(TOP)
gds readonly true
gds rescale false
gds read $gds
load $top -dereference
select top cell
drc euclidean on
drc style drc(full)
drc check
drc catchup
set n [drc list count total]
puts "POLARI_DRC_COUNT $n"
foreach e [drc listall why] { puts "POLARI_DRC_WHY $e" }
# LVS netlist: devices per cell, cells kept as subcircuits (hierarchy on) — what netgen compares to the Verilog
extract do local
extract no capacitance
extract no coupling
extract unique
extract all
ext2spice lvs
ext2spice hierarchy on
ext2spice -o ${top}_lvs.spice
puts "POLARI_LVS_NETLIST ${top}_lvs.spice"
quit -noprompt
