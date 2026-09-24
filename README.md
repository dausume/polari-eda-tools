# polari-eda-tools

The open EDA toolchain Polari's compute ladder (`polari-framework/modules/computelod`) runs on, as ONE Docker image
plus a PDK fetcher — its own submodule of `polari-rf-node` so the tools, their pins and their licence audit live
apart from the framework's rows and readings (the framework only ever names the image and the PDK root).

    docker build -t polari-eda-tools:noble .      # gcc-riscv64, yosys, verilator, iverilog, nextpnr/icestorm, magic (source), netgen, ciel
    ./fetch-pdk.sh                                # sky130A (sky130_fd_sc_hd + sky130_fd_pr only, ~0.9 GB) → $POLARI_PDK_ROOT, never in git

    # the framework's lod scripts use these knobs:
    POLARI_EDA_IMAGE=polari-eda-tools:noble   POLARI_PDK_ROOT=~/.cache/polari-lod/pdk   POLARI_OPENSTA_IMAGE=openroad/opensta

`flows/` holds the tool scripts the framework drives (`cell_check.tcl`: magic DRC + parasitic extraction of one
cell from the PDK's own `.mag`; `lvs.sh`: netgen layout-vs-schematic against the PDK's schematic netlist).
`LICENSES.md` is the audit — every tool is invoked as a separate process; nothing is linked or vendored.
