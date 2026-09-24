#!/usr/bin/env bash
# Fetch a BUILT sky130A (only the sc_hd cell library + fd_pr primitives) with ciel at a PINNED open_pdks version
# into $POLARI_PDK_ROOT (default ~/.cache/polari-lod/pdk) — gitignored, never in the image. Idempotent.
#   POLARI_PDK_VERSION  open_pdks commit ciel resolves (pinned below; `ciel ls-remote --pdk-family sky130` lists)
set -euo pipefail
IMAGE="${POLARI_EDA_IMAGE:-polari-eda-tools:noble}"
ROOT="${POLARI_PDK_ROOT:-$HOME/.cache/polari-lod/pdk}"
VERSION="${POLARI_PDK_VERSION:-1689ac3f2dc763876eaf967227c7dfe831b031ae}"
mkdir -p "$ROOT"
if [ -d "$ROOT/sky130A/libs.tech/magic" ] && [ -f "$ROOT/sky130A/libs.tech/magic/sky130A.tech" ]; then
    echo "pdk present: $ROOT/sky130A (version $(cat "$ROOT/.polari-pdk-version" 2>/dev/null || echo '?'))"; exit 0
fi
docker run --rm -u "$(id -u):$(id -g)" -e HOME=/tmp -v "$ROOT:/pdk" -e PDK_ROOT=/pdk "$IMAGE" \
    ciel enable --pdk-family sky130 --include-libraries sky130_fd_sc_hd --include-libraries sky130_fd_pr "$VERSION"
echo "$VERSION" > "$ROOT/.polari-pdk-version"
du -sh "$ROOT"
