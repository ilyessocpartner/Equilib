@echo off
REM Double-clique sur ce fichier pour publier Haunt a House sur Roblox (Windows).
REM Pre-requis : publish.config.json rempli (voir docs\GUIDE_DEBUTANT.md).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0publish.ps1"
echo.
pause
