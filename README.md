# Codex Traffic Light for Windows

一个 Windows 桌面红绿灯小组件，用来提示 Codex 当前状态：正在工作、等待你处理、已完成或空闲，并在浮窗底部显示 Codex 5 小时和 1 周剩余额度百分比。

本项目是基于原作者 [langkonzil](https://github.com/langkonzil) 的 macOS 项目修改而来的 Windows 版本。感谢原作者的开源工作：

- 原作者：[langkonzil](https://github.com/langkonzil)
- 原项目：[langkonzil/codex-traffic-light-mxp](https://github.com/langkonzil/codex-traffic-light-mxp.git)
- 原项目许可证：Apache License 2.0

本仓库继续保留 Apache License 2.0。

## 功能概览

- Windows 悬浮红绿灯：桌面显示红、黄、绿三种状态灯。
- 系统托盘菜单：可显示/隐藏窗口、静音、手动切换状态、清空失联任务、退出。
- Codex Hooks 集成：根据 Codex hook 事件自动更新状态。
- 等待提醒：需要你回复、确认或授权时显示红灯并闪烁。
- 完成提醒：任务完成时显示绿灯并播放提示音。
- 多任务聚合：多个 Codex 任务同时存在时，优先显示最需要关注的状态。
- 额度显示：浮窗底部显示 Codex 5 小时和 1 周剩余额度。
- Windows 开机自启：可在设置面板中开启或关闭。

## 状态说明

| 颜色 | 状态 | 含义 | 行为 |
| --- | --- | --- | --- |
| 红灯 | `waiting` | Codex 正在等待你回复、确认、授权或补充信息 | 闪烁并播放提示音 |
| 黄灯 | `working` | Codex 正在执行任务 | 静默显示 |
| 绿灯 | `done` | 任务已完成，可以验收 | 播放完成提示音 |
| 暗灯 | `idle` | 没有活跃任务 | 静默显示 |

多个任务同时存在时，聚合状态按以下优先级计算：

1. 只要有任务处于 `waiting`，显示红灯。
2. 否则只要有任务处于 `working`，显示黄灯。
3. 否则如果有最近完成的任务，短暂显示绿灯。
4. 其他情况显示暗灯。

## 环境要求

- Windows 系统
- 已安装并可正常使用 Codex
- Codex Hooks 可用
- 构建时需要系统自带的 .NET Framework C# 编译器

Windows 构建脚本默认使用：

```powershell
C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe
```

不需要额外安装 .NET SDK。

## 构建 Windows 版本

在项目根目录运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Windows\build-win.ps1
```

构建产物会生成到：

```text
dist\windows\
```

主要文件：

```text
dist\windows\红绿灯.exe
dist\windows\codex-light-mxp.exe
dist\windows\codex-light-hook-mxp.exe
```

## 运行

构建完成后，运行：

```powershell
.\dist\windows\红绿灯.exe
```

启动后会出现一个桌面悬浮红绿灯窗口，并在系统托盘显示图标。

## 安装 Codex Hooks

推荐使用 Windows 安装脚本：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Windows\install-global-command-win.ps1
```

脚本会把命令行工具安装到：

```text
%USERPROFILE%\.codex\bin
```

并把 Windows hooks 配置写入：

```text
%USERPROFILE%\.codex\config.toml
```

安装完成后，在 Codex 中运行：

```text
/hooks
```

然后检查并信任 `codex-light-hook-mxp.exe`。只有完成信任后，红绿灯才会随着 Codex 任务自动变色。

Windows hooks 示例文件在：

```text
Windows\hooks.example.toml
```

## 日常操作

| 操作 | 功能 |
| --- | --- |
| 拖动悬浮窗 | 移动红绿灯位置 |
| 点击标题栏关闭按钮 | 关闭窗口 |
| 点击标题栏最小化按钮 | 隐藏窗口 |
| 点击设置按钮 | 打开设置面板 |
| 点击刷新图标 | 手动刷新额度 |
| 双击托盘图标 | 显示或隐藏窗口 |
| 右键托盘图标 | 打开菜单 |

托盘菜单可以手动切换：

- 黄灯：正在干活
- 绿灯：完成验收
- 红灯：等你回复
- 全暗：空闲

也可以清空失联任务或退出程序。

## 运行时文件

Windows 版默认把状态、偏好和日志保存到：

```text
%APPDATA%\CodexTrafficLight\state.json
%APPDATA%\CodexTrafficLight\preferences.json
%APPDATA%\CodexTrafficLight\hook-mxp.log
%APPDATA%\CodexTrafficLight\quota-mxp.log
```

如需隔离测试，可以通过环境变量指定状态文件：

```powershell
$env:CODEX_TRAFFIC_LIGHT_STATE_PATH="C:\Temp\codex-light-state.json"
```

## 额度显示

红绿灯会尝试通过本机 Codex app-server 读取额度：

```text
codex app-server --stdio
account/rateLimits/read
```

浮窗底部显示：

- `5小时` 剩余额度百分比
- `1周` 剩余额度百分比

如果 app-server 暂时不可用，程序会保留上一次成功读取的额度，不会编造数字。

## 命令行工具

安装后可以使用：

```powershell
codex-light-mxp working
codex-light-mxp done
codex-light-mxp waiting
codex-light-mxp idle
codex-light-mxp status
codex-light-mxp clear
codex-light-mxp quit
codex-light-mxp quota --app-server
```

手动写入额度：

```powershell
codex-light-mxp quota --five-hour 72 --weekly 48
```

从 JSON 标准输入提取额度：

```powershell
'{"quota":{"fiveHourRemainingPercent":71,"weeklyRemainingPercent":47}}' | codex-light-mxp quota --stdin --json
```

## 常见问题

### 红绿灯不会自动变色

请检查：

- 是否运行过 `Windows\install-global-command-win.ps1`
- 是否在 Codex 中运行过 `/hooks`
- 是否信任了 `codex-light-hook-mxp.exe`
- `%USERPROFILE%\.codex\config.toml` 中的 hook 路径是否正确

也可以查看日志：

```text
%APPDATA%\CodexTrafficLight\hook-mxp.log
```

### 一直没有额度

先确认 Codex 本身可以正常使用，然后查看：

```text
%APPDATA%\CodexTrafficLight\quota-mxp.log
```

如果 Codex app-server 没有返回可识别的额度字段，底部会显示 `--` 或保留旧值。

### 想重置状态

可以从托盘菜单选择“清空失联任务”，也可以运行：

```powershell
codex-light-mxp clear
```

### 想关闭提示音

右键托盘图标，选择“静音提示音”。

## 和原 macOS 版的关系

原项目主要面向 macOS，包含 Swift 菜单栏应用、悬浮窗、命令行工具和 Codex Hooks 集成。

本仓库是在原项目基础上做的 Windows 修改版，重点是：

- 增加 Windows WinForms 悬浮红绿灯
- 增加 Windows 构建脚本
- 增加 Windows hooks 安装脚本
- 增加 Windows 托盘菜单、提示音和运行时路径
- 适配 `%APPDATA%\CodexTrafficLight` 状态目录

原作者：

```text
https://github.com/langkonzil
```

原作者项目地址：

```text
https://github.com/langkonzil/codex-traffic-light-mxp.git
```

## 许可证

本项目基于 Apache License 2.0 开源项目修改，并继续使用 Apache License 2.0。

请保留原项目作者信息、许可证文本和必要的修改说明。
