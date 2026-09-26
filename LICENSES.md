# polari-eda-tools — licence ledger

Polari is GPLv3 ([[project-license-gplv3]]). Everything in this image is a TOOL the framework invokes as a
separate process (subprocess / `docker run`); nothing is linked into Polari, nothing is vendored into a Polari
repo, and the tools' OUTPUTS (netlists, reports, timing numbers) are ours. GPL compatibility therefore never
arises for the tools themselves — it is recorded anyway, per the suite's licence gate, so nobody has to redo
this audit. Verified 2026-09-24 against the Debian `copyright` files shipped in the noble packages, upstream
`LICENSE` files, and PyPI metadata.

| Component | Version / pin | Licence | Verified where | Verdict |
|---|---|---|---|---|
| gcc-riscv64-unknown-elf, binutils, picolibc | noble apt | GPL-3.0+ (runtime exception) / GPL-3.0+ / BSD-3 | Debian copyright | tool — fine |
| yosys | noble apt 0.33 | ISC | Debian copyright | tool — fine (GPLv3-compatible anyway) |
| verilator | noble apt | LGPL-3.0 or Artistic-2.0 | Debian copyright | tool — fine |
| iverilog | noble apt | GPL-2.0+ | Debian copyright | tool — fine |
| nextpnr-ice40, fpga-icestorm | noble apt | ISC | Debian copyright | tool — fine |
| magic | source, tag 8.3.684 (RTimothyEdwards/magic) | UC Berkeley permissive ("Permission to use, copy, modify, and distribute … without fee") + Juniper permissive parts | upstream LICENSE; Debian copyright of the 8.3.105 package (BSD-style, Juniper) | tool — fine; permissive |
| netgen-lvs | noble apt 1.5.133 | GNU GPL "any version" (Files: *); parts public-domain / MIT-with-X-exception / GPL-2+ | Debian copyright: "under the terms of the GNU General Public License … (any version)" | tool — fine; GPLv3-compatible |
| ciel | PyPI 3.0.0 (fossi-foundation/ciel) | Apache-2.0 | wheel METADATA | tool — fine; one-way compatible into GPLv3 |
| OpenSTA | the `openroad/opensta` image's `/OpenSTA/build/sta` binary, copied (multi-stage) | GPL-3.0 | The-OpenROAD-Project/OpenSTA LICENSE | tool — fine; a separate process, same binary the suite has timed with since lod-2 |
| falcon, gunicorn (the worker's HTTP) | pip | Apache-2.0 / MIT | PyPI | fine |
| open_pdks / sky130A (built PDK, fetched at run time, NEVER in git or the image) | ciel version 1689ac3f2dc763876eaf967227c7dfe831b031ae | Apache-2.0 (open_pdks; SkyWater PDK) | RTimothyEdwards/open_pdks + google/skywater-pdk licence fields; SPDX headers on the cell files read in lod-3 | data — fine; cited by version + sha256 in every report |
| Ubuntu 24.04 base | ubuntu:24.04 | various (Debian/Ubuntu) | — | base image |
| **A SECOND engine image — `openroad/orfs` (lod-3e, 2026-09-26): NOT built here, used as published, pinned by tag + digest** | `openroad/orfs:26Q3-651-gbc334a4aa` (digest sha256:69df744e2b5ce26a14950713fd2d74b96ec8c9bd8351d2719f9bb200388239ad; Ubuntu 22.04 base, 4.6 GB) | see the rows below | `/OpenROAD-flow-scripts/tools/install/licenses/*` inside the image | the framework's engines ladder runs `make` (the ORFS flow) and `openroad` in it as separate processes (engine names `orfs`, `openroad`); the eda-tools WORKER does not carry it (its capability says so) — a device wanting the flow pulls this image |
| OpenROAD (in the orfs image) | nightly build in the pinned image (`openroad -version` prints "unknown") | BSD-3-Clause | `licenses/OpenROAD/LICENSE` ("Copyright (c) 2018-2025, The OpenROAD Authors") | tool — fine |
| OpenROAD-flow-scripts (the flow's Makefile + Tcl) | the pinned image's `/OpenROAD-flow-scripts` | BSD-3-Clause | `LICENSE_BUILD_RUN_SCRIPTS` | tool — fine; our design config.mk + SDC are ours |
| yosys (in the orfs image) | ORFS build | ISC | `licenses/yosys` | tool — fine |
| codespace (in the orfs image) | ORFS build | Apache-2.0 | `licenses/codespace/LICENSE` | not invoked |
| kepler-formal (equivalence checker in the orfs image) | ORFS build | GPL-3.0 | `licenses/kepler-formal/LICENSE.rst` | NOT invoked (`LEC_CHECK=0`: it dies with an illegal instruction on pol-core; a separate process anyway) |
| KLayout (in the orfs image) | 0.30.12 | GPL-3.0 | upstream | NOT invoked by our flow (the GDS merge step uses it inside ORFS's final stage; the GDS is never committed) |
| sky130hd platform files (in the orfs image: LEF, GDS, a copy of the tt Liberty) | ORFS `flow/platforms/sky130hd` | Apache-2.0 (SkyWater PDK) | upstream | read by the flow inside the image; our flow hands the flow OUR cached Liberty (lod-2's, sha256-cited) as LIB_FILES; nothing of it enters git |

Rules this repo keeps:
- the PDK lives in `$POLARI_PDK_ROOT` (default `~/.cache/polari-lod/pdk`), gitignored, mounted read-only into the
  container; reports cite the ciel version and the sha256 of every file they read;
- no vendor-locked or NC-licensed tool enters this image (the suite's hard blocker);
- a new tool = a new row here with the verification location, before the Dockerfile line.
