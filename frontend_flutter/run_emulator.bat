@echo off
echo ========================================
echo Flutter Run on Android Emulator
echo ========================================
echo.
echo This script will run Flutter app on emulator with correct config
echo (Uses 10.0.2.2 to access localhost backend)
echo.

cd /d "%~dp0"

echo Running: flutter run --dart-define=USE_EMULATOR=true --dart-define=API_PORT=5270
echo.

flutter run --dart-define=USE_EMULATOR=true --dart-define=API_PORT=5270

pause

