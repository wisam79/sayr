$DeviceId = "android" # Default fallback

# Check if there is already an active connected device
$devices = adb devices | Select-String -Pattern "\bdevice\b"
if ($devices) {
    Write-Host "Found already connected device(s):" -ForegroundColor Green
    # Get the ID of the first connected device
    $DeviceId = $devices[0].Line.Split("`t")[0]
    Write-Host " - Using device ID: $DeviceId" -ForegroundColor Cyan
} else {
    Write-Host "No connected devices found. Scanning network for Wireless Debugging services..." -ForegroundColor Yellow
    
    # Query mDNS services to discover the wireless debugging IP/Port automatically
    $mdnsLine = adb mdns services | Select-String -Pattern "_adb-tls-connect" | Select-Object -First 1
    
    if ($mdnsLine) {
        $parts = $mdnsLine.Line -split '\s+'
        $Address = $parts[-1]
        Write-Host "Auto-discovered wireless debugging address: $Address" -ForegroundColor Green
        
        Write-Host "Connecting to $Address..." -ForegroundColor Cyan
        adb connect $Address
        $DeviceId = $Address
    } else {
        Write-Warning "Could not auto-discover any wireless debugging services on the local network."
        $Address = Read-Host "Please enter the address manually (IP:PORT), or press Enter to try default"
        
        if ($Address) {
            Write-Host "Connecting to manually entered address: $Address..." -ForegroundColor Cyan
            adb connect $Address
            $DeviceId = $Address
        }
    }
}

# Run the Flutter app on the target device with environment variables
Write-Host "Launching Flutter application on device '$DeviceId' with .env configuration..." -ForegroundColor Green
cd apps/mobile
C:\flutter\bin\flutter.bat run -d $DeviceId --dart-define-from-file=../../.env
