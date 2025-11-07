@echo off
chcp 932 >nul
REM ==========================================================
REM HarmoNet Git Utility Launcher v2
REM Purpose: Execute PowerShell script with proper encoding
REM ==========================================================

echo =========================================
echo  HarmoNet Git Utility Starting...
echo =========================================
echo.

REM Execute PowerShell script in the same directory
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0harmonet-git-utility_v4_2.ps1"

echo.
echo =========================================
echo  Process completed
echo =========================================
pause
