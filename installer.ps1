# Shield Antivirus - Windows Deployment Script
# Εκτελέστε το ως Administrator στο PowerShell

$ServiceName = "ShieldCoreAntivirus"
$InstallDir = "C:\Program Files\ShieldAntivirus"
$BinarySource = "target\release\shield_core.exe" # Το compiled binary της Rust

Write-Host "=== SHIELD ANTIVIRUS WINDOWS INSTALLER ===" -ForegroundColor Cyan

# 1. Έλεγχος δικαιωμάτων Administrator
If (!(([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
    Write-Error "Παρακαλώ εκτελέστε το PowerShell ως Διαχειριστής (Administrator)!"
    Exit
}

# 2. Δημιουργία φακέλων εγκατάστασης και καραντίνας
If (!(Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
    New-Item -ItemType Directory -Force -Path "$InstallDir\quarantine" | Out-Null
    Write-Host "[+] Created installation directory: $InstallDir" -ForegroundColor Green
}

# 3. Αντιγραφή του Binary
If (Test-Path $BinarySource) {
    Copy-Item $BinarySource -Destination "$InstallDir\shield_core.exe" -Force
    Write-Host "[+] Copied Shield binary successfully." -ForegroundColor Green
} else {
    Write-Error "Δεν βρέθηκε το compiled binary ($BinarySource). Κάντε πρώτα 'cargo build --release'!"
    Exit
}

# 4. Δημιουργία Windows Service μέσω sc.exe
$ExistingService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
If ($ExistingService) {
    Write-Host "[*] Stopping existing service..." -ForegroundColor Yellow
    Stop-Service -Name $ServiceName -ErrorAction SilentlyContinue
    sc.exe delete $ServiceName | Out-Null
}

Write-Host "[*] Registering Windows Service..." -ForegroundColor Yellow
sc.exe create $ServiceName binPath= "$InstallDir\shield_core.exe" start= auto DisplayName= "Shield Core Antivirus Protection"
sc.exe description $ServiceName "Real-time threat intelligence, network filtering, and behavioral ransomware protection."

# 5. Εκκίνηση της Υπηρεσίας
Start-Service -Name $ServiceName
Write-Host "[+] Shield Antivirus Service started successfully and set to Automatic!" -ForegroundColor Green
Write-Host "=== INSTALLATION COMPLETED ===" -ForegroundColor Cyan