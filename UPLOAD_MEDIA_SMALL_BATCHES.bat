@echo off
title Denz iPhones - Small Batch Media Upload
echo.
echo ==========================================
echo   DENZ iPHONES - MEDIA UPLOAD
echo   Max target: 10 MB per commit / push
echo ==========================================
echo.
where git >nul 2>&1
if errorlevel 1 (
  echo Git is not installed or not in PATH.
  echo Install Git for Windows, then run this BAT again.
  pause
  exit /b 1
)
set "PS1=%TEMP%\denz-upload-media.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/spirit2k5/denz-iphones/main/upload-media-small-batches.ps1' -OutFile '%PS1%'"
if errorlevel 1 (
  echo Could not download the uploader script from GitHub.
  pause
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
echo.
echo Finished. Check the messages above for the result.
pause
