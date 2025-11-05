@echo off
chcp 65001 >nul
REM ==========================================================
REM HarmoNet Git Utility Launcher v4.5
REM Purpose: Execute PowerShell script v4.5 with UTF-8 encoding
REM Changelog v4.5:
REM   - Multi-line commit message support
REM ==========================================================

echo =========================================
echo  HarmoNet Git Utility Starting...
echo =========================================
echo.

REM Execute PowerShell script in the same directory
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0harmonet-git-utility_v4.5.ps1"

echo.
echo =========================================
echo  Process completed
echo =========================================
pause
