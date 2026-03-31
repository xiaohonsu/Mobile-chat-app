@echo off
title Flutter Chat App - Demo Server
color 0A

echo ============================================
echo   FLUTTER CHAT APP - DEMO SERVER
echo ============================================
echo.

REM Lay IP WiFi cua laptop
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "IPv4" ^| findstr /v "169.254" ^| findstr /v "127.0.0"') do (
    set WIFI_IP=%%a
    goto :found_ip
)
:found_ip
set WIFI_IP=%WIFI_IP: =%

echo [INFO] Laptop IP: %WIFI_IP%
echo.
echo ============================================
echo   BUOC 1: Cap nhat IP trong config.dart
echo ============================================
echo.
echo Mo file: source_code/chat_app/lib/config.dart
echo Doi dong nay:
echo   const String emulatorHost = '10.0.2.2';
echo Thanh:
echo   const String emulatorHost = '%WIFI_IP%';
echo.
echo Nhan phim bat ky sau khi da cap nhat...
pause > nul

echo.
echo ============================================
echo   BUOC 2: Khoi dong Firebase Emulator
echo ============================================
echo.
echo Emulator UI: http://localhost:4000
echo Firestore:   http://localhost:8080
echo Auth:        http://localhost:9099
echo.
echo Ca 2 thiet bi can ket noi cung WiFi voi laptop nay!
echo.

cd /d "%~dp0chat_app"
firebase emulators:start --project demo-chat-seminar

pause
