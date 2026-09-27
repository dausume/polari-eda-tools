# Polari lod-3f: netgen LVS of a ROUTED design — the layout extracted by magic (design_check.tcl, cells kept as subcircuits)
# against the routed Verilog netlist WITH its power connections (OpenROAD write_verilog -include_pwr_gnd), the standard
# cells compared as black boxes on both sides (their transistor-level LVS is lod-3c's). Physical-only cells the netlist
# never names (fill, tap, decap) are ignored on the LAYOUT side by name — stated in the report, never silently.
# env: TOP, LAYOUT (spice), SCHEMATIC (verilog), OUT
set top $env(TOP)
set setup /pdk/sky130A/libs.tech/netgen/sky130A_setup.tcl
set lay [readnet spice $env(LAYOUT)]
set sch [readnet verilog $env(SCHEMATIC)]
foreach c {sky130_fd_sc_hd__fill_1 sky130_fd_sc_hd__fill_2 sky130_fd_sc_hd__fill_4 sky130_fd_sc_hd__fill_8
           sky130_fd_sc_hd__tapvpwrvgnd_1 sky130_ef_sc_hd__decap_12 sky130_fd_sc_hd__decap_3 sky130_fd_sc_hd__decap_4
           sky130_fd_sc_hd__decap_6 sky130_fd_sc_hd__decap_8 sky130_fd_sc_hd__decap_12} {
    catch {ignore class $c -circuit1}
    catch {ignore class $c -circuit2}
    puts "POLARI_LVS_IGNORED $c"
}
lvs "$lay $top" "$sch $top" $setup $env(OUT) -blackbox
