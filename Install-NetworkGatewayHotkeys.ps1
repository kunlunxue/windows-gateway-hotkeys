$ErrorActionPreference = 'Stop'

$source = Join-Path $PSScriptRoot 'NetworkGatewayHotkeys.ps1'
$installDirectory = Join-Path $env:ProgramData 'NetworkGatewayHotkeys'
$installedScript = Join-Path $installDirectory 'NetworkGatewayHotkeys.ps1'
$configPath = Join-Path $installDirectory 'Config.json'
$taskName = 'Network Gateway Hotkeys'

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"{0}"' -f $PSCommandPath)
    )
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Test-IPv4([string]$value) {
    $parsed = [System.Net.IPAddress]::None
    return [System.Net.IPAddress]::TryParse($value.Trim(), [ref]$parsed) -and
        $parsed.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork
}

function Split-Dns([string]$value) {
    return @($value -split '[,;\s]+' | Where-Object { $_ })
}

$adapters = @(Get-NetAdapter -Physical | Where-Object Status -ne Disabled | Sort-Object Name)
if (-not $adapters) { throw 'No enabled physical network adapters were found.' }

$defaultRoute = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Sort-Object RouteMetric, InterfaceMetric | Select-Object -First 1
$defaultAdapter = if ($defaultRoute) { $defaultRoute.InterfaceAlias } else { $adapters[0].Name }
$currentGateway = if ($defaultRoute) { $defaultRoute.NextHop } else { '' }
$currentDns = if ($defaultRoute) {
    (Get-DnsClientServerAddress -InterfaceIndex $defaultRoute.InterfaceIndex -AddressFamily IPv4).ServerAddresses -join ', '
} else { '' }

$form = [System.Windows.Forms.Form]::new()
$form.Text = 'Configure network gateway hotkeys'
$form.ClientSize = [System.Drawing.Size]::new(520, 310)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.MinimizeBox = $false

function Add-Label([string]$text, [int]$x, [int]$y, [int]$width = 140) {
    $control = [System.Windows.Forms.Label]::new()
    $control.Text = $text
    $control.Location = [System.Drawing.Point]::new($x, $y)
    $control.Size = [System.Drawing.Size]::new($width, 23)
    $form.Controls.Add($control)
}

function Add-TextBox([int]$x, [int]$y, [string]$text = '') {
    $control = [System.Windows.Forms.TextBox]::new()
    $control.Location = [System.Drawing.Point]::new($x, $y)
    $control.Size = [System.Drawing.Size]::new(325, 23)
    $control.Text = $text
    $form.Controls.Add($control)
    return $control
}

Add-Label 'Network adapter' 20 24
$adapterBox = [System.Windows.Forms.ComboBox]::new()
$adapterBox.Location = [System.Drawing.Point]::new(170, 20)
$adapterBox.Size = [System.Drawing.Size]::new(325, 23)
$adapterBox.DropDownStyle = 'DropDownList'
[void]$adapterBox.Items.AddRange([object[]]@($adapters.Name))
$adapterBox.SelectedItem = $defaultAdapter
if ($adapterBox.SelectedIndex -lt 0) { $adapterBox.SelectedIndex = 0 }
$form.Controls.Add($adapterBox)

Add-Label 'Profile A gateway' 20 70
$gatewayA = Add-TextBox 170 66 $currentGateway
Add-Label 'Profile A DNS' 20 108
$dnsA = Add-TextBox 170 104 $currentDns
Add-Label 'Profile B gateway' 20 154
$gatewayB = Add-TextBox 170 150 ''
Add-Label 'Profile B DNS' 20 192
$dnsB = Add-TextBox 170 188 ''
Add-Label 'Multiple DNS addresses: separate with commas.' 170 222 325

$installButton = [System.Windows.Forms.Button]::new()
$installButton.Text = 'Install'
$installButton.Location = [System.Drawing.Point]::new(315, 260)
$installButton.Size = [System.Drawing.Size]::new(85, 30)
$form.Controls.Add($installButton)

$cancelButton = [System.Windows.Forms.Button]::new()
$cancelButton.Text = 'Cancel'
$cancelButton.Location = [System.Drawing.Point]::new(410, 260)
$cancelButton.Size = [System.Drawing.Size]::new(85, 30)
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.Controls.Add($cancelButton)
$form.CancelButton = $cancelButton

$installButton.Add_Click({
    $dnsAValues = @(Split-Dns $dnsA.Text)
    $dnsBValues = @(Split-Dns $dnsB.Text)
    $allDns = $dnsAValues + $dnsBValues
    if (-not (Test-IPv4 $gatewayA.Text) -or -not (Test-IPv4 $gatewayB.Text) -or
        $dnsAValues.Count -lt 1 -or $dnsBValues.Count -lt 1 -or
        @($allDns | Where-Object { -not (Test-IPv4 $_) }).Count -gt 0) {
        [System.Windows.Forms.MessageBox]::Show(
            'Enter valid IPv4 addresses for both gateways and DNS profiles.',
            'Invalid configuration', 'OK', 'Warning'
        ) | Out-Null
        return
    }
    $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Close()
})

if ($form.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { exit }

$config = [ordered]@{
    InterfaceAlias = [string]$adapterBox.SelectedItem
    ProfileA = [ordered]@{ Gateway = $gatewayA.Text.Trim(); Dns = @(Split-Dns $dnsA.Text) }
    ProfileB = [ordered]@{ Gateway = $gatewayB.Text.Trim(); Dns = @(Split-Dns $dnsB.Text) }
}

Stop-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $installDirectory -Force | Out-Null
Copy-Item -LiteralPath $source -Destination $installedScript -Force
$config | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $configPath -Encoding UTF8

$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$installedScript`""
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$principal = New-ScheduledTaskPrincipal -UserId ([Security.Principal.WindowsIdentity]::GetCurrent().Name) -LogonType Interactive -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero) -MultipleInstances IgnoreNew
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
Start-ScheduledTask -TaskName $taskName

[System.Windows.Forms.MessageBox]::Show(
    "Installation complete.`n`nCtrl+Alt+1: Profile A ($($config.ProfileA.Gateway))`nCtrl+Alt+2: Profile B ($($config.ProfileB.Gateway))`nCtrl+Alt+G: show current gateway and DNS",
    'Network hotkeys', 'OK', 'Information'
) | Out-Null
