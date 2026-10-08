@echo off
setlocal
rem ---------------------------------------------------------------------------
rem OKA WH Dev over USB (Windows).
rem   Double-click: connect the phone to the dev server through the cable.
rem   Drag oka-warehouse-dev.apk onto this file: install it first, then connect.
rem Needs: USB debugging on the phone, and port 8081 of the Codespace on this
rem computer (VS Code desktop does that by itself, or: gh codespace ports forward 8081:8081).
rem adb is downloaded once into %LOCALAPPDATA%\oka-platform-tools (no admin rights).
rem ---------------------------------------------------------------------------
set "PORT=8081"
set "TOOLS=%LOCALAPPDATA%\oka-platform-tools"
set "LINK=okawhdev://expo-development-client/?url=http%%3A%%2F%%2Flocalhost%%3A8081"

where adb >nul 2>nul
if %errorlevel%==0 (set "ADB=adb") else (set "ADB=%TOOLS%\platform-tools\adb.exe")
if not "%ADB%"=="adb" if not exist "%ADB%" call :download
if not "%ADB%"=="adb" if not exist "%ADB%" (
  echo Could not get adb. Check the internet connection and try again.
  goto :end
)

"%ADB%" start-server >nul 2>nul
echo.
echo Waiting for the phone... Plug it in with USB debugging on, and tap Allow on the phone if it asks.
"%ADB%" wait-for-device
echo Phone connected.

if not "%~1"=="" (
  echo Installing %~nx1 ...
  "%ADB%" install -r "%~1"
  if errorlevel 1 (
    echo Install failed - see the message above.
    goto :end
  )
)

curl.exe -s -m 3 http://localhost:%PORT%/status 2>nul | findstr /c:"packager-status:running" >nul
if errorlevel 1 (
  echo.
  echo WARNING: http://localhost:%PORT% does not answer on this computer.
  echo   Start "npm run dev:usb" in the Codespace, and open the Codespace in VS Code desktop
  echo   ^(it forwards port %PORT% here^) or run: gh codespace ports forward %PORT%:%PORT%
  echo   Then run this file again.
  echo.
)

"%ADB%" reverse tcp:%PORT% tcp:%PORT%
if errorlevel 1 (
  echo adb reverse failed - unplug and replug the cable, then run this again.
  goto :end
)
"%ADB%" shell "am start -a android.intent.action.VIEW -d '%LINK%'" >nul
echo.
echo Done: OKA WH Dev is opening on the phone and loading from the Codespace through USB.
echo Every save in the Codespace reloads the app. Shake the phone for the dev menu.
goto :end

:download
echo Downloading Android platform-tools (one time, about 7 MB)...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$z = Join-Path $env:TEMP 'oka-platform-tools.zip';" ^
  "Invoke-WebRequest -UseBasicParsing 'https://dl.google.com/android/repository/platform-tools-latest-windows.zip' -OutFile $z;" ^
  "Expand-Archive -Force $z '%TOOLS%'; Remove-Item $z"
exit /b

:end
echo.
pause
