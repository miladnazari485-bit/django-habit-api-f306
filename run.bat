@echo off
cd /d "%~dp0"

where flutter >nul 2>&1
if errorlevel 1 (
  echo Flutter is not on PATH.
  echo Install it from https://docs.flutter.dev/get-started/install/windows
  echo Close this window, reopen it, and run run.bat again.
  pause
  exit /b 1
)

echo.
echo Getting packages...
call flutter pub get
if errorlevel 1 goto fail

echo.
echo Starting Habit Tracker on Windows...
call flutter run -d windows
if errorlevel 1 goto fail
exit /b 0

:fail
echo.
echo Windows desktop needs Visual Studio with the "Desktop development with C++" workload.
echo Check with: flutter doctor
echo You can also run the app in Chrome: flutter run -d chrome
pause
exit /b 1
