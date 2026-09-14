@echo off
REM Construit le fichier de place Roblox (build\HauntAHouse.rbxlx) a partir des sources.
REM Pre-requis : Rojo 7.5+ (https://rojo.space) installe et present dans le PATH.
cd /d "%~dp0"
if not exist build mkdir build
rojo build default.project.json -o build\HauntAHouse.rbxlx
if %errorlevel% neq 0 (
  echo ERREUR : la construction a echoue. Verifiez que Rojo est installe.
  exit /b 1
)
echo OK : build\HauntAHouse.rbxlx genere.
