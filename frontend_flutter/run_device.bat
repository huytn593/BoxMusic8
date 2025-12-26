@echo off
echo ========================================
echo Flutter Run on Real Android Device (USB)
echo ========================================
echo.
echo This script will:
echo 1. Setup ADB reverse port forwarding
echo 2. Run Flutter app with correct config
echo.
echo Make sure you have:
echo 1. Device connected via USB
echo 2. USB Debugging enabled
echo 3. Backend running (dotnet run in backend\backend)
echo.

cd /d "%~dp0"

REM Find ADB
set ADB_PATH=
where adb >nul 2>&1
if %errorlevel% equ 0 (
    set ADB_PATH=adb
    goto :setup_adb
)

if exist "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" (
    set ADB_PATH=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe
    goto :setup_adb
)

if exist "C:\Users\huytn\AppData\Local\Android\Sdk\platform-tools\adb.exe" (
    set ADB_PATH=C:\Users\huytn\AppData\Local\Android\Sdk\platform-tools\adb.exe
    goto :setup_adb
)

echo WARNING: ADB not found! Skipping ADB reverse setup.
echo If connection fails, please setup ADB reverse manually:
echo   adb reverse tcp:5270 tcp:5270
echo.
goto :run_flutter

:setup_adb
echo Setting up ADB reverse port forwarding...
"%ADB_PATH%" reverse tcp:5270 tcp:5270
if %errorlevel% equ 0 (
    echo ✓ ADB reverse is active.
    echo.
) else (
    echo WARNING: Failed to setup ADB reverse.
    echo You may need to setup manually: adb reverse tcp:5270 tcp:5270
    echo.
)

:run_flutter
echo Running Flutter app...
echo Command: flutter run --dart-define=API_HOST=172.20.10.2 --dart-define=API_PORT=5270 --dart-define=USE_EMULATOR=false
echo.

flutter run --dart-define=API_HOST=172.20.10.2 --dart-define=API_PORT=5270 --dart-define=USE_EMULATOR=false

pause

