
@echo off
title Update InfoRetaguarda
setlocal enabledelayedexpansion

set "DOWNLOAD_URL=http://dbinfo01.iprojectti.com.br:8008/infobrasilsistemas/areadosuporte/arq/InfoDBX.zip"
set "DOWNLOAD_PATH=C:\Infobrasil\Exec\InfoDBX.zip"
set "DESTINATION_PATH=C:\Infobrasil\Exec"
set "BATCH_FILE_PATH=C:\Infobrasil\InfoRetaguardaUp.exe"

echo Checking if program InfoRetaguarda is running...
tasklist /FI "IMAGENAME eq Info.exe" 2>NUL | find /I /N "Info.exe">NUL
if "%ERRORLEVEL%"=="0" (
  echo Program is running. Trying to force close...
  taskkill /im Info.exe /t /f
  echo Program closed.
) else (
  echo Program is not running.
)

echo Starting download...

curl -L "%DOWNLOAD_URL%" --output "%DOWNLOAD_PATH%"

echo Extracting file...

powershell Expand-Archive -Force -Path "%DOWNLOAD_PATH%" -DestinationPath "%DESTINATION_PATH%"

echo Scheduling task...

REM Check if the scheduled task exists
schtasks /query /tn "InfoRetaguardaUp" > nul 2>&1
IF %ERRORLEVEL% EQU 1 (
  REM Scheduled task does not exist, so create it.
  schtasks /create /tn "InfoRetaguardaUp" /tr "%BATCH_FILE_PATH%" /sc weekly /mo 1 /d MON /st 12:00:00
) ELSE (
  echo The scheduled task already exists.
)

REM Replace `BATCH_FILE_PATH` with the actual path to your script file. 
REM monthly /d 1 means "run on the first day of the month"
REM weekly /mo 1 means "run every 1 week"
REM /d MON means "run on Monday"
REM /d SUN means "run on Sunday"
REM /st 00:00:00 means "run at 12:00 AM"
REM daily /st 00:00:00 "run the script every day at 12:00 AM"
REM /st 12:00:00 means "run at 12:00 PM" (noon)

echo Done.
