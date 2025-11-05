@echo off
chcp 65001 >nul
REM ==========================================================
REM HarmoNet Git Utility Launcher v4.4
REM Purpose: Execute PowerShell script v4.4 with UTF-8 encoding
REM ==========================================================

echo =========================================
echo  HarmoNet Git Utility Starting...
echo =========================================
echo.

REM Execute PowerShell script in the same directory
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0harmonet-git-utility_v4.4.ps1"

echo.
echo =========================================
echo  Process completed
echo =========================================
pause
