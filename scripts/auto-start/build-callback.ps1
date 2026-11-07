param([Parameter(Mandatory)][string]$UpstreamSource, [Parameter(Mandatory)][string]$Destination)
$ErrorActionPreference = 'Stop'
$source = Get-Content -LiteralPath (Join-Path $UpstreamSource 'PackageStartupDebugger.cs') -Raw
$arguments = Join-Path $UpstreamSource 'StartupArguments.cs'
foreach ($edit in (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'callback-edits.json') -Raw | ConvertFrom-Json)) {
    if (!$source.Contains($edit.before)) { throw 'Unsupported upstream callback source layout.' }
    $source = $source.Replace($edit.before, $edit.after)
}
$compiler = Join-Path $env:windir 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$tempSource = Join-Path ([IO.Path]::GetTempPath()) ('wallpaper-callback-' + [guid]::NewGuid() + '.cs')
try {
    Set-Content -LiteralPath $tempSource -Value $source -Encoding utf8
    & $compiler /nologo /target:winexe /platform:x64 /r:System.Web.Extensions.dll "/out:$Destination" $tempSource $arguments
    if ($LASTEXITCODE -ne 0) { throw 'Callback build failed.' }
} finally {
    if (Test-Path -LiteralPath $tempSource) { Remove-Item -LiteralPath $tempSource }
}
