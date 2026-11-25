# 2026-11-25 更新记录

## VoodooI2C 重编译：加入暖启动 I2C 总线恢复（recoverBus）

### 问题背景

Lenovo Yoga Slim 7 Carbon 14ACN6（R7 5800U）长期存在一个问题：
**冷启动触摸板正常，普通关机/重启（暖启动）后触摸板失效**，必须长按电源键 10 秒真断电（POR）才能恢复。
根因是暖重启时 I2C 从设备（触摸板）保持供电，若上次会话在事务中途被终止，从设备会持续拉低 SDA，
导致驱动首次探测超时（kIOReturnTimeout）。ACPI 的 `RSET()` 只打 ADSR 脉冲，不复位控制器本身，无效。

### 修复内容

本地 VoodooI2C 源码早已包含针对此问题的修复（从 Linux `i2c_dw_unstick_bus()` 移植），
但**此前从未编译进 EFI**——实机运行的仍是旧版。本次重新编译并替换，修复正式生效：

- 在 `initialiseBus()` 之后、设备探测之前调用 `recoverBus()`：
  使能 DesignWare bus-clear，向保留地址 0x7f 发起假读，由核心自动发出 **9 个 SCL 脉冲 + STOP**，
  把卡住的总线敲出来。
- 修正了 bus-clear 位（BIT11/BIT12）的兼容性探测（读写回读验证），
  以及 TX_ABRT 假成功的误判（只有 STOP_DET 才算真正释放总线）。
- 启动时无条件使能 bus-clear（SMU 只在电源转换时恢复，暖重启不管）。
- 新增 IOReg 诊断属性：`Recovery Status Entry` / `Recovery Con Entry` / `Recovery Try BIT11|BIT12` 等，
  可在系统信息中验证是否执行了恢复。

### 兼容性验证（关键）

| 项目 | 旧 kext | 新 kext | 结论 |
|---|---|---|---|
| `VoodooI2CTransferToAddress` 接口 | 有 | **有** | CirrusAudioFixup 走此接口驱动 CS35L41 功放，**低音不受影响** |
| `VoodooI2CRecoverBus` 接口 | 无 | 有（新增） | Cirrus 仅在 identity 读失败时才调用，且 `waitForFunction=false` 保证无接口时立即降级，正常启动不触发，安全 |
| LC_UUID | 379C7711... | D49CD71D... | CirrusAudioFixup 按接口名字符串查找，**不依赖 UUID**（二进制内无 UUID 字节序列），无影响 |
| IOKitPersonalities / AMDI0010 匹配 | — | 完全一致 | 设备匹配不变 |
| VoodooInput | 1.1.7 | 1.1.7 | 未变 |
| VoodooGPIO | 1.1 | 1.1 | 未变 |
| VoodooI2CServices | 1 | 1 | 未变 |

### 部署状态

- 实机 EFI：`/Volumes/NO NAME/EFI/OC/Kexts/VoodooI2C.kext` 已替换（新编译产物）
- 仓库：`EFI/oc/Kexts/VoodooI2C.kext` 已同步
- 其余 kext、config.plist、ACPI 补丁均未改动

### 重启后验证方法

1. 正常重启一次（无需长按电源键），测试触摸板**暖启动后是否直接可用**。
2. 终端执行以下命令，若出现新增诊断属性，说明新 kext 已生效：
   ```bash
   ioreg -l -w0 | grep -iE 'Recovery Status Entry|Recovery Con Entry|Recovery Try'
   ```
3. 确认音频低音仍在（CS35L41 功放经 `VoodooI2CTransferToAddress` 驱动）。

### 回退

如出现异常，将备份的旧 `VoodooI2C.kext` 拷回 `EFI/OC/Kexts/` 即可恢复原状。

---

## 补充诊断（15:30）：移除 `-vi2c-force-polling`

首次重启验证后触摸板仍失效。深入 IOReg 诊断发现：

- 新 kext 的 `recoverBus` **确实执行且成功**：I2CC（触摸板总线）`Recovery Result = STOP`（9 SCL + STOP 已发出，总线成功释放）。
- ELAN3915 设备**完整枚举**：`VoodooI2CHIDDevice`、`VoodooInput`、`Magic Trackpad 2` 模拟器、`AppleMultitouchTrackpadHIDEventDriver` 全部 attach。
- **根因浮现**：TPNL 的 `Interrupt Mode = "Polling"`。`boot-args` 里的 **`-vi2c-force-polling`** 强制触摸板跳过 GPIO 中断、改用轮询。

**结论**：总线恢复已由新 kext 的 `recoverBus` 解决，不再需要 force-polling 绕过。而轮询模式下暖启动后 ELAN 控制器状态异常时读不到触摸数据。该参数是 11-22 作为临时绕过加入的，但从未真正修好暖启动问题。

**改动**：从 boot-args 移除 `-vi2c-force-polling`，恢复触摸板走 GPIO 中断（DSDT 中 TPNL `_CRS` 定义了 GpioInt pin 0x74，VoodooGPIOAMD 已加载）。

**boot-args 变更**：
```
移除前: -lilubetaall revpatch=sbvmm,cpuname revblock=media -noredpdelay -no_compat_check alcid=21 alcverbs=1 itlwm_he=1 -vi2c-force-polling -NRedNoVDA
移除后: -lilubetaall revpatch=sbvmm,cpuname revblock=media -noredpdelay -no_compat_check alcid=21 alcverbs=1 itlwm_he=1 -NRedNoVDA
```
（同时把实机已在用的 `-NRedNoVDA` 补入仓库 config，保持仓库与实机一致，防止同步时丢失。）

**验证要点**：重启后执行 `ioreg -l -w0 | grep -i 'Interrupt Mode'`，触摸板 TPNL 应显示 `GPIO` 而非 `Polling`；再测暖启动触摸板。
