if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: Run as Administrator" -ForegroundColor Red
    Read-Host -Prompt "Press Enter to exit"
    exit
}

$confirm = Read-Host "Continue? (y/n)"
if ($confirm -ne 'y') { exit }

Write-Host "Applying privacy fixes..." -ForegroundColor Cyan

# ============================================
# HOSTS FILE - BLOCK TELEMETRY DOMAINS
# ============================================
$hostsPath = "$env:windir\System32\drivers\etc\hosts"
$hostsBackup = "$hostsPath.gdid_backup"
Copy-Item -Path $hostsPath -Destination $hostsBackup -Force -ErrorAction SilentlyContinue

$domainsToBlock = @(
"127.0.0.1 settings-win.data.microsoft.com",
"127.0.0.1 dds.microsoft.com",
"127.0.0.1 cs.dds.microsoft.com",
"127.0.0.1 watson.telemetry.microsoft.com",
"127.0.0.1 telemetry.microsoft.com",
"127.0.0.1 vortex.data.microsoft.com",
"127.0.0.1 vortex-win.data.microsoft.com",
"127.0.0.1 telecommand.telemetry.microsoft.com",
"127.0.0.1 v10.vortex-win.data.microsoft.com",
"127.0.0.1 v10.events.data.microsoft.com",
"127.0.0.1 oca.telemetry.microsoft.com",
"127.0.0.1 oca.telemetry.microsoft.com.nsatc.net",
"127.0.0.1 sqm.telemetry.microsoft.com",
"127.0.0.1 sqm.telemetry.microsoft.com.nsatc.net",
"127.0.0.1 redird.data.microsoft.com",
"127.0.0.1 redird.data.microsoft.com.nsatc.net",
"127.0.0.1 watson.telemetry.microsoft.com.nsatc.net",
"127.0.0.1 diagnostics.support.microsoft.com",
"127.0.0.1 corp.sts.microsoft.com",
"127.0.0.1 statsfe1.ws.microsoft.com",
"127.0.0.1 statsfe2.ws.microsoft.com",
"127.0.0.1 az667904.vo.msecnd.net",
"127.0.0.1 df.telemetry.microsoft.com",
"127.0.0.1 ads.msn.com",
"127.0.0.1 adnxs.com",
"127.0.0.1 choice.microsoft.com",
"127.0.0.1 choice.microsoft.com.nsatc.net",
"127.0.0.1 compatexchange.cloudapp.net",
"127.0.0.1 configuration.live.com",
"127.0.0.1 dc.services.visualstudio.com",
"127.0.0.1 fe2.update.microsoft.com.akadns.net",
"127.0.0.1 feedback.microsoft-hohm.com",
"127.0.0.1 feedback.search.microsoft.com",
"127.0.0.1 feedback.windows.com",
"127.0.0.1 i1.services.social.microsoft.com",
"127.0.0.1 i1.services.social.microsoft.com.nsatc.net",
"127.0.0.1 pre.footprintpredict.com",
"127.0.0.1 redir.metaservices.microsoft.com",
"127.0.0.1 reports.wes.df.telemetry.microsoft.com",
"127.0.0.1 service.ws.microsoft.com",
"127.0.0.1 settings-sandbox.data.microsoft.com",
"127.0.0.1 sls.update.microsoft.com.akadns.net",
"127.0.0.1 sqm.df.telemetry.microsoft.com",
"127.0.0.1 telecommand.telemetry.microsoft.com.nsatc.net",
"127.0.0.1 telemetry.microsoft.com.nsatc.net",
"127.0.0.1 vortex.telemetry.microsoft.com",
"127.0.0.1 vortex.telemetry.microsoft.com.nsatc.net",
"127.0.0.1 watson.microsoft.com",
"127.0.0.1 watson.ppe.telemetry.microsoft.com",
"127.0.0.1 wes.df.telemetry.microsoft.com",
"127.0.0.1 wes.df.telemetry.microsoft.com.nsatc.net"
)

foreach ($domain in $domainsToBlock) {
    if ((Get-Content $hostsPath -ErrorAction SilentlyContinue) -notcontains $domain) {
        Add-Content -Path $hostsPath -Value $domain -ErrorAction SilentlyContinue
    }
}

ipconfig /flushdns | Out-Null

# ============================================
# FIREWALL RULES
# ============================================
$blockedExes = @(
"C:\Windows\System32\DiagTrackRunner.exe",
"C:\Windows\System32\CompatTelRunner.exe"
)

foreach ($exePath in $blockedExes) {
    $exeName = [System.IO.Path]::GetFileName($exePath)
    $ruleName = "Block_GDID_$exeName"
    netsh advfirewall firewall delete rule name="$ruleName" > $null 2>&1
    netsh advfirewall firewall add rule name="$ruleName" dir=out action=block program="$exePath" > $null 2>&1
}

# ============================================
# TELEMETRY & DATA COLLECTION
# ============================================
Write-Host "Disabling telemetry and data collection..." -ForegroundColor Yellow

# Disable Tailored Experiences
New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" -Force -ErrorAction SilentlyContinue | Out-Null
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Value 0 -Type DWord -Force

# Disable Advertising ID
New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Force -ErrorAction SilentlyContinue | Out-Null
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -Type DWord -Force

# Disable Improve Inking and Typing
Set-ItemProperty -Path "HKCU:\Software\Microsoft\InputPersonalization" -Name "RestrictImplicitTextCollection" -Value 1 -Type DWord -Force
Set-ItemProperty -Path "HKCU:\Software\Microsoft\InputPersonalization" -Name "RestrictImplicitInkCollection" -Value 1 -Type DWord -Force
New-Item -Path "HKLM:\Software\Policies\Microsoft\InputPersonalization" -Force -ErrorAction SilentlyContinue | Out-Null
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\InputPersonalization" -Name "AllowInputPersonalization" -Value 0 -Type DWord -Force

# Disable Windows Error Reporting
New-Item -Path "HKLM:\Software\Microsoft\Windows\Windows Error Reporting" -Force -ErrorAction SilentlyContinue | Out-Null
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\Windows Error Reporting" -Name "Disabled" -Value 1 -Type DWord -Force

# Disable Activity History
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Force -ErrorAction SilentlyContinue | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Value 0 -Type DWord -Force

# Disable Cloud Content Sync
New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync" -Force -ErrorAction SilentlyContinue | Out-Null
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync" -Name "SyncPolicy" -Value 5 -Type DWord -Force

# ============================================
# SERVICES & SCHEDULED TASKS
# ============================================
Write-Host "Disabling services and scheduled tasks..." -ForegroundColor Yellow

# Disable Services
$servicesToDisable = @(
"DiagTrack",
"dmwappushservice",
"CDPSvc",
"DoSvc",
"diagnosticshub.standardcollector.service",
"XblAuthManager",
"XblGameSave",
"XboxNetApiSvc",
"RetailDemo"
)

foreach ($serviceName in $servicesToDisable) {
    try {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($service) {
            Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
            Set-Service -Name $serviceName -StartupType Disabled -ErrorAction SilentlyContinue
        }
    } catch {}
}

# Disable Xbox Services via Registry
New-Item -Path "HKLM:\System\CurrentControlSet\Services\XblAuthManager" -Force -ErrorAction SilentlyContinue | Out-Null
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\XblAuthManager" -Name "Start" -Value 4 -Type DWord -Force

# Disable Additional Telemetry Scheduled Tasks
$telemetryTasks = @(
"Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
"Microsoft\Windows\Application Experience\ProgramDataUpdater",
"Microsoft\Windows\Application Experience\StartupAppTask",
"Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
"Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask",
"Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
"Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector",
"Microsoft\Windows\Windows Error Reporting\QueueReporting",
"Microsoft\Windows\Feedback\Siuf\DmClient",
"Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload"
)

foreach ($taskPath in $telemetryTasks) {
    schtasks /query /tn "$taskPath" 2>$null
    if ($LASTEXITCODE -eq 0) {
        schtasks /change /tn "$taskPath" /disable > $null 2>&1
    }
}

# ============================================
# FEATURES & APP PERMISSIONS
# ============================================
Write-Host "Configuring features and permissions..." -ForegroundColor Yellow

# Disable Cortana
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Force -ErrorAction SilentlyContinue | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Personalization\Settings" -Name "CortanaEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

# Disable Location Tracking
New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Force -ErrorAction SilentlyContinue | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Value "Deny" -Type String -Force
New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\loosely coupled" -Force -ErrorAction SilentlyContinue | Out-Null
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\DeviceAccess\Global\loosely coupled" -Name "Value" -Value "Deny" -Type String -Force

# Disable Microsoft Account Sign-In Assistant
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "DisableAutoDaylightTimeSet" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

# ============================================
# MICROSOFT ACCOUNT & CLOUD
# ============================================
Write-Host "Disabling Microsoft Account and Cloud features..." -ForegroundColor Yellow

# Disable OneDrive
Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
$onedrive = "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe"
if (Test-Path $onedrive) {
    & $onedrive /uninstall
}
Start-Sleep -Seconds 2
Remove-Item -Path "$env:USERPROFILE\OneDrive" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\OneDrive" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "$env:PROGRAMDATA\Microsoft OneDrive" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "$env:SYSTEMDRIVE\OneDriveTemp" -Force -Recurse -ErrorAction SilentlyContinue

# Prevent OneDrive from reinstalling
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Force -ErrorAction SilentlyContinue | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSyncNGSC" -Value 1 -Type DWord -Force

# Disable Cloud Content Sync
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Force -ErrorAction SilentlyContinue | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Name "DisableSettingSync" -Value 2 -Type DWord -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Name "DisableSettingSyncUserOverride" -Value 1 -Type DWord -Force

# ============================================
# REMOVE PRE-INSTALLED APPS (BLOATWARE)
# ============================================
Write-Host "Removing pre-installed bloatware apps..." -ForegroundColor Yellow

$bloatwareApps = @(
"Microsoft.BingWeather",
"Microsoft.GetHelp",
"Microsoft.Getstarted",
"Microsoft.MicrosoftOfficeHub",
"Microsoft.MicrosoftSolitaireCollection",
"Microsoft.MicrosoftStickyNotes",
"Microsoft.MSPaint",
"Microsoft.Office.OneNote",
"Microsoft.People",
"Microsoft.ScreenSketch",
"Microsoft.StorePurchaseApp",
"Microsoft.Wallet",
"Microsoft.WindowsAlarms",
"Microsoft.WindowsCalculator",
"Microsoft.WindowsCamera",
"Microsoft.WindowsCommunicationsApps",
"Microsoft.WindowsFeedbackHub",
"Microsoft.WindowsMaps",
"Microsoft.WindowsSoundRecorder",
"Microsoft.XboxApp",
"Microsoft.XboxGameCallableUI",
"Microsoft.XboxGamingOverlay",
"Microsoft.XboxIdentityProvider",
"Microsoft.XboxSpeechToTextOverlay",
"Microsoft.YourPhone",
"Microsoft.ZuneMusic",
"Microsoft.ZuneVideo",
"Microsoft.549981C3F5F10",
"Microsoft.BingFinance",
"Microsoft.BingNews",
"Microsoft.BingSports",
"Microsoft.BingTranslator",
"Microsoft.BingTravel",
"Microsoft.BingFoodAndDrink",
"Microsoft.BingHealthAndFitness",
"Microsoft.WindowsReadingList",
"Microsoft.MinecraftUWP",
"Microsoft.SkypeApp",
"Microsoft.Todos",
"Microsoft.Windows.Photos",
"Microsoft.WindowsStore",
"Microsoft.Advertising.Xaml",
"Microsoft.NET.Native.Framework.1.0",
"Microsoft.NET.Native.Framework.1.1",
"Microsoft.NET.Native.Framework.1.2",
"Microsoft.NET.Native.Framework.1.3",
"Microsoft.NET.Native.Framework.1.4",
"Microsoft.NET.Native.Framework.1.5",
"Microsoft.NET.Native.Framework.1.6",
"Microsoft.NET.Native.Framework.1.7",
"Microsoft.NET.Native.Runtime.1.0",
"Microsoft.NET.Native.Runtime.1.1",
"Microsoft.NET.Native.Runtime.1.2",
"Microsoft.NET.Native.Runtime.1.3",
"Microsoft.NET.Native.Runtime.1.4",
"Microsoft.NET.Native.Runtime.1.5",
"Microsoft.NET.Native.Runtime.1.6",
"Microsoft.NET.Native.Runtime.1.7",
"Microsoft.VCLibs.120.00",
"Microsoft.VCLibs.120.00.Universal",
"Microsoft.VCLibs.140.00",
"Microsoft.VCLibs.140.00.UWPDesktop",
"Microsoft.Services.Store.Engagement",
"Microsoft.Services.Store.PurchaseContract",
"Microsoft.Advertising.Xaml",
"Microsoft.Advertising.Xamarin.Android",
"Microsoft.Advertising.Xamarin.iOS",
"Microsoft.Advertising.JavaScript",
"Microsoft.Advertising.WinRT",
"Microsoft.Advertising.WinRT.Phone",
"Microsoft.Advertising.Mobile",
"Microsoft.Advertising",
"SpotifyAB.SpotifyMusic",
"Amazon.com.Amazon",
"Facebook.FacebookBeta",
"Facebook.InstagramBeta",
"PandoraMediaInc.Pandora",
"Netflix.Netflix",
"Flipboard.Flipboard",
"ShazamEntertainmentLtd.Shazam",
"Twitter.Twitter",
"Evernote.Evernote",
"Viber.Viber",
"Duolingo.Duolingo",
"TikTok.TikTok",
"Snapchat.Snapchat",
"Pinterest.Pinterest"
)

foreach ($app in $bloatwareApps) {
    try {
        Get-AppxPackage -Name $app -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.PackageName -like "$app*" } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    } catch {}
}

# Remove Microsoft Edge remnants (optional)
try {
    Get-AppxPackage -Name "Microsoft.MicrosoftEdge" -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
} catch {}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  COMPLETE! Changes Applied:" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✓ Hosts file updated with telemetry domain blocks" -ForegroundColor White
Write-Host "✓ Firewall rules created" -ForegroundColor White
Write-Host "✓ Telemetry and data collection disabled" -ForegroundColor White
Write-Host "✓ Xbox services disabled" -ForegroundColor White
Write-Host "✓ Retail Demo service disabled" -ForegroundColor White
Write-Host "✓ Cortana disabled" -ForegroundColor White
Write-Host "✓ Location tracking disabled" -ForegroundColor White
Write-Host "✓ OneDrive removed" -ForegroundColor White
Write-Host "✓ Cloud content sync disabled" -ForegroundColor White
Write-Host "✓ Pre-installed bloatware apps removed" -ForegroundColor White
Write-Host ""
Write-Host "Features affected:" -ForegroundColor Yellow
Write-Host "  ✗ Phone Link (Your Phone)" -ForegroundColor Gray
Write-Host "  ✗ Cloud Clipboard" -ForegroundColor Gray
Write-Host "  ✗ Nearby Sharing" -ForegroundColor Gray
Write-Host "  ✗ P2P Windows Updates" -ForegroundColor Gray
Write-Host "  ✗ Xbox services" -ForegroundColor Gray
Write-Host "  ✗ Cortana" -ForegroundColor Gray
Write-Host "  ✗ OneDrive" -ForegroundColor Gray
Write-Host "  ✗ Timeline/Activity History" -ForegroundColor Gray
Write-Host ""
Write-Host "IMPORTANT: You MUST restart your computer for all changes to take effect!" -ForegroundColor Yellow
Write-Host ""
Read-Host -Prompt "Press Enter to exit"