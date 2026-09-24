# polari-eda-tools — THE OPEN EDA TOOLCHAIN Polari's compute ladder runs on (computelod lod-1…lod-3c), in ONE image
# pinned by the Ubuntu 24.04 (noble) apt archive. Every tool is invoked as a separate process by the framework;
# nothing here is linked into or vendored by Polari — see LICENSES.md for the audit.
#
#   gcc-riscv64-unknown-elf   GPL-3 (+ runtime exception)  the RISC-V cross compiler (lod-1)
#   yosys                     ISC                           synthesis + technology mapping (lod-1, lod-2)
#   verilator / iverilog      LGPL-3 | Artistic-2 / GPL-2+  RTL simulation (lod-1)
#   nextpnr-ice40 + icestorm  ISC                           open place-and-route + bitstream for iCE40 (tt-3)
#   magic 8.3.684 (source)    UC Berkeley permissive (LICENSE) built from RTimothyEdwards/magic at a PINNED tag — the
#                             noble package (8.3.105) is older than the sky130A tech file requires (>= 8.3.411)
#   netgen-lvs                GPL "any version"             layout-vs-schematic (lod-3c; binary: netgen-lvs)
#   ciel                      Apache-2.0                    fetches a BUILT open PDK (sky130A) at a pinned version
#
#   docker build -t polari-eda-tools:noble .
#   ./fetch-pdk.sh                  # sky130A (sc_hd + fd_pr only) into $POLARI_PDK_ROOT (never in git, never in the image)
#   docker run --rm -v <work>:/w -w /w -v $POLARI_PDK_ROOT:/pdk -e PDK_ROOT=/pdk polari-eda-tools:noble <tool> …
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
        gcc-riscv64-unknown-elf binutils-riscv64-unknown-elf picolibc-riscv64-unknown-elf \
        yosys verilator iverilog nextpnr-ice40 fpga-icestorm \
        netgen-lvs tcl tk tcl-dev tk-dev libcairo2 libcairo2-dev libx11-dev libglu1-mesa-dev libgl1-mesa-dev \
        build-essential git m4 csh python3 python3-pip ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && pip3 install --no-cache-dir --break-system-packages ciel==3.0.0
ARG MAGIC_TAG=8.3.684
RUN git clone --depth 1 --branch ${MAGIC_TAG} https://github.com/RTimothyEdwards/magic /tmp/magic \
    && cd /tmp/magic && ./configure --prefix=/usr/local >/tmp/magic-configure.log 2>&1 \
    && make -j"$(nproc)" >/tmp/magic-make.log 2>&1 && make install >/dev/null \
    && cp /tmp/magic/LICENSE /usr/local/share/doc-magic-LICENSE && rm -rf /tmp/magic
ENV PDK_ROOT=/pdk
WORKDIR /w
