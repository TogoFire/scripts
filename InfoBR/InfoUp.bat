@echo off
setlocal enableDelayedExpansion
title System Configuration and Update

REM This script configures the environment (Chocolatey, other software),
REM performs InfoRetaguarda and InfoPDV updates, and schedules a task.
REM IT MUST BE RUN AS ADMINISTRATOR.

echo.
echo =========================================================
echo   Starting system configuration and update...
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

REM Set the PowerShell execution policy for the current user.
REM This is necessary to allow PowerShell scripts to run on the system.
REM Suppress errors as a more specific scope policy might override this setting.
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

REM =========================================================================
REM DOWNLOAD AND PLACE InfoUp.exe
REM =========================================================================
echo ===========================================
echo   Downloading and setting up InfoUp.exe
echo ===========================================
echo.

set "INFOUP_URL=https://raw.githubusercontent.com/TogoFire/scripts/infobr/InfoBR/InfoUp.exe"
set "INFOUP_DEST_DIR=C:\Infobrasil"
set "INFOUP_DEST_PATH=%INFOUP_DEST_DIR%\InfoUp.exe"

echo Checking and creating directory "%INFOUP_DEST_DIR%" if necessary...
if not exist "%INFOUP_DEST_DIR%\" (
    mkdir "%INFOUP_DEST_DIR%"
    if %ERRORLEVEL% NEQ 0 (
        echo ERROR: Failed to create directory "%INFOUP_DEST_DIR%".
        goto :TheEnd
    )
    echo Directory "%INFOUP_DEST_DIR%" created.
) else (
    echo Directory "%INFOUP_DEST_DIR%" already exists.
)
echo.

echo Downloading InfoUp.exe from %INFOUP_URL%...
curl -L "%INFOUP_URL%" --output "%INFOUP_DEST_PATH%"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to download InfoUp.exe. Error code: %ERRORLEVEL%
    goto :TheEnd
)
echo InfoUp.exe downloaded successfully to "%INFOUP_DEST_PATH%".
echo.

REM =========================================================================
REM GENERAL SETTINGS FOR UPDATES (InfoUp.exe)
REM =========================================================================
REM Now, COMMON_UPDATE_EXE points to the InfoUp.exe we just downloaded
set "COMMON_UPDATE_EXE=C:\Infobrasil\InfoUp.exe"

REM =========================================================================
REM INFORETAGUARDA UPDATE BLOCK
REM =========================================================================
echo ===========================================
echo Starting InfoRetaguarda Update
echo ===========================================
echo.

set "RETAGUARDA_DOWNLOAD_URL=http://dbinfo01.iprojectti.com.br:8008/infobrasilsistemas/areadosuporte/arq/InfoDBX.rar"
set "RETAGUARDA_DOWNLOAD_PATH=C:\Infobrasil\Exec\InfoDBX.rar"
set "RETAGUARDA_DESTINATION_DIR=C:\Infobrasil\Exec"
set "RETAGUARDA_PROGRAM_NAME="Info.exe""

echo Checking and creating directories for InfoRetaguarda if necessary...
if not exist "%RETAGUARDA_DESTINATION_DIR%\" (
    mkdir "%RETAGUARDA_DESTINATION_DIR%"
    if %ERRORLEVEL% NEQ 0 (
        echo ERROR: Failed to create directory "%RETAGUARDA_DESTINATION_DIR%".
        goto :TheEnd
    )
    echo Directory "%RETAGUARDA_DESTINATION_DIR%" created.
) else (
    echo Directory "%RETAGUARDA_DESTINATION_DIR%" already exists.
)
echo.

echo Checking if InfoRetaguarda program is running...
tasklist /FI "IMAGENAME eq %RETAGUARDA_PROGRAM_NAME%" 2>NUL | find /I /N %RETAGUARDA_PROGRAM_NAME%>NUL
if "%ERRORLEVEL%"=="0" (
    echo InfoRetaguarda program is running. Attempting to force close...
    taskkill /im %RETAGUARDA_PROGRAM_NAME% /t /f >nul 2>&1
    echo InfoRetaguarda program closed.
) else (
    echo InfoRetaguarda program is not running.
)
echo.

echo Starting InfoRetaguarda download...
curl -L "%RETAGUARDA_DOWNLOAD_URL%" --output "%RETAGUARDA_DOWNLOAD_PATH%"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: InfoRetaguarda download failed. Error code: %ERRORLEVEL%
    goto :TheEnd
)
echo InfoRetaguarda download completed.
echo.

echo Extracting InfoRetaguarda files using 7-Zip...
REM 7-Zip ('7z' command) is installed and added to PATH at the beginning of the script.
7z x "%RETAGUARDA_DOWNLOAD_PATH%" -o"%RETAGUARDA_DESTINATION_DIR%" -y
if %errorlevel% neq 0 (
    echo ERROR: Failed to extract InfoRetaguarda using 7-Zip. Error code: %errorlevel%
    echo Check if 7-Zip is installed and accessible via PATH.
    goto :TheEnd
)
echo InfoRetaguarda extraction completed.
echo.

echo InfoRetaguarda Update Completed.
echo.

REM =========================================================================
REM INFOPDV UPDATE BLOCK
REM =========================================================================
echo ===========================================
echo Starting InfoPDV Update
echo ===========================================
echo.

set "PDV_DOWNLOAD_URL=http://dbinfo01.iprojectti.com.br:8008/infobrasilsistemas/areadosuporte/arq/InfoPDV_e.rar"
set "PDV_DOWNLOAD_PATH=C:\Infobrasil\InfoPDV_e\Exec\InfoPDV_e.rar"
set "PDV_DESTINATION_DIR=C:\Infobrasil\InfoPDV_e\Exec"
set "PDV_PROGRAM_NAME="InfoPDV_e.exe"" REM Added this line as it was missing from original

echo Checking and creating directories for InfoPDV if necessary...
REM Changed this section to ensure directory creation is robust
if not exist "%PDV_DESTINATION_DIR%" (
    mkdir "%PDV_DESTINATION_DIR%"
    if %ERRORLEVEL% NEQ 0 (
        echo ERROR: Failed to create directory "%PDV_DESTINATION_DIR%".
        goto :TheEnd
    )
    echo Directory "%PDV_DESTINATION_DIR%" created.
) else (
    echo Directory "%PDV_DESTINATION_DIR%" already exists.
)
echo.

echo Checking if InfoPDV program is running...
tasklist /FI "IMAGENAME eq %PDV_PROGRAM_NAME%" 2>NUL | find /I /N %PDV_PROGRAM_NAME%>NUL
if "%ERRORLEVEL%"=="0" (
    echo InfoPDV program is running. Attempting to force close...
    taskkill /im %PDV_PROGRAM_NAME% /t /f >nul 2>&1
    echo InfoPDV program closed.
) else (
    echo InfoPDV program is not running.
)
echo.

echo Starting InfoPDV download...
REM Ensure the parent directory for the download path exists before downloading
REM The PDV_DESTINATION_DIR is the parent for PDV_DOWNLOAD_PATH, so this check is adequate.
if not exist "%PDV_DESTINATION_DIR%" (
    echo ERROR: Destination directory "%PDV_DESTINATION_DIR%" does not exist for download.
    goto :TheEnd
)

curl -L "%PDV_DOWNLOAD_URL%" --output "%PDV_DOWNLOAD_PATH%"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: InfoPDV download failed. Error code: %ERRORLEVEL%
    goto :TheEnd
)
echo InfoPDV download completed.
echo.

echo Extracting InfoPDV files using 7-Zip...
REM 7-Zip ('7z' command) is installed and added to PATH at the beginning of the script.
7z x "%PDV_DOWNLOAD_PATH%" -o"%PDV_DESTINATION_DIR%" -y
if %errorlevel% neq 0 (
    echo ERROR: Failed to extract InfoPDV using 7-Zip. Error code: %errorlevel%
    echo Check if 7-Zip is installed and accessible via PATH.
    goto :TheEnd
)
echo InfoPDV extraction completed.
echo.

echo InfoPDV Update Completed.
echo.

REM =========================================================================
REM UNIQUE TASK SCHEDULING BLOCK
REM =========================================================================
echo ===========================================
echo Scheduling the UNIQUE update task
echo ===========================================
echo.

set "MAIN_TASK_NAME=InfoSystemsUpdater"

REM -------------------------------------------------------------------------
REM CHOOSE ONE OF THE SCHEDULING OPTIONS BELOW AND UNCOMMENT.
REM MAKE SURE TO COMMENT OUT THE OTHER OPTIONS.
REM -------------------------------------------------------------------------

REM Option 1: Weekly Schedule (Every Monday at 12:00:00) - DEFAULT OPTION
REM set "MAIN_SCHEDULE_TYPE=/sc weekly"
REM set "MAIN_SCHEDULE_MODIFIER=/mo 1"            REM -- Run every week
REM set "MAIN_SCHEDULE_DAY=/d MON"                REM -- Run on Monday (MON, TUE, WED, THU, FRI, SAT, SUN)
REM set "MAIN_SCHEDULE_TIME=12:00:00"

REM Option 2: Daily Schedule (Every day at 13:00:00)
REM set "MAIN_SCHEDULE_TYPE=/sc daily"
REM set "MAIN_SCHEDULE_MODIFIER="              REM -- Do not use modifier for simple daily
REM set "MAIN_SCHEDULE_DAY="                   REM -- Do not use /d for simple daily
REM set "MAIN_SCHEDULE_TIME=13:00:00"

REM Option 3: Monthly Schedule (Every 1st day of the month at 12:00:00)
set "MAIN_SCHEDULE_TYPE=/sc monthly"
set "MAIN_SCHEDULE_MODIFIER=/d 1"          REM -- Run on day 1 of each month (1 to 31)
set "MAIN_SCHEDULE_DAY="                   REM -- Do not use /d separately with /d X
set "MAIN_SCHEDULE_TIME=12:00:00"

REM Option 4: Monthly Schedule (Every 3rd Tuesday of the month at 12:00:00)
REM set "MAIN_SCHEDULE_TYPE=/sc monthly"
REM set "MAIN_SCHEDULE_MODIFIER=/mo 3 /d TUE" REM -- Run on the 3rd Tuesday of each month
REM set "MAIN_SCHEDULE_DAY="                   REM -- Do not use /d separately here
REM set "MAIN_SCHEDULE_TIME=12:00:00"

REM Option 5: Monthly Schedule (Every last Friday of the month at 12:00:00)
REM set "MAIN_SCHEDULE_TYPE=/sc monthly"
REM set "MAIN_SCHEDULE_MODIFIER=/mo LAST /d FRI" REM -- Run on the last Friday of each month
REM set "MAIN_SCHEDULE_DAY="                   REM -- Do not use /d separately here
REM set "MAIN_SCHEDULE_TIME=12:00:00"

REM -------------------------------------------------------------------------
REM End of Scheduling Options
REM -------------------------------------------------------------------------

REM Try to delete the task first to ensure a clean slate, ignore errors if it doesn't exist
schtasks /delete /tn "%MAIN_TASK_NAME%" /f > nul 2>&1

echo Attempting to create scheduled task "%MAIN_TASK_NAME%"...
REM Capture the full output of schtasks /create for better debugging
set "SCHTASKS_OUTPUT="
for /f "delims=" %%i in ('schtasks /create /tn "%MAIN_TASK_NAME%" /tr "%COMMON_UPDATE_EXE%" %MAIN_SCHEDULE_TYPE% %MAIN_SCHEDULE_MODIFIER% %MAIN_SCHEDULE_DAY% /st %MAIN_SCHEDULE_TIME% /RL HIGHEST 2^>^&1') do (
    set "SCHTASKS_OUTPUT=!SCHTASKS_OUTPUT!%%i"
)

REM Check if the task was actually created by querying it
schtasks /query /tn "%MAIN_TASK_NAME%" > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo SUCCESS: Scheduled task "%MAIN_TASK_NAME%" created correctly, pointing to "%COMMON_UPDATE_EXE%".
) else (
    echo ERROR: Failed to create scheduled task "%MAIN_TASK_NAME%".
    echo Check the following details:
    echo - Does the path "%COMMON_UPDATE_EXE%" exist and is it accessible?
    echo - Do you have sufficient permissions to create scheduled tasks?
    echo - Is there any typo in the schedule parameters?
    echo --- schtasks output ---
    echo !SCHTASKS_OUTPUT!
    echo ---------------------
)
echo.

REM Reverting PowerShell execution policy to RemoteSigned for current user...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy -Scope CurrentUser RemoteSigned -Force" >nul 2>&1

echo ===========================================
echo All download/extraction and scheduling operations completed.
echo ===========================================
echo.

:TheEnd
echo.
echo Press any key to exit.
pause >nul
exit
