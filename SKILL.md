---
name: codex-wallpaper-standalone
description: Open an in-app Ctrl+Alt+W picker for Wallpaper Engine Workshop projects in Windows Codex without a separate wallpaper manager.
---

# Codex Wallpaper

Requires the Microsoft Store Codex desktop package and Node.js 22 or later.

1. Save any active work and quit ChatGPT from its menu.
2. Run [scripts/start.cmd](scripts/start.cmd). Leave the launcher open. For a custom Steam library, run it with the arguments `-SteamLibraryPath "E:\Steam"`. Add `-List` to inspect the catalog without launching Codex.
3. Press Ctrl+Alt+W inside Codex, then choose a card. The picker applies supported original media or extracted high-resolution stills. Scene thumbnails without a usable still are preview-only. Select Restore default to remove the wallpaper for the current window.
4. Quit Codex and open it normally to end the session. The launcher connects through an unauthenticated local debugging port that remains available to local processes until Codex exits.

The picker saves the selected wallpaper and opacity locally. The wallpaper is restored when Codex starts through the launcher. Restore default clears the saved selection. If the launcher reports that the Store package cannot start with the debugger enabled, report that compatibility error.


