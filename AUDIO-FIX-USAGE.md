# 音频修复使用说明（Lenovo Yoga Slim 7 Carbon 14ACN6 / 82L0）

本仓库是该机型的 OpenCore EFI 备份。2026-11-16 完成了 CS35L51 智能功放音频的实机修复，本文件说明这套 EFI 的音频部分怎么用、怎么验证、怎么回滚。

## 一、这套 EFI 解决了什么

本机为 AMD Ryzen 7 5800U + ALC287 + Cirrus CS35L51（`CLSA0102`，PCI SSID `0x17AA383B`）的黑苹果。原声卡只有高音、没有低频、声音发尖。根因有两层：

1. **驱动层**：上游 CirrusAudioFixup 按 `383D` SSID 适配，不认本机的 `383B`；且 DSP 增益用保守默认值、偶发 I2C 错误会锁死功放。→ 已通过重新编译 kext 修复（源码见 `CirrusAudioFixup-CS35L51` 仓库 `cs35l51` 分支及其 `CS35L51-383B-PATCH-NOTES.md`）。
2. **codec 路由层**：`alcid=21` 的 layout 没有激活低音单元所在的 Node `0x17`，功放收不到音频流。→ 通过一个开机守护进程在运行时补发 HDA verb 激活（见下文 `audio-tools/`）。

## 二、当前 EFI 的音频关键配置

| 项目 | 值 |
| --- | --- |
| CirrusAudioFixup.kext | SHA256 前缀 `087e0b69`（383B + gain20 + I2C 自愈三合一，黄金版） |
| boot-args | `... alcid=21 alcverbs=1 -cirrusdbg`（**保留 alcid=21**，**无** `-cirrusnodsp`） |
| 依赖 kext | Lilu 1.7.3、AppleALC 1.9.8、VoodooI2C（KPI 版）、VoodooGPIO |

- `-cirrusnodsp` 是 DAC 旁路模式（跳过 DSP、没有增益补偿）。**移除它**才能启用 DSP、让音量恢复正常。
- `alcverbs=1` 必须保留：`audio-tools/` 的守护进程依赖 AppleALC 的用户态 verb 接口。

## 三、安装步骤

### 1. EFI 部分

把本仓库的 `EFI/` 目录整体拷贝到 EFI 分区（FAT32 的 `EFI` 分区，替换已有 `EFI` 目录）。拷贝前请先备份你原来的 EFI。

> 提示：仓库内所有 `config.plist` 的 `MLB`、`ROM`、`SerialNumber` 已清空（不含原机标识）。在别的机器上使用本 EFI 时，请填入那台机器自己的标识；`EFI/restore/RESTORE-GOLDEN.sh` 恢复时会自动保留你本机现有的标识，不会抹掉它们。

### 2. Node 0x17 守护进程（低音必需）

这套 EFI 单独装好还不够，**低音依赖一个开机守护进程**（verb 是运行时的，重启失效，守护进程负责每次重放）：

```bash
cd audio-tools
./INSTALL.sh
```

看到 `com.local.node17-fix` 出现在输出里即成功。它会在每次登录/唤醒后自动检测并激活 Node `0x17`。

- 手动检查：`launchctl list | grep node17`
- 手动激活一次（声音又变尖时）：`./activate-node17.sh apply`
- 卸载守护进程：`launchctl bootout gui/$(id -u)/com.local.node17-fix && rm ~/Library/LaunchAgents/com.local.node17-fix.plist`

## 四、验证

重启（若之前动了功放供电，建议物理断电：关机→拔电源→长按电源键 20~30 秒→开机）后运行：

```bash
ioreg -lw0 -p IOService -r -c CirrusAudioFixup | grep -iE 'Driver_Verdict|Amplifier_Status|DSP_BOOT|Tuning_PCM_Gain|Tuning_Source|Playback_Verdict|Read_Fail|Write_Fail'
```

全绿标志：

```
Driver_Verdict       = READY_DSP
Amplifier_Status     = READY / PLAYING
DSP_BOOT_VERDICT     = HEALTHY (i2c0 / i2c1)
Tuning_PCM_Gain      = 20
Tuning_Source        = EMBEDDED_BINCFG
Read_Fail / Write_Fail = 0
Playback_Verdict     = SAFE_IDLE_VERIFIED (静音时) / ACTIVE_... (播放时)
```

然后播放一段有鼓点的音乐，确认低频和音量。

> 开机瞬间偶尔会出现一次 `COMMUNICATION_FAILED` / `I2C_IDENTITY_TRANSFER_FAILED`，这是 I2C 功放探测的时序瞬态，已验证会自动恢复。等几秒再查一次即可，不必惊慌。

## 五、回滚 / 故障处理

- **声音又变尖、低音没了**：先 `cd audio-tools && ./activate-node17.sh apply`；再确认守护进程在跑 `launchctl list | grep node17`，不在就重跑 `./INSTALL.sh`。
- **DSP 模式有问题**（无声/爆音/进不了系统）：在 OpenCore 启动菜单选中 macOS 后按空格编辑 boot-args，末尾加 `-cirrusnodsp` 进系统（DAC 旁路模式）。
- **kext 版本回退**：
  - `5f6c33fd` = 383B 版（能进系统、低频回来，但音量小）
  - `38e80927` = gain20 版（音量提升，但偶发 I2C 故障会锁死低音）—— **不要单独回退到这版**
  - `087e0b69` = 当前黄金版（含 I2C 自愈）—— 推荐始终用这版

## 六、已知限制

- 音量仍可能比 Windows 略小：Windows 叠加了联想官方 EQ、响度、Nahimic 等音效链，本开源驱动不复刻这套 OEM 音效链。
- `Calibration_Status = NOT_AVAILABLE`、`Speaker_ID = UNKNOWN`：未导入出厂扬声器校准，属音质可选优化，不影响使用。
- 本机 `alcid=21` 为用户指定值，勿改为 16。
