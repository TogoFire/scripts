@echo off
setlocal enableDelayedExpansion
title Update Software

REM This script performs a generic software update, including:
REM - Administrator check
REM - Chocolatey and 7-Zip installation (if needed)
REM - Program termination (if running)
REM - File download and extraction
REM - Scheduled task creation
REM IT MUST BE RUN AS ADMINISTRATOR.

REM =========================================================================
REM GENERAL CONFIGURATIONS
REM =========================================================================

set "DOWNLOAD_URL=https://your-site.file.zip"
set "DOWNLOAD_PATH=C:\App\file.zip"
set "DESTINATION_PATH=C:\App"
set "PROGRAM_NAME=App.exe"
set "TASK_NAME=SoftwareUpdate"
set "BATCH_FILE_PATH=C:\App\SoftwareUpdate.bat" REM Path to this script. Ensure it is correct.

echo.
echo =========================================================
echo   Starting Software Update...
echo =========================================================
echo.

REM --- Check if the script is running as Administrator ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: This script MUST be run as Administrator.
    echo Please right-click this .bat file and select "Run as administrator".
    pause
    exit /b 1
)
echo Running as Administrator.
echo.

REM --- Set the PowerShell execution policy for the current user (suppress output) ---
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy -Scope CurrentUser Unrestricted -Force" >nul 2>&1

REM --- 1. Check for and install Chocolatey if missing ---
echo =========================================================
echo   Checking and installing management tools...
echo =========================================================
echo.

echo Checking Chocolatey installation...
where choco >nul 2>&1
if %errorlevel% neq 0 (
    echo Chocolatey not found. Attempting to install Chocolatey...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" >nul 2>&1
    if %errorlevel% equ 0 (
        echo Chocolatey installed successfully.
        REM Tries to update PATH for the current CMD/BAT session. Requires choco to be functional.
        call refreshenv >nul 2>&1
    ) else (
        echo ERROR: Failed to install Chocolatey or apply changes.
        echo -------------------------------------------------------------
        echo Please, try the following:
        echo 1. Close and reopen ALL terminals ^(CMD/PowerShell^) and run this script again.
        echo 2. If the problem persists, check your internet connection.
        echo 3. If the above steps do not resolve the issue, it's likely there's a problem with the integrity of your Windows installation.
        echo    In this case, you may need to investigate, repair, or even reinstall the operating system.
        echo -------------------------------------------------------------
        goto :TheEnd
    )
) else (
    echo Chocolatey is already installed.
)
echo.

REM --- 2. Software Installation via Chocolatey ---
echo =========================================================
echo   Starting software installations via Chocolatey...
echo =========================================================
echo.

REM --- GENERAL PACKAGE INSTALLATIONS VIA CHOCOLATEY ---
REM Installation via choco is idempotent, so we don't need to check beforehand.
REM It will install if not there, or do nothing/update if already there.
set "packagesToInstall=7zip curl notepadplusplus fastfetch"

for %%P in (%packagesToInstall%) do (
    echo Checking and installing %%P...
    choco install %%P -y --no-progress
    if !errorlevel! neq 0 (
        echo WARNING: Failed to install %%P. Exit code: !errorlevel!
    ) else (
        echo %%P installed/updated successfully.
    )
    echo.
)

echo All specified software installations attempted.
echo.

REM --- Check and create destination directory if necessary ---
echo Checking and creating destination directory if necessary: "%DESTINATION_PATH%"...
if not exist "%DESTINATION_PATH%\" (
    mkdir "%DESTINATION_PATH%"
    if %ERRORLEVEL% NEQ 0 (
        echo ERROR: Failed to create directory "%DESTINATION_PATH%".
        goto :TheEnd
    )
    echo Directory "%DESTINATION_PATH%" created.
) else (
    echo Directory "%DESTINATION_PATH%" already exists.
)
echo.

echo Checking if program %PROGRAM_NAME% is running...
tasklist /FI "IMAGENAME eq %PROGRAM_NAME%" 2>NUL | find /I /N "%PROGRAM_NAME%">NUL
if "%ERRORLEVEL%"=="0" (
    echo Program %PROGRAM_NAME% is running. Attempting to force close...
    taskkill /im %PROGRAM_NAME% /t /f >nul 2>&1
    if "%ERRORLEVEL%"=="0" (
        echo Program %PROGRAM_NAME% closed successfully.
    ) else (
        echo WARNING: Failed to close program %PROGRAM_NAME%. Continuing...
    )
) else (
    echo Program %PROGRAM_NAME% is not running.
)
echo.

echo Starting file download...
REM Ensure the parent directory for the download path exists.
if not exist "%DOWNLOAD_PATH%\.." (
    mkdir "%DOWNLOAD_PATH%\.."
    if %ERRORLEVEL% NEQ 0 (
        echo ERROR: Failed to create download directory "%DOWNLOAD_PATH%\..".
        goto :TheEnd
    )
)
curl -L "%DOWNLOAD_URL%" --output "%DOWNLOAD_PATH%"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to download file. Error code: %ERRORLEVEL%
    goto :TheEnd
)
echo Download complete.
echo.

REM --- Corrected Extraction Block ---
echo Extracting files using 7-Zip...
REM Using PowerShell to pipe the password without a newline
powershell -c "Write-Host '123' -NoNewLine" | 7z x "%DOWNLOAD_PATH%" -o"%DESTINATION_PATH%" -y
if %errorlevel% neq 0 (
    echo ERROR: Could not extract the file. Please verify the file integrity, the password, or if 7-Zip is installed.
    goto :TheEnd
)
echo Extraction complete.
echo.

REM =========================================================================
REM SCHEDULED TASK BLOCK
REM =========================================================================
echo ===========================================
echo   Scheduling the update task
echo ===========================================
echo.

REM -------------------------------------------------------------------------
REM CHOOSE ONE OF THE SCHEDULING OPTIONS BELOW AND UNCOMMENT IT.
REM MAKE SURE TO COMMENT OUT THE OTHER OPTIONS.
REM -------------------------------------------------------------------------

REM Option 1: Weekly Schedule (Every Monday at 12:00:00) - THIS IS THE DEFAULT OPTION
set "SCHEDULE_TYPE=/sc weekly"
set "SCHEDULE_MODIFIER=/mo 1"              REM -- Run every week
set "SCHEDULE_DAY=/d MON"                  REM -- Run on Monday (MON, TUE, WED, THU, FRI, SAT, SUN)
set "SCHEDULE_TIME=12:00:00"

REM Option 2: Daily Schedule (Every day at 03:00:00)
REM set "SCHEDULE_TYPE=/sc daily"
REM set "SCHEDULE_MODIFIER="                 REM -- No modifier for simple daily schedule
REM set "SCHEDULE_DAY="                      REM -- Do not use /d for simple daily schedule
REM set "SCHEDULE_TIME=03:00:00"

REM Option 3: Monthly Schedule (On the 1st of every month at 06:00:00)
REM set "SCHEDULE_TYPE=/sc monthly"
REM set "SCHEDULE_MODIFIER=/d 1"             REM -- Run on the 1st day of each month (1 to 31)
REM set "SCHEDULE_DAY="                      REM -- Do not use /d separately with /d X
REM set "SCHEDULE_TIME=06:00:00"

REM Option 4: Monthly Schedule (On the 3rd Tuesday of every month at 09:00:00)
REM set "SCHEDULE_TYPE=/sc monthly"
REM set "SCHEDULE_MODIFIER=/mo 3 /d TUE"     REM -- Run on the 3rd Tuesday of each month
REM set "SCHEDULE_DAY="                      REM -- Do not use /d separately here
REM set "SCHEDULE_TIME=09:00:00"

REM Option 5: Monthly Schedule (On the last Friday of every month at 23:00:00)
REM set "SCHEDULE_TYPE=/sc monthly"
REM set "SCHEDULE_MODIFIER=/mo LAST /d FRI"  REM -- Run on the last Friday of each month
REM set "SCHEDULE_DAY="                      REM -- Do not use /d separately here
REM set "SCHEDULE_TIME=23:00:00"

REM -------------------------------------------------------------------------
REM End of Scheduling Options
REM -------------------------------------------------------------------------

REM Try to delete the task first to ensure a clean slate, ignore errors if it doesn't exist
schtasks /delete /tn "%TASK_NAME%" /f > nul 2>&1

echo Attempting to create scheduled task "%TASK_NAME%"...
REM Capture the full output of schtasks /create for better debugging
set "SCHTASKS_OUTPUT="
for /f "delims=" %%i in ('schtasks /create /tn "%TASK_NAME%" /tr "%BATCH_FILE_PATH%" %SCHEDULE_TYPE% %SCHEDULE_MODIFIER% %SCHEDULE_DAY% /st %SCHEDULE_TIME% /RL HIGHEST 2^>^&1') do (
    set "SCHTASKS_OUTPUT=!SCHTASKS_OUTPUT!%%i"
)

REM Check if the task was actually created by querying it
schtasks /query /tn "%TASK_NAME%" > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo SUCCESS: Scheduled task "%TASK_NAME%" created successfully, pointing to "%BATCH_FILE_PATH%".
) else (
    echo ERROR: Failed to create scheduled task "%TASK_NAME%".
    echo Check the following details:
    echo - Does the path "%BATCH_FILE_PATH%" exist and is it accessible?
    echo - Do you have sufficient permissions to create scheduled tasks?
    echo - Is there any typo in the schedule parameters?
    echo --- schtasks output ---
    echo !SCHTASKS_OUTPUT!
    echo ---------------------
)
echo.

REM Reverting PowerShell execution policy to RemoteSigned for current user (suppress output)...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy -Scope CurrentUser RemoteSigned -Force" >nul 2>&1

echo ===========================================
echo   All update operations completed.
echo ===========================================

:TheEnd
echo.
echo Press any key to exit.
pause >nul
exit
