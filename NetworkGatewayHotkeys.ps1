# Ctrl+Alt+1 -> Profile A; Ctrl+Alt+2 -> Profile B
# Ctrl+Alt+3 -> DHCP for IPv4 address, gateway, and DNS.
# Ctrl+Alt+G -> show current gateway and DNS.

$ErrorActionPreference = 'Stop'
$configPath = Join-Path $PSScriptRoot 'Config.json'
if (-not (Test-Path -LiteralPath $configPath)) { throw "Configuration not found: $configPath" }
$config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$interfaceAlias = [string]$config.InterfaceAlias

Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class NativeHotKey {
    [DllImport("user32.dll", SetLastError=true)]
    public static extern bool RegisterHotKey(IntPtr hWnd, int id, uint modifiers, uint key);
    [DllImport("user32.dll", SetLastError=true)]
    public static extern bool UnregisterHotKey(IntPtr hWnd, int id);
    [DllImport("user32.dll")]
    public static extern int GetMessage(out MSG message, IntPtr hWnd, uint min, uint max);
    public const uint MOD_ALT = 0x0001;
    public const uint MOD_CONTROL = 0x0002;
    public const uint WM_HOTKEY = 0x0312;
    [StructLayout(LayoutKind.Sequential)]
    public struct MSG {
        public IntPtr hwnd;
        public uint message;
        public UIntPtr wParam;
        public IntPtr lParam;
        public uint time;
        public int pt_x;
        public int pt_y;
    }
}
'@

Add-Type -AssemblyName System.Windows.Forms

function Show-Status([string]$title, [string]$text, [System.Windows.Forms.ToolTipIcon]$icon = 'Info') {
    $notify = [System.Windows.Forms.NotifyIcon]::new()
    try {
        $notify.Icon = [System.Drawing.SystemIcons]::Information
        $notify.Visible = $true
        $notify.ShowBalloonTip(4000, $title, $text, $icon)
        Start-Sleep -Milliseconds 4200
    } finally { $notify.Dispose() }
}

function Get-TargetAdapter {
    return Get-NetAdapter -Name $interfaceAlias -ErrorAction Stop
}

function Set-JapanRegionalSettings {
    Set-TimeZone -Id 'Tokyo Standard Time'
    Set-Culture -CultureInfo 'ja-JP'
    Set-WinSystemLocale -SystemLocale 'ja-JP'
    Set-WinHomeLocation -GeoId 122
}

function Set-NetworkProfile($profile, [string]$profileName) {
    try {
        $adapter = Get-TargetAdapter
        $interfaceIndex = $adapter.ifIndex
        $ip = Get-NetIPAddress -InterfaceIndex $interfaceIndex -AddressFamily IPv4 |
            Where-Object AddressState -ne Duplicate | Select-Object -First 1
        if (-not $ip) { throw "$interfaceAlias has no IPv4 address." }

        Get-NetRoute -InterfaceIndex $interfaceIndex -DestinationPrefix '0.0.0.0/0' -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            Remove-NetRoute -Confirm:$false -ErrorAction Stop
        New-NetRoute -InterfaceIndex $interfaceIndex -DestinationPrefix '0.0.0.0/0' -NextHop $profile.Gateway -RouteMetric 0 | Out-Null
        Set-DnsClientServerAddress -InterfaceIndex $interfaceIndex -ServerAddresses @($profile.Dns)
        Clear-DnsClientCache

        $regionStatus = ''
        if ([string]$profile.Gateway -eq '192.168.3.11') {
            try {
                Set-JapanRegionalSettings
                $regionStatus = "`nTime zone and region: Japan (Tokyo)`nSome regional changes may require sign-out."
            } catch {
                $regionStatus = "`nWarning: Could not apply Japan regional settings: $($_.Exception.Message)"
            }
        }
        Show-Status "Switched to Profile $profileName" "Adapter: $interfaceAlias`nGateway: $($profile.Gateway)`nDNS: $(@($profile.Dns) -join ', ')$regionStatus"
    } catch { Show-Status 'Network switch failed' $_.Exception.Message 'Error' }
}

function Set-AutomaticNetworkConfiguration {
    try {
        [void](Get-TargetAdapter)
        & netsh.exe interface ipv4 set address name="$interfaceAlias" source=dhcp | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "Could not enable automatic IPv4 addressing (netsh exit code $LASTEXITCODE)." }
        & netsh.exe interface ipv4 set dnsservers name="$interfaceAlias" source=dhcp | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "Could not enable automatic DNS (netsh exit code $LASTEXITCODE)." }
        Clear-DnsClientCache
        Show-Status 'Automatic network configuration enabled' "Adapter: $interfaceAlias`nIPv4 address: Automatic (DHCP)`nGateway: Automatic (DHCP)`nDNS: Automatic (DHCP)"
    } catch { Show-Status 'Could not enable automatic configuration' $_.Exception.Message 'Error' }
}

function Show-NetworkStatus {
    try {
        $adapter = Get-TargetAdapter
        $interfaceIndex = $adapter.ifIndex
        $gateway = (Get-NetRoute -InterfaceIndex $interfaceIndex -DestinationPrefix '0.0.0.0/0' -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            Sort-Object RouteMetric | Select-Object -First 1).NextHop
        $dns = (Get-DnsClientServerAddress -InterfaceIndex $interfaceIndex -AddressFamily IPv4).ServerAddresses -join ', '
        if (-not $gateway) { $gateway = 'Not configured' }
        if (-not $dns) { $dns = 'Not configured' }
        Show-Status 'Current network configuration' "Adapter: $interfaceAlias`nGateway: $gateway`nDNS: $dns"
    } catch { Show-Status 'Could not read network configuration' $_.Exception.Message 'Error' }
}

$modifiers = [NativeHotKey]::MOD_CONTROL -bor [NativeHotKey]::MOD_ALT
$registered = @()
try {
    foreach ($hotkey in @(
        @{ Id = 1; Key = [uint32][char]'1' },
        @{ Id = 2; Key = [uint32][char]'2' },
        @{ Id = 3; Key = [uint32][char]'3' },
        @{ Id = 4; Key = [uint32][char]'G' }
    )) {
        if (-not [NativeHotKey]::RegisterHotKey([IntPtr]::Zero, $hotkey.Id, $modifiers, $hotkey.Key)) {
            throw "Could not register hotkey ID $($hotkey.Id); it may be in use by another program."
        }
        $registered += $hotkey.Id
    }

    Show-Status 'Network hotkeys started' "Ctrl+Alt+1 -> Profile A ($($config.ProfileA.Gateway))`nCtrl+Alt+2 -> Profile B ($($config.ProfileB.Gateway))`nCtrl+Alt+3 -> Automatic IP and DNS`nCtrl+Alt+G -> Show current configuration"
    $message = [NativeHotKey+MSG]::new()
    while ([NativeHotKey]::GetMessage([ref]$message, [IntPtr]::Zero, 0, 0) -gt 0) {
        if ($message.message -eq [NativeHotKey]::WM_HOTKEY) {
            switch ($message.wParam.ToUInt32()) {
                1 { Set-NetworkProfile $config.ProfileA 'A' }
                2 { Set-NetworkProfile $config.ProfileB 'B' }
                3 { Set-AutomaticNetworkConfiguration }
                4 { Show-NetworkStatus }
            }
        }
    }
} finally {
    foreach ($id in $registered) { [void][NativeHotKey]::UnregisterHotKey([IntPtr]::Zero, $id) }
}
