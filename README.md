# polari-eda-tools

The open EDA toolchain Polari's compute ladder (`polari-framework/modules/computelod`) runs on, as ONE Docker image
plus a PDK fetcher — its own submodule of `polari-rf-node` so the tools, their pins and their licence audit live
apart from the framework's rows and readings (the framework only ever names the image and the PDK root).

    docker build -t polari-eda-tools:noble .      # gcc-riscv64, yosys, verilator, iverilog, nextpnr/icestorm, magic (source), netgen, ciel
    ./fetch-pdk.sh                                # sky130A (sky130_fd_sc_hd + sky130_fd_pr only, ~0.9 GB) → $POLARI_PDK_ROOT, never in git

    # the framework's lod scripts use these knobs:
    POLARI_EDA_IMAGE=polari-eda-tools:noble   POLARI_PDK_ROOT=~/.cache/polari-lod/pdk   POLARI_OPENSTA_IMAGE=openroad/opensta

It is ALSO an engines WORKER (the Polari engines pattern — cnt-engines / msci-engines / cad-engines): the image's
default command serves `GET /capability` + `POST /run` (argv only, files round-trip) on :9800;
`polari-rf-node/docker-compose.eda-engines.yml` deploys it, `pol allocate computelod.engines <instance>` places it,
and the framework resolves every engine through `computelod/custom/eda_engines.py` (EDA_ENGINES_URL → local binary
→ local image → topology provider → refusal). The device that runs the worker holds the PDK volume.

`flows/` holds the tool scripts the framework drives (`cell_check.tcl`: magic DRC + parasitic extraction of one
cell from the PDK's own `.mag`; `lvs.sh`: netgen layout-vs-schematic against the PDK's schematic netlist).
`LICENSES.md` is the audit — every tool is invoked as a separate process; nothing is linked or vendored.

**A second worker, the OpenROAD FLOW (eng-1, 2026-09-26)** — `Dockerfile.orfs` builds `prf-orfs-engines:staging` FROM the pinned
published `openroad/orfs:26Q3-651-gbc334a4aa` (4.64 GB, never rebuilt here; + falcon/gunicorn/psutil + this same service with
`WORKER_KIND=orfs`, ~50 MB on top): engines `orfs` (= `make` on `/OpenROAD-flow-scripts/flow`, claimed ONLY where that Makefile
exists) and `openroad`, on :9801, files round-trip up to `WORKER_MAX_MB` (256 there — a routed adder's work tree is ~45 MB). An
argv may carry the token `{work}`, which every rung replaces with the job's own directory (the ORFS flow needs absolute
`DESIGN_CONFIG` / `WORK_HOME`), and a `config.mk` written with `$(dir $(DESIGN_CONFIG))` paths runs unchanged anywhere.
`polari-rf-node/docker-compose.orfs-engines.yml` deploys it; `pol allocate computelod.pnr <instance>` places it; the framework's
ladder for the two flow engines is `ORFS_ENGINES_URL` → the local pinned image → the topology provider → refusal (the host's
`make` and this image's `make` are never the flow).
