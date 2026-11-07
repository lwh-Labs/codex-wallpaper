# Codex Wallpaper

[简体中文](README.md) · English

Use downloaded Steam Wallpaper Engine Workshop items as backgrounds in Codex for Windows. Open ChatGPT through the launcher, press **Ctrl + Alt + W** inside the app, and choose a wallpaper from the thumbnail grid.

## Features

- Discover locally downloaded Wallpaper Engine Workshop projects (Steam app ID `431960`).
- Play local MP4 and WebM originals through a browser file handle. For scene projects, an extracted high-resolution still can be applied when available. Workshop thumbnails are used for browsing.
- Adjust wallpaper opacity live from **0–100%**. The picker remembers the last successfully applied wallpaper and opacity on this machine.
- Show the wallpaper behind the chat with lightly frosted sidebar and composer surfaces and text shadows for contrast.
- Run independently of Codex Dynamic Skin.

## Setup

You need Windows, the Microsoft Store ChatGPT desktop app with Codex, Node.js 22 or later, and at least one locally downloaded Wallpaper Engine Workshop item.

1. Download and extract the standalone ZIP from [Releases](https://github.com/lwh-Labs/codex-wallpaper/releases/latest).
2. Save your work and quit ChatGPT from its menu.
3. Double-click `scripts\start.cmd` in the extracted folder and leave the launcher open.
4. When the terminal says `Connected to Codex renderer`, focus ChatGPT and press **Ctrl + Alt + W**. The picker shows titles first and loads thumbnails afterward.

You can extract the ZIP anywhere. For skill discovery in Codex, place the entire folder containing `SKILL.md` under `%USERPROFILE%\.codex\skills\`.

## Launch from the Start menu

Run `scripts\install-shortcut.cmd` once, then open **ChatGPT 壁纸版** from the Start menu. The connection runs in the background and writes its log to `%LOCALAPPDATA%\CodexWallpaperStandalone\launcher.log`.

## Restore and exit

The next time you open ChatGPT through the launcher, it restores the last successful selection if the wallpaper is still available. Choose **Restore default** to clear the current and saved wallpaper. To end the wallpaper session, quit ChatGPT completely and reopen it from its regular app icon.

The launcher uses a loopback-only debugging port to load the picker into the Codex window. Local processes can access that port while this ChatGPT session is running.

## Troubleshooting

| Symptom | What to check |
| --- | --- |
| The launcher asks you to quit ChatGPT | Quit from the app menu. If closing the window leaves it running, use the system tray to quit. |
| The Steam library is missing | Pass the Steam library root that contains `steamapps`, such as `E:\Steam`. |
| The shortcut does nothing | Check that the launcher reports a connection and that the ChatGPT window has focus. |
| The connection times out or repeatedly disconnects | Keep the terminal error and app version. Debugger behavior can vary across Store builds. |
| A scene card is preview-only | This project needs a scene renderer or an extracted high-resolution still. The thumbnail is for browsing. |

Run this from PowerShell in the extracted folder to check which Workshop items the picker can discover. It does not launch ChatGPT.

```powershell
.\scripts\start.cmd -List -SteamLibraryPath "E:\Steam"
```

The picker interaction is inspired by [reasonix-wallpaper](https://github.com/lwh-Labs/reasonix-wallpaper). The earlier implementation that requires Codex Dynamic Skin is available in [v0.2.0](https://github.com/lwh-Labs/codex-wallpaper/releases/tag/v0.2.0).

Extracted scene stills can be placed at `%LOCALAPPDATA%\CWAuto\scene-stills\<Workshop ID>.jpg`. The release ZIP contains no personal wallpaper cache.

## Experimental: launch from the original ChatGPT icon

This option targets the Windows x64 Microsoft Store ChatGPT package. A Windows package-debug callback adds a loopback debugging port to the fresh process and starts the wallpaper worker. Package debugging can change how Windows suspends, resumes, and terminates the app while enabled.

1. Obtain `PackageDebugSession.cs`, `PackageStartupDebugger.cs`, and `StartupArguments.cs` from the [codex-glass-themes source](https://github.com/mabyes1/codex-glass-themes/tree/35b5f0593852abcb52625fdab8367c8a4bafb601/packaging/payload) and save them together. The release provides the integration scripts and builds the callback locally.
2. Quit ChatGPT completely. From PowerShell in the extracted project folder, run the following with your actual source directory and Steam library root.

```powershell
.\scripts\auto-start\chatgpt-wallpaper-auto.cmd -UpstreamSource "C:\path\to\payload" -SteamLibraryPath "E:\Steam"
```

3. Open ChatGPT from its original Store icon and press **Ctrl + Alt + W**. Run the enable command again when a Store update replaces the package.
4. To turn this off, run `scripts\auto-start\chatgpt-wallpaper-disable.cmd`, then quit and reopen ChatGPT. Startup and connection logs are under `%LOCALAPPDATA%\CWAuto`.

