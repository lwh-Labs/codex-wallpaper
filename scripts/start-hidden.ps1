param([string]$SteamLibraryPath)
$ErrorActionPreference = 'Stop'
$folder = Join-Path $env:LOCALAPPDATA 'CodexWallpaperStandalone'
$log = Join-Path $folder 'launcher.log'
try {
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
    Start-Transcript -Path $log -Force | Out-Null
    try {
        $arguments = @{}
        if ($SteamLibraryPath) { $arguments.SteamLibraryPath = $SteamLibraryPath }
        & (Join-Path $PSScriptRoot 'start.ps1') @arguments
        if ($LASTEXITCODE -ne 0) { throw "Wallpaper launcher exited with code $LASTEXITCODE." }
    } finally { Stop-Transcript | Out-Null }
} catch {
    Add-Type -AssemblyName System.Windows.Forms
    [void][Windows.Forms.MessageBox]::Show(
        ($_.Exception.Message + [Environment]::NewLine + $log), 'ChatGPT Wallpaper')
    exit 1
}
