# Path to your Chrome executable (change if needed)
$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"

# Your user data profile path
$userDataDir = "C:\Users\meowm\AppData\Local\Google\Chrome\User Data\MyDevProfile"

# Your extension folder path
$extensionPath = "C:\Users\meowm\Desktop\pbl siber itu\bismillah\extension"

Write-Host "Starting Chrome watcher..."

while ($true) {
    # Get all running chrome processes
    $chromeProcs = Get-Process chrome -ErrorAction SilentlyContinue

    if ($chromeProcs) {
        # Check command line arguments of Chrome processes to see if --load-extension is present
        $allHaveExtension = $true

        foreach ($proc in $chromeProcs) {
            try {
                # Get command line of process (requires admin for other users; might fail)
                $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId=$($proc.Id)").CommandLine
            }
            catch {
                $cmdLine = ""
            }

            if (-not $cmdLine -or $cmdLine -notmatch "--load-extension") {
                $allHaveExtension = $false
                break
            }
        }

        if (-not $allHaveExtension) {
            Write-Host "Chrome detected without extension loaded. Restarting..."

            # Kill all Chrome processes (current user only)
            Stop-Process -Name chrome -Force -ErrorAction SilentlyContinue

            Start-Sleep -Seconds 3

            # Start Chrome with extension and user profile
            Start-Process $chromePath "--user-data-dir=`"$userDataDir`" --load-extension=`"$extensionPath`""

            Write-Host "Chrome restarted with extension."
        }
        else {
            Write-Host "Chrome is running with extension loaded. Waiting..."
        }
    }
    else {
        Write-Host "Chrome is not running. Waiting..."
    }

    Start-Sleep -Seconds 10
}
