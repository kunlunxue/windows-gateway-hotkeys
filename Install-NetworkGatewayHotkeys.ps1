$ErrorActionPreference = 'Stop'

$source = Join-Path $PSScriptRoot 'NetworkGatewayHotkeys.ps1'
$installDirectory = Join-Path $env:ProgramData 'NetworkGatewayHotkeys'
$installedScript = Join-Path $installDirectory 'NetworkGatewayHotkeys.ps1'
$taskName = 'Network Gateway Hotkeys'

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"{0}"' -f $PSCommandPath)
    )
    exit
}

New-Item -ItemType Directory -Path $installDirectory -Force | Out-Null
Copy-Item -LiteralPath $source -Destination $installedScript -Force

$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$installedScript`""
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$principal = New-ScheduledTaskPrincipal -UserId ([Security.Principal.WindowsIdentity]::GetCurrent().Name) -LogonType Interactive -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero) -MultipleInstances IgnoreNew
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
Start-ScheduledTask -TaskName $taskName

Add-Type -AssemblyName PresentationFramework
[System.Windows.MessageBox]::Show(
    "Installation complete.`n`nCtrl+Alt+1: switch to 192.168.3.1`nCtrl+Alt+2: switch to 192.168.3.11`nCtrl+Alt+G: show current gateway and DNS",
    'Network hotkeys', 'OK', 'Information'
) | Out-Null
