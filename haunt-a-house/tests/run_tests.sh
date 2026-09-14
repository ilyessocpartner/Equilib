#!/usr/bin/env bash
# Execute les tests de logique pure avec l'executable `luau` (https://github.com/luau-lang/luau/releases).
# Les modules partages utilisent `require(script.Parent.X)` ; on les copie en remplacant par des requires relatifs.
set -euo pipefail
cd "$(dirname "$0")"
LUAU_BIN="${LUAU_BIN:-luau}"
OUT="$(mktemp -d)"
mkdir -p "$OUT/shared"
for f in ../src/shared/*.luau; do
  sed -E 's/require\(script\.Parent\.([A-Za-z_]+)\)/require("\.\/\1")/g' "$f" > "$OUT/shared/$(basename "$f")"
done
cp ./*.test.luau "$OUT/"
status=0
for t in "$OUT"/*.test.luau; do
  echo "== $(basename "$t")"
  if ! "$LUAU_BIN" "$t"; then status=1; fi
done
rm -rf "$OUT"
exit $status
