#!/usr/bin/env bash
# Teste publish/publish.py (et publish.ps1 si pwsh est disponible) contre un serveur Roblox factice.
set -euo pipefail
cd "$(dirname "$0")/.."
PORT=${PORT:-8765}
python3 tests/mock_roblox_server.py "$PORT" > /tmp/mock_roblox.log 2>&1 &
MOCK_PID=$!
trap 'kill $MOCK_PID 2>/dev/null || true' EXIT
sleep 1
run_case() {
  local runner="$1"
  local work
  work="$(mktemp -d)"
  mkdir -p "$work/build" "$work/src/shared" "$work/publish"
  cp build/HauntAHouse.rbxlx "$work/build/"
  cp src/shared/MonetizationIds.luau "$work/src/shared/"
  cp publish/publish.py publish/publish.ps1 publish/smoke_test.luau "$work/publish/"
  cat > "$work/publish/publish.config.json" <<JSON
{ "apiKey": "test-key", "universeId": 111, "placeId": 222, "groupId": 333, "apiBase": "http://127.0.0.1:$PORT", "experienceName": "Haunt a House 👻 [TEST]", "serverSize": 12, "makePublic": true, "runSmokeTest": true }
JSON
  echo "===== $runner"
  if [ "$runner" = "python" ]; then
    python3 "$work/publish/publish.py"
  else
    "$PWSH" -NoLogo -NonInteractive -File "$work/publish/publish.ps1"
  fi
  echo "--- verification des fichiers patches"
  src_zero=$(grep -c "Id = 0," "$work/src/shared/MonetizationIds.luau" || true)
  rbx_zero=$(grep -c "Id = 0," "$work/build/HauntAHouse.rbxlx" || true)
  [ "$src_zero" = "0" ] || { echo "ECHEC : $src_zero Id = 0 subsistent dans la source"; exit 1; }
  [ "$rbx_zero" = "0" ] || { echo "ECHEC : $rbx_zero Id = 0 subsistent dans le rbxlx"; exit 1; }
  grep -q "Ids.GroupId = 333" "$work/src/shared/MonetizationIds.luau" || { echo "ECHEC : GroupId non inscrit"; exit 1; }
  grep -q "Ids.GroupId = 333" "$work/build/HauntAHouse.rbxlx" || { echo "ECHEC : GroupId non inscrit dans le rbxlx"; exit 1; }
  grep -Eq "DoubleCoins = \{ Id = [0-9]{4}" "$work/src/shared/MonetizationIds.luau" || { echo "ECHEC : DoubleCoins non patche"; exit 1; }
  grep -Eq "FlashRebirthRush = \{ Id = [0-9]{4}" "$work/build/HauntAHouse.rbxlx" || { echo "ECHEC : rbxlx non patche"; exit 1; }
  echo "OK : fichiers patches"
  rm -rf "$work"
}
run_case python
echo "--- etat du serveur factice apres python"
curl -sS -X DUMP "http://127.0.0.1:$PORT/dump" | python3 -c "import json,sys; d=json.load(sys.stdin); print('passes:', len(d['passes']), 'produits:', len(d['products']), 'publications:', [(p['versionType'], p['hasIds']) for p in d['published']], 'reglages:', len(d['place_patches']), 'visibilite:', len(d['universe_patches']), 'taches:', len(d['tasks']))"
if [ -n "${PWSH:-}" ] && [ -x "$PWSH" ]; then
  run_case powershell
  echo "--- etat du serveur factice apres powershell"
  curl -sS -X DUMP "http://127.0.0.1:$PORT/dump" | python3 -c "import json,sys; d=json.load(sys.stdin); print('passes:', len(d['passes']), 'produits:', len(d['products']), 'publications:', [(p['versionType'], p['hasIds']) for p in d['published']], 'reglages:', len(d['place_patches']), 'visibilite:', len(d['universe_patches']), 'taches:', len(d['tasks']))"
else
  echo "(pwsh non disponible : script PowerShell non teste)"
fi
