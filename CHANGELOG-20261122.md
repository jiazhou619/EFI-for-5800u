# 更新日志 / Changelog

## 2026-11-22 — 同步本机验证通过的 EFI 状态

本次将实机当前正在使用、且已验证「低音正常 + 触摸正常」的 EFI 状态同步回本仓库。

### 变更的 kext

| kext | 旧（仓库） | 新（同步后） | 原因 |
| --- | --- | --- | --- |
| `CirrusAudioFixup.kext` | `33AA9CEC` | `E15E5975` | 当前实机在用的版本，功放探测正常、低音正常 |
| `VoodooI2CHID.kext` | `A26590FF` | `84ED0F48` | 与当前实机 I2C 栈一致 |
| `VoodooI2CAtmelMXT.kext` | — | `D7796F74` | 补齐实机存在的 I2C satellite |
| `VoodooI2CFTE.kext` | — | `7E89D70A` | 同上 |
| `VoodooI2CSynaptics.kext` | — | `48AD81D4` | 同上 |

`config.plist` 内容未变（与实机仅缩进格式差异，规范化后哈希一致），`boot-args` 保持：

```
-lilubetaall revpatch=sbvmm,cpuname revblock=media -noredpdelay -no_compat_check alcid=21 alcverbs=1 itlwm_he=1 -vi2c-force-polling
```

其余 kext、ACPI、Drivers、Tools 与已验证状态一致，未改动。

### ⚠️ 关键：`VoodooI2C.kext` 必须是定制 fork，不能用官方版

本次 `VoodooI2C.kext` 保持为 **UUID `379C7711`（2.9.1 定制 fork）**，这是音频功放正常工作的前提：

- 该 fork 暴露了 `VoodooI2CTransferToAddress` 接口，`CirrusAudioFixup` 依靠它读取 CS35L41 功放芯片。
- **官方上游 2.9.1（UUID `49691D8A`）和 2.8 都不含此接口**。换成官方版会导致功放探测失败（`WAITING_BOARD_IDENTITY` / `CS35L41_PROPERTIES_INCOMPLETE`），表现为**低音消失、声音发薄**。
- 判断版本请认准 UUID `379C7711`，不要只看「2.9.1」这个版本号。

恢复/替换 I2C 时务必确认 UUID，避免再次踩坑。

### 关于触摸板暖启动失效

已知问题：普通关机（S5）后触摸控制器保持供电、内部状态不复位，可能导致下次开机触摸板无反应；**长按电源键 10 秒真正断电**可恢复。此为硬件/EC 层面的供电残留，非本次 EFI 改动引入。ACPI 层的修复方向（I2C 控制器 `RSET` 软复位 SSDT）尚在评估中，暂未纳入本 EFI。

### 验证状态

同步后实机状态（IORegistry）：

- `Cirrus_Detected_Amplifiers = 2`
- `Cirrus_Driver_Verdict = READY_DSP`
- `Cirrus_Communication_Status = READY`
- `Cirrus_Audio_Event_Mode = IOAUDIO_FAMILY_EVENTS`
- 运行中的 `VoodooI2C` = `379C7711`
