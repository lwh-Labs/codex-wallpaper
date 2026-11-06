# Codex Wallpaper

简体中文 · [English](README.en.md)

把 Steam Wallpaper Engine 已下载的创意工坊壁纸用作 Windows Codex 窗口背景。通过专用启动器打开 ChatGPT 后，在窗口里按 **Ctrl + Alt + W** 呼出缩略图面板，点一张即可切换。

## 功能

- 扫描 Steam 创意工坊中 Wallpaper Engine 的本地项目（应用 ID 为 `431960`）。
- 支持常见图片和 MP4、WebM。场景项目在有可用预览时使用预览画面，场景本身的动态效果由 Wallpaper Engine 渲染。
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
| 场景壁纸显示为预览图 | 当前支持项目预览，尚未接入 Wallpaper Engine 场景渲染器。 |

在解压目录打开 PowerShell，用以下命令检查库中能识别的项目。该命令不会启动 ChatGPT。

```powershell
.\scripts\start.cmd -List -SteamLibraryPath "E:\Steam"
```

交互参考了 [reasonix-wallpaper](https://github.com/lwh-Labs/reasonix-wallpaper)。需要 Codex Dynamic Skin 的旧实现保留在 [v0.2.0](https://github.com/lwh-Labs/codex-wallpaper/releases/tag/v0.2.0)。
