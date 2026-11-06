---
name: codex-wallpaper
description: Open a Ctrl+Alt+W thumbnail picker for locally downloaded Wallpaper Engine Workshop projects and switch the wallpaper in Windows Codex through Codex Dynamic Skin.
---

# Codex Wallpaper

This skill uses Wallpaper Engine's downloaded Steam Workshop library (app 431960). The picker is a separate Windows window that can be opened while Codex is in focus.

1. Install [Codex Dynamic Skin](https://github.com/CCDawn/Codex-Dynamic-Skin/releases), open its manager once, and start the wallpaper engine. If the manager requests a restart, let the user complete it.
2. Start [scripts/start-picker.cmd](scripts/start-picker.cmd) and leave it running. Use Windows PowerShell 5.1 for the picker. Steam libraries are discovered by the engine. Pass `-SteamLibraryPath "E:\Steam"` if automatic discovery misses a library. Pass `-List` to inspect the detected compatible projects without opening a window.
3. Press Ctrl+Alt+W, then click a thumbnail. Escape hides the picker. Closing the picker with the window close button exits it. If the shortcut is occupied, close the competing app and restart the picker.

Video and image projects supported by the engine can be applied from the picker. Scene packages use their Workshop thumbnail as a static wallpaper when a readable preview is available. Use the Dynamic Skin manager with its scene renderer to apply the live scene. Other unsupported project types may be filtered out by the engine.

Verify the result visually in Codex. To restore the default appearance, use the manager's full restore control.

