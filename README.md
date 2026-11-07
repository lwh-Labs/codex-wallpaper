# Codex Wallpaper

简体中文 · [English](README.en.md)

把 Steam Wallpaper Engine 已下载的创意工坊壁纸用作 Windows Codex 窗口背景。通过专用启动器打开 ChatGPT 后，在窗口里按 **Ctrl + Alt + W** 呼出缩略图面板，点一张即可切换。

## 功能

- 扫描 Steam 创意工坊中 Wallpaper Engine 的本地项目（应用 ID 为 `431960`）。
- 直接读取本地图片和 MP4、WebM 原片。视频通过浏览器文件句柄播放，无需整段编码。已提取高清图层的场景可以作为静态壁纸，其余场景只在面板中显示缩略图。
- 在面板中用 **0–100%** 滑块实时调整壁纸不透明度。成功应用的壁纸和不透明度会保存在本机。
- 聊天区显示壁纸，侧栏和输入框使用浅色毛玻璃，文字加阴影以改善对比度。
- 独立运行，无需安装 Codex Dynamic Skin。

## 安装与启动

需要 Windows、Microsoft Store 版 ChatGPT 桌面端（含 Codex）、Node.js 22 或更新版本，以及已下载到本机的 Wallpaper Engine 创意工坊壁纸。

1. 从 [Releases](https://github.com/lwh-Labs/codex-wallpaper/releases/latest) 下载独立版 ZIP 并解压。
2. 保存工作，从 ChatGPT 菜单完全退出应用。
3. 双击解压目录里的 `scripts\start.cmd`，保持启动器窗口打开。
4. 看到 `Connected to Codex renderer` 后，切回 ChatGPT 窗口，按 **Ctrl + Alt + W**。面板先显示壁纸名称，缩略图随后加载。

ZIP 可以解压到任意目录。若希望 Codex 也发现配套技能，可把包含 `SKILL.md` 的整个目录放进 `%USERPROFILE%\.codex\skills\`。

## 从开始菜单启动

在解压目录运行一次 `scripts\install-shortcut.cmd`，以后从开始菜单打开 **ChatGPT 壁纸版** 即可。连接在后台运行，日志位于 `%LOCALAPPDATA%\CodexWallpaperStandalone\launcher.log`。

## 恢复壁纸与退出

下次通过同一个启动器打开 ChatGPT 时，脚本会自动应用上次成功选择且仍存在的壁纸。在面板里选择 **Restore default** 可清除当前壁纸及保存的选择。完全退出 ChatGPT，再从原来的应用图标打开，即可结束壁纸会话并恢复原生外观。

启动器通过仅绑定到回环地址的调试端口向 Codex 窗口加载面板。该端口在这次 ChatGPT 会话期间可被本机进程访问。

## 常见问题

| 现象 | 处理 |
| --- | --- |
| 启动器要求退出 ChatGPT | 从 ChatGPT 菜单退出。关闭窗口后若进程仍在运行，可从系统托盘退出。 |
| 找不到 Steam 壁纸库 | 传入 Steam 库根目录，例如 `E:\Steam`，也就是包含 `steamapps` 的目录。 |
| 快捷键没有反应 | 确认启动器显示已连接，把焦点切回 ChatGPT，再按快捷键。 |
| 连接超时或反复断开 | 保留终端报错和桌面端版本。不同版本的 Store 应用可能有不同的调试接口行为。 |
| 场景卡片只能预览 | 该项目需要场景渲染，或者需要先提取高清图层。缩略图只用于浏览。 |

在解压目录打开 PowerShell，用以下命令检查库中能识别的项目。该命令不会启动 ChatGPT。

```powershell
.\scripts\start.cmd -List -SteamLibraryPath "E:\Steam"
```

交互参考了 [reasonix-wallpaper](https://github.com/lwh-Labs/reasonix-wallpaper)。需要 Codex Dynamic Skin 的旧实现保留在 [v0.2.0](https://github.com/lwh-Labs/codex-wallpaper/releases/tag/v0.2.0)。

`scene.pkg` 的高清静态图缓存位置为 `%LOCALAPPDATA%\CWAuto\scene-stills\<创意工坊 ID>.jpg`。发布包不包含个人壁纸缓存。

## 实验功能：原图标自动加载

此功能面向 Windows x64 的 Microsoft Store 版 ChatGPT。Windows 包调试会在应用启动时运行本地回调，回调为新进程加入本机调试端口，再启动后台壁纸服务。启用期间，Windows 对该应用的挂起、恢复和终止行为可能变化。

1. 从 [codex-glass-themes 源码](https://github.com/mabyes1/codex-glass-themes/tree/35b5f0593852abcb52625fdab8367c8a4bafb601/packaging/payload) 单独取得 `PackageDebugSession.cs`、`PackageStartupDebugger.cs` 和 `StartupArguments.cs`，放在同一目录。公开 ZIP 提供集成脚本，回调在本机编译。
2. 完全退出 ChatGPT。在本项目解压目录打开 PowerShell，运行以下命令。把示例路径换成你的源码目录和 Steam 库根目录。

```powershell
.\scripts\auto-start\chatgpt-wallpaper-auto.cmd -UpstreamSource "C:\path\to\payload" -SteamLibraryPath "E:\Steam"
```

3. 成功后，从原来的 ChatGPT Store 图标启动，按 **Ctrl + Alt + W**。Store 更换应用包版本后，重新执行一次启用命令。
4. 要关闭，运行 `scripts\auto-start\chatgpt-wallpaper-disable.cmd`，再完全退出并重开 ChatGPT。启动和连接日志在 `%LOCALAPPDATA%\CWAuto`。

