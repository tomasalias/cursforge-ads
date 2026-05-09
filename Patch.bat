@echo off
setlocal

rem —————————————————————————————
rem CONFIGURATION
set "DESKTOP_HTML=%~dp0desktop.html"
set "CURSEFORGE_RES=%LOCALAPPDATA%\Programs\CurseForge Windows\resources"
set "ASAR=%CURSEFORGE_RES%\app.asar"
set "BACKUP=%ASAR%.bak"
set "WORK=%TEMP%\cf_extract"
set "NEW_ASAR=%TEMP%\new.asar"
set "PYTHON=python"

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
rem 1) Ensure Python
where /q "%PYTHON%">nul
if errorlevel 1 (
  echo Installing Python...
  winget install --silent --accept-package-agreements --accept-source-agreements Python.Python.3.12
)

where /q "%PYTHON%">nul
if errorlevel 1 (
  echo ERROR: Python not found after install.
  pause & exit /b 1
)

"%PYTHON%" -m pip --version >nul 2>nul
if errorlevel 1 (
  "%PYTHON%" -m ensurepip --upgrade >nul 2>nul
)

rem —————————————————————————————
rem 2) Install asar
echo Installing asar...
"%PYTHON%" -m pip install --upgrade asar >nul 2>nul
if errorlevel 1 (
  echo ERROR: Failed to install asar.
  pause & exit /b 1
)

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
echo Extracting app.asar...
set "ASAR_SRC=%ASAR%"
set "ASAR_DST=%WORK%"
"%PYTHON%" -c "from pathlib import Path; import os; from asar import extract_archive; extract_archive(Path(os.environ['ASAR_SRC']), Path(os.environ['ASAR_DST']))" >nul 2>nul
if errorlevel 1 (
  echo ERROR: Failed to extract app.asar.
  pause & exit /b 1
)

if not exist "%WORK%\dist\desktop\" (
  echo ERROR: dist\desktop not found
  pause & exit /b 1
)

rem —————————————————————————————
rem 6) Replace desktop.html
echo Overwriting desktop.html...
copy /Y "%DESKTOP_HTML%" "%WORK%\dist\desktop\desktop.html" >nul

rem —————————————————————————————
rem 7) Pack new archive into temporary file
if exist "%NEW_ASAR%" del "%NEW_ASAR%"
echo Packing new ASAR...
set "ASAR_PACK_SRC=%WORK%"
set "ASAR_PACK_DST=%NEW_ASAR%"
"%PYTHON%" -c "from pathlib import Path; import os; from asar import create_archive; create_archive(Path(os.environ['ASAR_PACK_SRC']), Path(os.environ['ASAR_PACK_DST']))" >nul 2>nul
if errorlevel 1 (
  echo ERROR: Failed to create new ASAR.
  pause & exit /b 1
)

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
