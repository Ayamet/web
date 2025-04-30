@echo off
setlocal enabledelayedexpansion

:: Set Firebase URL for reading and writing data
set firebase_url=https://check-6c35e-default-rtdb.asia-southeast1.firebasedatabase.app/user_visits.json

:: Loop to constantly check Firebase for new data
:loop
:: Fetch the latest data from Firebase
curl -s %firebase_url% > visit_data.json

:: Check if there is any new data by reading the file
for /f "delims=" %%i in (visit_data.json) do (
    set visit=%%i
    :: If visit contains a specific value (like a URL or command), trigger batch commands
    echo Checking for visit...
    if "!visit!"=="specific_command_to_trigger" (
        echo Command triggered, running batch command...
        :: Replace with your actual batch command or script to run
        call your_batch_command.bat
    )
)

:: Pause for 1 second before checking again
timeout /t 1 >nul
goto loop
