#!/usr/bin/env bash
# Construit le fichier de place Roblox (build/HauntAHouse.rbxlx) a partir des sources.
# Pre-requis : Rojo 7.5+ (https://rojo.space) installe et present dans le PATH.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p build
rojo build default.project.json -o build/HauntAHouse.rbxlx
echo "OK : build/HauntAHouse.rbxlx genere."
