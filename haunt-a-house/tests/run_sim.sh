#!/usr/bin/env bash
# Lance la simulation d'equilibrage avec l'executable luau.
set -euo pipefail
cd "$(dirname "$0")"
LUAU_BIN="${LUAU_BIN:-luau}"
OUT="$(mktemp -d)"
mkdir -p "$OUT/shared"
for f in ../src/shared/*.luau; do
  sed -E 's/require\(script\.Parent\.([A-Za-z_]+)\)/require("\.\/\1")/g' "$f" > "$OUT/shared/$(basename "$f")"
done
cp balance_sim.luau "$OUT/"
"$LUAU_BIN" "$OUT/balance_sim.luau"
rm -rf "$OUT"
