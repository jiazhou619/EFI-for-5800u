# EFI-for-5800u

本机（**Lenovo Yoga Slim 7 Carbon 14ACN6 / 82L0**，AMD Ryzen 7 5800U）的 OpenCore EFI 备份，含 2026-11-16 完成的 CS35L51 音频修复。

## 机器配置

| 项目 | 值 |
| --- | --- |
| 机型 | Lenovo Yoga Slim 7 Carbon 14ACN6 / 82L0 |
| CPU | AMD Ryzen 7 5800U（Renoir） |
| SMBIOS | MacBookPro16,3 |
| macOS | 26.6.2 |
| 音频 | ALC287 + Cirrus CS35L51（CLSA0102，SSID `0x17AA383B`） |

## 仓库结构

```
EFI/
├── BOOT/                    OpenCore 引导
├── oc/
│   ├── ACPI/                SSDT（含 CLSA0102 功放定义）
│   ├── Drivers/             OpenCore 驱动
│   ├── Kexts/               全部 kext（含修复后的 CirrusAudioFixup.kext）
│   ├── Resources/           主题/资源
│   └── config.plist         当前在用的配置
└── restore/                 ★ 一键恢复包（见下）
    ├── RESTORE-GOLDEN.sh    恢复 kext + config 到验证通过的状态
    ├── CHECK-GOLDEN.sh      重启后验证是否处于黄金状态
    ├── INSTALL-PERSISTENCE.command  重装 Node 0x17 守护进程
    ├── config.plist / Kexts/        黄金版 kext 与配置
    └── alc-verb / node17-daemon.sh  低音激活工具
audio-tools/                 可移植的低音守护工具（独立安装用）
AUDIO-FIX-USAGE.md           音频修复使用说明
```

`EFI/` 下的 OpenCore 核心内容（BOOT/ACPI/Drivers/Kexts/Resources/config.plist）就是本机**正在使用**的那份，已逐字节核对一致。原厂 Windows 引导目录（`Lenovo/`、`Microsoft/`）不在本仓库，与本修复无关。

## 音频修复状态（黄金版）

当前 kext 为 `CirrusAudioFixup.kext` SHA256 前缀 `**087e0b69**`，包含三项修复：383B SSID 适配、DSP 增益 20、I2C 瞬态故障自愈。运行时验证全绿：

```
Driver_Verdict=READY_DSP   Amplifier_Status=READY/PLAYING
DSP_BOOT_VERDICT=HEALTHY x2   Tuning_PCM_Gain=20
Tuning_Source=EMBEDDED_BINCFG   Read_Fail/Write_Fail=0
```

关键 boot-args：`alcid=21`（用户指定，勿改）、`alcverbs=1`（守护进程依赖）、**无** `-cirrusnodsp`（启用 DSP 增益）。

## 一键恢复（改坏了用）

如果音频被改坏、或低音又消失：

```bash
# 1. 挂载 EFI 分区到 /Volumes/NO NAME
# 2. 运行恢复脚本（会自动备份当前状态再覆盖）
cd EFI/restore
./RESTORE-GOLDEN.sh
# 3. 重启
# 4. 验证
./CHECK-GOLDEN.sh
```

若重启后低音仍不回来（守护进程没装/丢了）：

```bash
cd EFI/restore
./INSTALL-PERSISTENCE.command
```

脚本全部为**可移植版**（自动定位自身目录），换机器、换路径都能用。详见 `AUDIO-FIX-USAGE.md`。

## 隐私提示

`EFI/oc/config.plist` 与 `EFI/restore/config.plist` 含本机标识 `MLB`、`ROM`。分享给他人前请改为自己机器的值。

## 相关

- 源码与改动说明：`jiazhou619/CirrusAudioFixup-CS35L51`（`cs35l51` 分支，`CS35L51-383B-PATCH-NOTES.md`）
