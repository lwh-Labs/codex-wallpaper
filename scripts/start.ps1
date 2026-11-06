param([string]$SteamLibraryPath, [switch]$List)
$ErrorActionPreference = 'Stop'
$node = Get-Command node.exe -CommandType Application | Select-Object -First 1
if ([int]((& $node.Source --version).TrimStart('v').Split('.')[0]) -lt 22) {
    throw 'Node.js 22 or later is required.'
}
$driveLibraries = Get-PSDrive -PSProvider FileSystem | ForEach-Object { Join-Path $_.Root 'Steam' }
$libraries = @($SteamLibraryPath, (Get-ItemProperty 'HKCU:\Software\Valve\Steam' -ErrorAction SilentlyContinue).SteamPath,
    "${env:ProgramFiles(x86)}\Steam", "$env:ProgramFiles\Steam") + @($driveLibraries)
$libraries = $libraries | Where-Object { $_ } | Select-Object -Unique
$extraLibraries = foreach ($library in $libraries) {
    $vdf = Join-Path $library 'steamapps\libraryfolders.vdf'
    if (Test-Path -LiteralPath $vdf -PathType Leaf) {
        foreach ($entry in [regex]::Matches((Get-Content -LiteralPath $vdf -Raw), '"path"\s+"([^"]+)"')) {
            $entry.Groups[1].Value.Replace('\\','\')
        }
    }
}
$roots = @(@($libraries) + @($extraLibraries) | Where-Object { $_ } |
    ForEach-Object { Join-Path $_ 'steamapps\workshop\content\431960' } |
    Where-Object { Test-Path -LiteralPath $_ -PathType Container } | Select-Object -Unique)
if (!$roots.Count) { throw 'No Workshop library found. Pass -SteamLibraryPath with the Steam library root.' }
$script = Join-Path $PSScriptRoot 'wallpaper.mjs'
if ($List) {
    & $node.Source $script --list @roots
    exit $LASTEXITCODE
}
$package = Get-AppxPackage -Name OpenAI.Codex | Select-Object -First 1
if (!$package -or $package.SignatureKind -ne 'Store') { throw 'The Microsoft Store Codex package is required.' }
$app = Join-Path $package.InstallLocation 'app\ChatGPT.exe'
if (!(Test-Path -LiteralPath $app -PathType Leaf)) { throw 'The installed Codex executable was not found.' }
if (Get-Process -Name ChatGPT -ErrorAction SilentlyContinue) {
    throw 'Save your work and quit ChatGPT from its menu before running this launcher.'
}
$socket = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, 0)
try { $socket.Start(); $port = $socket.LocalEndpoint.Port }
finally { $socket.Stop() }
Start-Process -FilePath $app -ArgumentList "--remote-debugging-address=127.0.0.1 --remote-debugging-port=$port"
function Wait-CodexRenderer {
    $ready = $false
    for ($attempt = 0; $attempt -lt 40; $attempt++) {
        $listeners = @(Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue)
        if ($listeners.Count) {
            foreach ($listener in $listeners) {
                $owner = Get-Process -Id $listener.OwningProcess -ErrorAction SilentlyContinue
                if ($listener.LocalAddress -ne '127.0.0.1' -or $owner.Path -ine $app) {
                    throw 'Unexpected debugger listener. Quit Codex to close this session.'
                }
            }
            try {
                $targets = Invoke-RestMethod "http://127.0.0.1:$port/json/list" -TimeoutSec 1
                if ($targets | Where-Object { $_.type -eq 'page' -and $_.url -like 'app://*' }) {
                    $ready = $true
                    break
                }
            } catch {}
        }
        Start-Sleep -Milliseconds 500
    }
    if (!$ready) { throw 'Codex did not expose a compatible local renderer. Quit this session and reopen normally.' }
}

for ($connection = 1; $connection -le 5; $connection++) {
    Wait-CodexRenderer
    & $node.Source $script $port @roots
    $result = $LASTEXITCODE
    if ($result -ne 75) { exit $result }
    if ($connection -lt 5) {
        Write-Host "Codex window connection lost. Reconnecting ($connection/4)..."
        Start-Sleep -Seconds 2
    }
}
throw 'The Codex window disconnected repeatedly. See the connection details above.'
