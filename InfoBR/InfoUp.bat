@echo off
title Update InfoRetaguarda

set "DOWNLOAD_URL=http://dbinfo01.iprojectti.com.br:8008/infobrasilsistemas/areadosuporte/arq/InfoDBX.zip"
set "DOWNLOAD_PATH=C:\Infobrasil\Exec\InfoDBX.zip"
set "DESTINATION_PATH=C:\Infobrasil\Exec"

echo Starting download...

curl "%DOWNLOAD_URL%" --output "%DOWNLOAD_PATH%"

echo Extracting file...

powershell Expand-Archive -Force -Path "%DOWNLOAD_PATH%" -DestinationPath "%DESTINATION_PATH%"

echo Done.

:TheEnd
echo.
echo Press any key to exit.
pause >nul
exit
