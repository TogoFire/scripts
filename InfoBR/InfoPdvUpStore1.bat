
@echo off
title Update InfoPDVStore1
setlocal enabledelayedexpansion

set "DOWNLOAD_URL=http://dbinfo01.iprojectti.com.br:8008/infobrasilsistemas/areadosuporte/arq/InfoPDV_e.zip"
set "DOWNLOAD_PATH=C:\Infobrasil\InfoPDV_e\Exec\InfoPDV_e.zip"
set "DESTINATION_PATH=C:\Infobrasil\InfoPDV_e\Exec"
set "BATCH_FILE_PATH=C:\Infobrasil\InfoPdvUpStore1.exe"

echo Checking if program InfoPDV is running...
tasklist /FI "IMAGENAME eq InfoPDV_e.exe" 2>NUL | find /I /N "InfoPDV_e.exe">NUL
if "%ERRORLEVEL%"=="0" (
  echo Program is running. Trying to force close...
  taskkill /im InfoPDV_e.exe /t /f
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
schtasks /query /tn "InfoPdvUpStore1" > nul 2>&1
IF %ERRORLEVEL% EQU 1 (
  REM Scheduled task does not exist, so create it.
  schtasks /create /tn "InfoPdvUpStore1" /tr "%BATCH_FILE_PATH%" /sc weekly /mo 1 /d MON /st 08:50:00
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
