$ErrorActionPreference = 'Stop'
$taskName = 'Network Gateway Hotkeys'
$installDirectory = Join-Path $env:ProgramData 'NetworkGatewayHotkeys'

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"{0}"' -f $PSCommandPath)
    )
    exit
}

Stop-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $installDirectory -Recurse -Force -ErrorAction SilentlyContinue

Add-Type -AssemblyName PresentationFramework
[System.Windows.MessageBox]::Show('Network hotkeys have been removed.', 'Network hotkeys', 'OK', 'Information') | Out-Null
