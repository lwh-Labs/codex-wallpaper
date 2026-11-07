param([switch]$Disable, [string]$UpstreamSource, [string]$SteamLibraryPath)
$ErrorActionPreference = 'Stop'

$source = $PSScriptRoot
$runtime = Join-Path $env:LOCALAPPDATA 'CWAuto'
$config = Join-Path $runtime 'activation.json'
$callback = Join-Path $runtime 'WallpaperStartupDebugger.exe'
$worker = Join-Path $runtime 'Attach-OriginalIconWallpaper.ps1'
$command = '"' + $callback + '" --config "' + $config + '"'
$sessionSource = Join-Path $runtime 'PackageDebugSession.cs'
if (!$Disable) {
    if (!$UpstreamSource) { throw 'Supply -UpstreamSource with the upstream packaging/payload directory. See the README.' }
    $UpstreamSource = (Resolve-Path -LiteralPath $UpstreamSource).Path
    $sessionSource = Join-Path $UpstreamSource 'PackageDebugSession.cs'
}
if (!(Test-Path -LiteralPath $sessionSource -PathType Leaf)) { throw 'PackageDebugSession.cs is missing.' }
Add-Type -Path $sessionSource
$sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
function Get-DebugKeys([string]$Name) {
    "Registry::HKEY_USERS\$sid\Software\Classes\ActivatableClasses\Package\$Name\DebugInformation"
    "Registry::HKEY_USERS\$sid\Software\Microsoft\Windows\CurrentVersion\PackagedAppXDebug\$Name"
}
function Get-OwnedRegistration([string]$Name) {
    $found = $false
    foreach ($key in Get-DebugKeys $Name) {
        if (!(Test-Path -LiteralPath $key)) { continue }
        if ((Get-Item -LiteralPath $key).GetValue('') -cne $command) {
            throw 'Another debugger owns this package registration. It was preserved.'
        }
        $found = $true
    }
    return $found
}
function Disable-OwnedRegistration([string]$Name) {
    if (!(Get-OwnedRegistration $Name)) { return }
    try {
        [PackageDebugSession]::Disable($Name)
    } catch {
        $cause = $_.Exception.GetBaseException()
        if ($cause.HResult -ne -2147023728) { throw }
        if ([CodexPackageCatalog]::Find() | Where-Object PackageFullName -EQ $Name) { throw }
        Write-Host "Store removed the old ChatGPT package. Skipping its inactive callback: $Name"
        return
    }
    foreach ($key in Get-DebugKeys $Name) {
        if (Test-Path -LiteralPath $key) { throw "Debug registration still exists: $key" }
    }
}
$old = if (Test-Path -LiteralPath $config) { Get-Content -LiteralPath $config -Raw | ConvertFrom-Json }
if ($old -and ($old.sid -ne $sid -or $old.package -notmatch '^OpenAI\.Codex_[0-9.]+_x64__2p2nqsd0c76g0$')) {
    throw 'Existing wallpaper configuration has unexpected ownership or package identity.'
}
if ($Disable) {
    if ($old) { Disable-OwnedRegistration $old.package }
    Write-Host 'Automatic wallpaper startup is disabled. Quit and reopen ChatGPT to end the current session.'
    return
}
$packages = @([CodexPackageCatalog]::Find())
if ($packages.Count -ne 1) { throw 'Expected one current-user ChatGPT Store package.' }
$package = $packages[0]
$name = $package.PackageFullName
if ($name -notmatch '^OpenAI\.Codex_[0-9.]+_x64__2p2nqsd0c76g0$') { throw 'Unexpected Store package identity.' }
if ($old -and $old.package -ne $name) { Disable-OwnedRegistration $old.package }
if (Get-OwnedRegistration $name) {
    if (!$old -or $old.package -ne $name -or !(Test-Path $callback) -or !(Test-Path $worker)) {
        throw 'An incomplete wallpaper registration exists. Run Disable before enabling it again.'
    }
    Write-Host 'Automatic wallpaper startup is already enabled.'
    return
}
$official = Join-Path $package.InstallLocation 'app'
$image = Join-Path $official 'ChatGPT.exe'
if (!(Test-Path -LiteralPath $image -PathType Leaf)) { throw 'Official executable unavailable.' }
New-Item -ItemType Directory -Path $runtime -Force | Out-Null
$alias = Join-Path $runtime ('a' + [guid]::NewGuid().ToString('N').Substring(0, 8))
$argumentImage = Join-Path $alias 'ChatGPT.exe'
if ($argumentImage.Length + 26 -gt $image.Length) { throw 'Wallpaper runtime path is too long for the startup argument buffer.' }
New-Item -ItemType Junction -Path $alias -Target $official | Out-Null
& (Join-Path $source 'build-callback.ps1') -UpstreamSource $UpstreamSource -Destination $callback
Copy-Item -LiteralPath $sessionSource -Destination (Join-Path $runtime 'PackageDebugSession.cs') -Force
Copy-Item -LiteralPath (Join-Path $source 'Attach-OriginalIconWallpaper.ps1') -Destination $worker -Force
$media = Split-Path -Parent $PSScriptRoot
foreach ($file in 'wallpaper.mjs') {
    Copy-Item -LiteralPath (Join-Path $media $file) -Destination $runtime -Force
}
$settings = @{
    mode='user-main'; package=$name; sid=$sid; image=$image; imageArgument=$argumentImage
    excludedPids=@(); notBefore=[DateTime]::UtcNow.ToFileTimeUtc(); expires=0
    log=(Join-Path $runtime 'activation.jsonl'); worker=$worker; steamLibraryPath=$SteamLibraryPath
}
[IO.File]::WriteAllText($config, ($settings | ConvertTo-Json), [Text.UTF8Encoding]::new($false))
$session = [PackageDebugSession]::new($name, $command, [IntPtr]::Zero, 0)
try {
    if (!(Get-OwnedRegistration $name)) { throw 'Windows did not retain the wallpaper callback.' }
    $session.ReleaseWithoutDisabling()
} catch {
    $session.Dispose()
    throw
}
Write-Host 'Automatic wallpaper startup is enabled. Quit ChatGPT completely, then open it from its original icon.'



