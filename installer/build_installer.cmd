@echo off
rem Build the simple_bible PERSONAL installer.
rem   1. release builds of bible and bible_build (ec.sh release: lean, no contracts)
rem   2. compile installer\simple_bible_personal.iss with Inno Setup 6
rem Needs: SIMPLE_BIBLE_CONC naming the personal conc.db, and content.db in
rem %LOCALAPPDATA%\simple_bible (run bible_build first).
rem Output: installer\output\simple_bible-personal-<version>-Setup.exe
rem That file holds the personal edition: never publish or upload it.
setlocal
set "ROOT=%~dp0.."
set "ISCC=C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
rem Git's bash: a plain "bash" can resolve to the WSL launcher, where /d/prod does not exist.
set "GITBASH=C:\Program Files\Git\bin\bash.exe"
if "%SIMPLE_BIBLE_CONC%"=="" (
  echo SIMPLE_BIBLE_CONC is not set: point it at the personal conc.db.
  exit /b 1
)
pushd "%ROOT%"
"%GITBASH%" -c "/d/prod/ec.sh release -config simple_bible_app.ecf -target bible" || goto :failed
"%GITBASH%" -c "/d/prod/ec.sh release -config bible_build.ecf -target bible_build" || goto :failed
if not exist "EIFGENs\bible\F_code\bible_lean.exe" goto :failed
if not exist "EIFGENs\bible_build\F_code\bible_build_lean.exe" goto :failed
popd
"%ISCC%" "%~dp0simple_bible_personal.iss" || goto :failed_iscc
echo.
echo Installer ready in %~dp0output (personal edition: keep it on your own machines)
exit /b 0
:failed
popd
echo A program did not build. See the ec.sh output above.
exit /b 1
:failed_iscc
echo Inno Setup could not build the installer.
exit /b 1
