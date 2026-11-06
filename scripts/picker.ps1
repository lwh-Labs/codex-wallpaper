param(
    [string]$SteamLibraryPath,
    [switch]$List
)

$ErrorActionPreference = 'Stop'
$stateRoot = Join-Path $env:LOCALAPPDATA 'CodexDreamSkin'
$runtimeRoot = Join-Path $stateRoot 'manager-runtime'
$command = Get-ChildItem -LiteralPath $runtimeRoot -Directory -ErrorAction SilentlyContinue |
    Where-Object Name -Match '^\d+\.\d+\.\d+$' |
    Sort-Object { [version]$_.Name } -Descending |
    ForEach-Object { Join-Path $_.FullName 'payload\scripts\manager-command.ps1' } |
    Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
    Select-Object -First 1
if (!$command) { throw 'Install and open Codex Dynamic Skin once to initialize its Windows runtime.' }

$nodeDir = Join-Path (Split-Path (Split-Path (Split-Path $command))) 'node'
$env:PATH = "$nodeDir;$env:PATH"

function Get-Wallpapers {
    $arguments = @{ Action = 'ListWallpaperEngine'; StateRoot = $stateRoot }
    if ($SteamLibraryPath) { $arguments.SteamLibraryPath = $SteamLibraryPath }
    $catalog = & $command @arguments | ConvertFrom-Json
    return $catalog.items
}

if ($List) {
    Get-Wallpapers | ConvertTo-Json -Depth 5
    return
}

Add-Type -AssemblyName System.Windows.Forms,System.Drawing
Add-Type -ReferencedAssemblies System.Windows.Forms -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public sealed class WallpaperPickerForm : Form
{
    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool RegisterHotKey(IntPtr window, int id, uint modifiers, uint key);
    [DllImport("user32.dll")]
    private static extern bool UnregisterHotKey(IntPtr window, int id);

    public event EventHandler PickerRequested;

    public bool RegisterPickerKey()
    {
        return RegisterHotKey(Handle, 1, 0x4003, 0x57);
    }

    protected override void WndProc(ref Message message)
    {
        if (message.Msg == 0x0312 && message.WParam.ToInt32() == 1)
            PickerRequested?.Invoke(this, EventArgs.Empty);
        base.WndProc(ref message);
    }

    protected override void OnHandleDestroyed(EventArgs e)
    {
        if (IsHandleCreated) UnregisterHotKey(Handle, 1);
        base.OnHandleDestroyed(e);
    }
}
"@

$form = New-Object WallpaperPickerForm
$form.Text = 'Codex Wallpaper | Ctrl+Alt+W'
$form.Width = 900
$form.Height = 650
$form.StartPosition = 'CenterScreen'
$form.KeyPreview = $true
$form.Add_FormClosed({ [Windows.Forms.Application]::ExitThread() })
$form.Add_KeyDown({ if ($_.KeyCode -eq 'Escape') { $form.Hide() } })

$grid = New-Object System.Windows.Forms.FlowLayoutPanel
$grid.Dock = 'Fill'
$grid.AutoScroll = $true
$form.Controls.Add($grid)

function Update-Picker {
    $items = @(Get-Wallpapers)
    $grid.SuspendLayout()
    try {
        foreach ($old in @($grid.Controls)) {
            if ($old -is [System.Windows.Forms.Button] -and $old.Image) { $old.Image.Dispose() }
            $grid.Controls.Remove($old)
            $old.Dispose()
        }
        if (!$items.Count) {
            $label = New-Object System.Windows.Forms.Label
            $label.AutoSize = $true
            $label.Text = 'No supported Workshop wallpapers found. Check the Steam library path.'
            $grid.Controls.Add($label)
        }
        foreach ($item in $items) {
            $card = New-Object System.Windows.Forms.Button
            $card.Width = 190
            $card.Height = 145
            $card.TextImageRelation = 'ImageAboveText'
            $card.Text = $item.name
            $previewPath = $null
            foreach ($file in 'preview.jpg','preview.jpeg','preview.png','preview.webp','preview.gif') {
                $preview = Join-Path $item.projectDirectory $file
                if (!(Test-Path -LiteralPath $preview -PathType Leaf)) { continue }
                try {
                    $image = [Drawing.Image]::FromFile($preview)
                    try { $card.Image = $image.GetThumbnailImage(160,90,$null,[IntPtr]::Zero) }
                    finally { $image.Dispose() }
                    $previewPath = $preview
                    break
                } catch { continue }
            }
            if ([IO.Path]::GetFileName($item.mediaPath) -ieq 'scene.pkg') {
                $card.Text += ' [Static preview]'
                $card.Enabled = [bool]$previewPath
            }
            $card.Tag = @{ Item = $item; Preview = $previewPath }
            $card.Add_Click({
                param($sender, $eventArgs)
                $grid.Enabled = $false
                try {
                    $stateFile = Join-Path $stateRoot 'state.json'
                    if (!(Test-Path -LiteralPath $stateFile)) {
                        throw 'Start the wallpaper engine from Codex Dynamic Skin first.'
                    }
                    $session = Get-Content -LiteralPath $stateFile -Raw |
                        ConvertFrom-Json
                    if (!$session.injectorPid -or
                        ((Get-Process -Id $session.injectorPid -ErrorAction SilentlyContinue).ProcessName -ne 'node')) {
                        throw 'Start the wallpaper engine from Codex Dynamic Skin first.'
                    }
                    if (Test-Path -LiteralPath (Join-Path $stateRoot 'paused')) {
                        throw 'Resume the wallpaper engine from Codex Dynamic Skin first.'
                    }
                    $media = $sender.Tag.Item.mediaPath
                    if ([IO.Path]::GetFileName($media) -ieq 'scene.pkg') {
                        $tempImage = Join-Path ([IO.Path]::GetTempPath()) ("codex-wallpaper-{0}.png" -f [guid]::NewGuid())
                        try {
                            $preview = [Drawing.Image]::FromFile($sender.Tag.Preview)
                            try { $preview.Save($tempImage, [Drawing.Imaging.ImageFormat]::Png) }
                            finally { $preview.Dispose() }
                            & $command -Action SetWallpaper -Path $tempImage -StateRoot $stateRoot | Out-Null
                        } finally {
                            if (Test-Path -LiteralPath $tempImage) { Remove-Item -LiteralPath $tempImage }
                        }
                    } else {
                        & $command -Action UseWallpaperEngine -Path $media -StateRoot $stateRoot | Out-Null
                    }
                    $form.Hide()
                } catch {
                    [void][Windows.Forms.MessageBox]::Show($form, $_.Exception.Message, 'Codex Wallpaper')
                } finally { $grid.Enabled = $true }
            })
            $grid.Controls.Add($card)
        }
    } finally { $grid.ResumeLayout() }
}

$form.add_PickerRequested({
    if ($form.Visible) { $form.Hide(); return }
    try {
        Update-Picker
        $form.Show()
        $form.Activate()
    } catch { [void][Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Codex Wallpaper') }
})
if (!$form.RegisterPickerKey()) {
    $form.Dispose()
    throw 'Could not register Ctrl+Alt+W. Close the app already using that global shortcut and retry.'
}
try { [Windows.Forms.Application]::Run() }
finally { $form.Dispose() }


