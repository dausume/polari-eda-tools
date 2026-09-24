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
| open_pdks / sky130A (built PDK, fetched at run time, NEVER in git or the image) | ciel version 1689ac3f2dc763876eaf967227c7dfe831b031ae | Apache-2.0 (open_pdks; SkyWater PDK) | RTimothyEdwards/open_pdks + google/skywater-pdk licence fields; SPDX headers on the cell files read in lod-3 | data — fine; cited by version + sha256 in every report |
| Ubuntu 24.04 base | ubuntu:24.04 | various (Debian/Ubuntu) | — | base image |

Rules this repo keeps:
- the PDK lives in `$POLARI_PDK_ROOT` (default `~/.cache/polari-lod/pdk`), gitignored, mounted read-only into the
  container; reports cite the ciel version and the sha256 of every file they read;
- no vendor-locked or NC-licensed tool enters this image (the suite's hard blocker);
- a new tool = a new row here with the verification location, before the Dockerfile line.
