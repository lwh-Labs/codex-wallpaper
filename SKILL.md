---
name: codex-wallpaper
description: Find a recently downloaded wallpaper, then apply, switch, or restore an image or video wallpaper inside the Windows Codex desktop app using an existing Codex Dynamic Skin installation. Use for Codex 换壁纸 and 恢复默认壁纸 requests.
---

# Codex Wallpaper

Use the installed Codex 动态壁纸 (Codex Dynamic Skin / CodexDreamSkin) manager as the wallpaper engine. The documented Windows backend targets the official Microsoft Store Codex package. Consult the [upstream Windows guide](https://github.com/CCDawn/Codex-Dynamic-Skin/blob/main/windows/README.en.md) for release-specific controls and compatibility. If the manager is missing or the installed client is unsupported, identify the missing prerequisite and provide the upstream guide. Do not silently install software.

## Find the wallpaper

Use an explicit file or a known output path from the current chat first. If a download was just performed, use its reported destination or inspect the browser's download entry if available. If the user provides a direct image or video URL, download it with the available authorized download tool, then use the actual returned path. Check that the result is media rather than an HTML page or an incomplete download.

When the user says “刚下载的壁纸” or gives a filename without a path, locate it automatically:

1. Check the actual Windows Downloads known folder (including redirected folders), the browser download location if known, and any explicit destination or output folder from this chat. To resolve Downloads in PowerShell, use `(New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path`. If that fails, check the default `%USERPROFILE%\Downloads` if it exists.
2. List files in those folders and any relevant subfolder indicated by the user or download context. Match a provided filename first. For “刚下载的”, prefer the browser's most recent completed matching entry. If download history is unavailable, compare recent creation and modification times and filenames. Do not recursively search the entire user profile or pick an old unrelated image merely because it ranks first.
3. Accept only existing, readable PNG, JPEG, WebP, MP4, or WebM files. Wait for a matching in-progress download to finish before using it. If one match is clear, apply it without asking the user to supply a path. If multiple plausible files remain, show a short list with filenames and times so the user can pick. If none is found, report the checked locations and ask for the filename or source link.

## Apply or switch

1. Use the exact resolved local file path in the manager's file picker. If the user asks to switch to a saved wallpaper, identify it by name in the library and skip download discovery.
2. Use the available Windows computer-use surface to open the installed manager and inspect the controls. Import the supplied file with 添加壁纸, select the imported item, then choose 应用到 Codex. For a saved wallpaper, select it directly. If the manager requests a restart, surface the prompt before closing an active Codex session and let the user confirm it.
3. Verify the wallpaper in the actual Codex window. Check that the sidebar and composer are visible. If only the manager preview is accessible, report that live application still needs verification.

## Restore

Use 恢复官方外观 in the installed manager or its matching Start menu shortcut. Use the full restore flow and complete any user-confirmed restart. Verify the standard appearance in Codex. Preserve the saved wallpaper library.

The backend uses unauthenticated loopback CDP while the skinned client is running. Full restore or quitting all Codex processes and relaunching normally ends that session. Pause alone leaves the debug endpoint open. Use the installed manager controls and avoid direct changes to the app package or global config.

If desktop control is unavailable, provide the exact manual steps for the requested operation and distinguish them from actions already completed.

