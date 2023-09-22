@echo off
SETLOCAL EnableExtensions
echo Opening %1
REM Pause
"%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -File "C:\Program Files\qBittorrent\torrentLauncher.ps1" %1
rem pause
REM echo Done
Pause
