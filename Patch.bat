@echo off
setlocal

rem —————————————————————————————
rem CONFIGURATION
set "DESKTOP_HTML=%~dp0desktop.html"
set "SCOOP_7ZIP=%USERPROFILE%\scoop\apps\7zip\current"
set "FORMATS_DIR=%SCOOP_7ZIP%\Formats"
set "CURSEFORGE_RES=%LOCALAPPDATA%\Programs\CurseForge Windows\resources"
set "ASAR=%CURSEFORGE_RES%\app.asar"
set "BACKUP=%ASAR%.bak"
set "WORK=%TEMP%\cf_extract"
set "NEW_ASAR=%TEMP%\new.asar"
set "ASAR_ZIP=%TEMP%\Asar.zip"
set "ZIP=7z.exe"

rem —————————————————————————————
rem 0) Sanity
if not exist "%DESKTOP_HTML%" (
  echo ERROR: desktop.html missing alongside patch.bat
  pause & exit /b 1
)
if not exist "%ASAR%" (
  echo ERROR: app.asar not found at "%ASAR%"
  pause & exit /b 1
)

rem —————————————————————————————
rem 1) Ensure 7‑Zip
where /q "%ZIP%">nul
if errorlevel 1 (
  echo Installing 7‑Zip…
  winget install --silent --accept-package-agreements --accept-source-agreements 7zip.7zip
) else (
  echo 7‑Zip present.
)

rem —————————————————————————————
rem 2) Download & install Asar plugin
echo Downloading Asar plugin…
powershell -Command "Invoke-WebRequest 'https://www.tc4shell.com/binary/Asar.zip' -OutFile '%ASAR_ZIP%'" 2>nul

if not exist "%FORMATS_DIR%" mkdir "%FORMATS_DIR%"
echo Installing plugin into %FORMATS_DIR%…
powershell -Command "Expand-Archive -LiteralPath '%ASAR_ZIP%' -DestinationPath '%FORMATS_DIR%' -Force" 2>nul

rem —————————————————————————————
rem 3) Prepare work dir
if exist "%WORK%" rd /s /q "%WORK%"
mkdir "%WORK%"

rem —————————————————————————————
rem 4) Backup original
if not exist "%BACKUP%" (
  echo Backing up original…
  copy /Y "%ASAR%" "%BACKUP%" >nul
)

rem —————————————————————————————
rem 5) Extract entire ASAR
echo Extracting app.asar…
"%ZIP%" x "%ASAR%" -o"%WORK%" >nul 2>nul

if not exist "%WORK%\dist\desktop\" (
  echo ERROR: dist\desktop not found
  pause & exit /b 1
)

rem —————————————————————————————
rem 6) Replace desktop.html
echo Overwriting desktop.html…
copy /Y "%DESKTOP_HTML%" "%WORK%\dist\desktop\desktop.html" >nul

rem —————————————————————————————
rem 7) Pack new archive into temporary file
if exist "%NEW_ASAR%" del "%NEW_ASAR%"
echo Packing new ASAR…
pushd "%WORK%"
"%ZIP%" a "%NEW_ASAR%" * >nul
popd

if not exist "%NEW_ASAR%" (
  echo ERROR: Failed to create new ASAR
  pause & exit /b 1
)

rem —————————————————————————————
rem 8) Replace original with new
del /F /Q "%ASAR%"
move /Y "%NEW_ASAR%" "%ASAR%" >nul

rem —————————————————————————————
rem Cleanup
rd /s /q "%WORK%"

echo Done. Original backed up at "%BACKUP%"
pause
