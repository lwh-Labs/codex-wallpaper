param([string]$SteamLibraryPath)
$ErrorActionPreference = 'Stop'
$programs = [Environment]::GetFolderPath('Programs')
$shortcutName = 'ChatGPT 壁纸版.lnk'
$path = Join-Path $programs $shortcutName
$launcher = Join-Path $PSScriptRoot 'start-hidden.ps1'
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($path)
$shortcut.TargetPath = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$shortcut.Arguments = '-NoProfile -STA -WindowStyle Hidden -ExecutionPolicy RemoteSigned -File "' + $launcher + '"'
if ($SteamLibraryPath) {
    $library = (Get-Item -LiteralPath $SteamLibraryPath).FullName.TrimEnd('\')
    $shortcut.Arguments += ' -SteamLibraryPath "' + $library + '"'
}
$shortcut.WorkingDirectory = $PSScriptRoot
$shortcut.Description = 'Start ChatGPT with the Wallpaper Engine picker'
$shortcut.Save()
Get-Item -LiteralPath $path
