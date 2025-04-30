# PowerShell script to monitor Firebase for user visits
$firebaseUrl = "https://check-6c35e-default-rtdb.asia-southeast1.firebasedatabase.app/user_visits.json"
$resetUrl = "https://check-6c35e-default-rtdb.asia-southeast1.firebasedatabase.app/user_visits.json"

while ($true) {
    try {
        # Get the latest user visit data from Firebase
        $visitData = Invoke-RestMethod -Uri $firebaseUrl

        if ($visitData) {
            foreach ($key in $visitData.PSObject.Properties.Name) {
                $visit = $visitData.$key
                Write-Host "New visit detected: URL = $($visit.url), Timestamp = $($visit.timestamp)"

                # You can add any additional logic here to check specific URLs or timestamps
                if ($visit.url -eq "https://yourwebsite.com/specific-page") {
                    Write-Host "User visited the specific page!"
                    
                    # Trigger the batch file or take an action based on the visit
                    Start-Process "cmd.exe" -ArgumentList "/c your_batch_command.bat"
                }
            }

            # Reset visit data in Firebase (optional, to prevent repeated triggers)
            Invoke-RestMethod -Uri $resetUrl -Method PUT -Body '{}'
        }

        # Add a small delay before checking again
        Start-Sleep -Seconds 1
    }
    catch {
        Write-Host "Error occurred: $_"
        Start-Sleep -Seconds 10
    }
}
