param([int]$CodexPid, [string]$Image)
$ErrorActionPreference = 'Stop'
$log = Join-Path $PSScriptRoot 'wallpaper-worker.log'
Start-Transcript -Path $log -Force | Out-Null
try {
    $wallpaper = Join-Path $PSScriptRoot 'wallpaper.mjs'
    $config = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'activation.json') -Raw | ConvertFrom-Json
    $libraries = @(Get-PSDrive -PSProvider FileSystem | ForEach-Object { Join-Path $_.Root 'Steam' })
    $libraries += $config.steamLibraryPath
    $libraries += (Get-ItemProperty 'HKCU:\Software\Valve\Steam' -ErrorAction SilentlyContinue).SteamPath
    $workshop = @($libraries | Where-Object { $_ } |
        ForEach-Object { Join-Path $_ 'steamapps\workshop\content\431960' } |
        Where-Object { Test-Path -LiteralPath $_ -PathType Container } | Select-Object -Unique)
    if (!$workshop.Count) { throw 'No Wallpaper Engine Workshop library found. Specify -SteamLibraryPath during setup.' }
    $node = Get-Command node.exe -CommandType Application | Select-Object -First 1
    for ($attempt = 1; $attempt -le 5; $attempt++) {
        $deadline = [DateTime]::UtcNow.AddSeconds(60)
        $port = $null
        do {
            $owner = Get-Process -Id $CodexPid -ErrorAction SilentlyContinue
            if (!$owner) { return }
            if ($owner.Path -ine $Image) { throw 'The verified ChatGPT process changed.' }
            foreach ($listener in @(Get-NetTCPConnection -OwningProcess $CodexPid -State Listen -ErrorAction SilentlyContinue)) {
                if ($listener.LocalAddress -ne '127.0.0.1') { continue }
                $candidate = $listener.LocalPort
                try {
                    $info = Invoke-RestMethod "http://127.0.0.1:$candidate/json/version" -TimeoutSec 1 -MaximumRedirection 0
                    $pages = Invoke-RestMethod "http://127.0.0.1:$candidate/json/list" -TimeoutSec 1 -MaximumRedirection 0
                } catch { continue }
                if ($info.webSocketDebuggerUrl -like "ws://127.0.0.1:$candidate/devtools/browser/*" -and
                    ($pages | Where-Object { $_.type -eq 'page' -and $_.url -like 'app://*' })) {
                    $port = $candidate
                    break
                }
            }
            if ($port) { break }
            Start-Sleep -Milliseconds 500
        } while ([DateTime]::UtcNow -lt $deadline)
        if (!$port) { throw 'The ChatGPT debugging session could not be reached.' }

        & $node.Source $wallpaper $port @workshop
        $result = $LASTEXITCODE
        if ($result -eq 0 -or !(Get-Process -Id $CodexPid -ErrorAction SilentlyContinue)) { return }
        if ($attempt -eq 5) { throw "Wallpaper connection failed after $attempt attempts (exit $result)." }
        Write-Host "Wallpaper connection exited ($result). Reconnecting ($attempt/4)."
        Start-Sleep -Seconds 2
    }
} finally { Stop-Transcript | Out-Null }


