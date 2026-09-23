#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/build"
mkdir -p "$OUT"
cd "$ROOT"

stylua --check src
rojo build default.project.json -o "$OUT/EggRivals.rbxlx"
rojo build test.project.json -o "$OUT/EggRivals_TEST.rbxlx"

sha256sum "$OUT/EggRivals.rbxlx" "$OUT/EggRivals_TEST.rbxlx"
echo "Build complete: $OUT"
