# NootedRed VCN 视频解码卡死问题诊断（2026-11-23）

> 本文记录一次「用着用着整机冻结、只能强制按电源重启」的故障排查结论。
> 结论：**与音频/触摸/I2C 无关**，根因是 NootedRed（第三方 fork 1.3.0）的 AMD VCN 视频解码通道反复复位，把 WindowServer 拖死。
> 处理方式（2026-11-24）：**升级 NootedRed 1.3.0 → 1.3.1**，未加 boot 参数；升级后重启数次未复现。正确参数作为备用方案记录在此，供再次发生时直接使用。

## 症状

- 2026-11-23 18:24 左右，正在使用 **WorkBuddy** 时整机冻结，鼠标/屏幕无响应，只能长按电源键强制重启。
- 卡死前没有内核 panic（最新 panic 仍是前一天 21:31 的）——这是"冻死"而非"崩溃"。

## 根因证据链

| 证据 | 内容 |
|---|---|
| `Kernel_2026-11-23-1824xx.gpuRestart`（共 8 份） | 18:24:31 → 18:25:23，每 10 秒一次，全部 `Restart Channel: 12 VCN0Dec` |
| `WindowServer_2026-11-23-182515.userspace_watchdog_timeout.spin` | WindowServer 被 kernel_task turnstile 阻塞 5.53 秒，触发 watchdog 超时冻结 |
| GPU 报告细节 | `VM Protection Fault (MM) VMID=7`、`SubmitContext = Video` |
| 触发进程 | spin 报告中出现 `Electron Framework.framework`、`chrome_crashpad_handler` |
| 平台 | AMD Radeon RX Renoir（5800U 核显），驱动 `NootedRed 1.3.0`（UUID `48235632`）|

**因果链**：WorkBuddy 是 Electron/Chromium 应用 → 大量调用 GPU 做界面合成/视频解码 → 触发 VCN 解码通道内存保护错误 → `VCN0Dec` 反复复位 → WindowServer 主线程被阻塞 → watchdog 超时 → 整机冻结。

这是 NootedRed 的已知痛点：Chromium 系应用（Chrome/Edge/VS Code/WorkBuddy 等）的 GPU 合成容易触发 AMD VCN 通道复位。

## 重要纠错：boot 参数用哪个

### ❌ `-nredvcn` —— 不适用于本机，不要用

这是**官方旧版** NootedRed 的参数。本机用的是第三方 fork **1.3.0**（用户所称 weachey 分支，官方主线最新才 0.8.10），从二进制中确认：**这个 fork 里根本没有 `-nredvcn` 这个参数**。加了无效；且资料显示该参数在官方语境下也可能是「启用」VCN 而非禁用，方向存疑。

### ✅ `-NRedNoVDA` —— 本 fork 关闭 VCN 解码桥的正确参数

从本机 `/Users/zhou/Downloads/NootedRed-1.3.0-RELEASE/NootedRed.kext` 二进制中提取到（UUID `48235632`，与运行中一致）：

| 参数 | 作用 |
|---|---|
| **`-NRedNoVDA`** | 关闭视频解码加速（VCN 桥），**保留 GPU 图形加速** ← 针对本问题的正确缓解参数 |
| `-NRedForceVDA` | 强制开启 VDA（外接显卡时用）|
| `-NRedNoHEVC` / `-NRedNoHEVC10` / `-NRedNoVP9` | 只关特定编码格式 |
| `-NRedNoAccel` | 关闭整个图形加速（回到 FB-only，代价大）|
| `-NRedOff` | 完全禁用 NootedRed |

二进制内相关日志串印证了 VCN 桥机制：
- `VCN bridge only supports Darwin 22 to 25 (macOS 13 to 26)`
- `VCN2 initHardware channel failed; disabling the VCN bridge`
- `X5000/X6000 ABI mismatch; VCN bridge disabled`

注意 Darwin 25（macOS 26）正处在支持范围的上边界，这是不稳定因素之一。

## 如果问题再次发生

在 EFI 分区 `EFI/OC/config.plist` 的 `NVRAM → Add → 7C43642F-... → boot-args` 末尾加：

```
-NRedNoVDA
```

代价：视频解码走 CPU 软解，1080p 无压力，4K 会多耗 CPU/电；**图形加速和界面流畅度不受影响**。

改完重启验证：重点观察用 WorkBuddy / Chrome 等 Electron 应用是否还会卡死。

## 处理结果（2026-11-24）

- **升级到 NootedRed 1.3.1**（UUID `C21EF0BF`）替代 1.3.0，未加任何 boot 参数。
  - 1.3.1 新增 `-NRedVCN1Decode` / `-NRedVCN1HEVC` / `-NRedVCN1HEVC10` 等 VCN 相关参数，说明新版调整了 VCN 解码路径。
  - 保留 `-NRedNoVDA` 作为备用：若 1.3.1 下仍出现 VCN 卡死，加它可关掉 VCN 桥、保留图形加速。
- 升级后重启数次，用户反馈**未再出现卡死，触摸板和声音的暖启动失效问题也未复现**。
- 说明：触摸/音频走的是 I2C（VoodooI2C 定制 fork `379C7711`），与 NootedRed（显卡驱动）无直接因果关系。此次稳定更可能来自此前 I2C 换回定制 fork + 一次真断电冷启动；"重启几次没问题"不等于该硬件级问题已根治，仍需长期观察。
