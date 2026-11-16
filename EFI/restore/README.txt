================================================================
 已知可用"黄金状态" — 2026-11-16 21:51 验证全绿
================================================================
机型: Lenovo Yoga Slim 7 Carbon 14ACN6 (82L0)
     Ryzen 7 5800U / SMBIOS MacBookPro16,3 / macOS 26.6.2
音频: ALC287 + CS35L51 (CLSA0102) / SSID 0x17AA383B

【这个状态验证过的关键指标】
  Driver_Verdict      = READY_DSP
  Amplifier_Status    = READY / PLAYING
  DSP_BOOT_VERDICT    = HEALTHY (i2c0 / i2c1 两颗)
  Detected_Amplifiers = 2
  I2C DeviceID        = 219712 (0x35A40) 两颗
  Tuning_PCM_Gain     = 20 (i2c0 / i2c1)
  Tuning_Source       = EMBEDDED_BINCFG
  Platform_Authorized = Yes
  PCI_SSID            = 397031483 (0x17AA383B)
  Read_Fail/Write_Fail= 0
  Playback_Verdict    = SAFE_IDLE_VERIFIED (静音时正常)
                        ACTIVE_... (播放时)
  守护进程            = com.local.node17-fix 运行中

【boot-args (config.plist NVRAM/Add)】
  -lilubetaall -vi2c-force-polling -amfipassbeta revpatch=sbvmm
  revblock=media -noredpdelay -no_compat_check alcid=21 alcverbs=1 -cirrusdbg
  注意: 保留 alcid=21 (用户指定); 无 -cirrusnodsp (DSP 增益开启)

【本包内容】
  Kexts/CirrusAudioFixup.kext  — I2CRecover 版, SHA256 前12位 087e0b6920c3
                                  = 383B + gain20 + I2C_TRANSFER 自愈修复
  config.plist                 — 上述 boot-args
  node17-daemon.sh             — Node 0x17 激活守护脚本 (每5s检测重放)
  com.local.node17-fix.plist   — LaunchAgent 配置
  INSTALL-PERSISTENCE.command  — 重装守护进程用
  alc-verb                     — 自制 verb 工具 (探测/手动激活用)
  RESTORE-GOLDEN.sh            — 一键恢复本状态到 EFI (需先挂载 EFI)
  CHECK-GOLDEN.sh              — 重启后校验是否处于本状态

【版本谱系 — sha256 前12位, 便于辨认】
  992250e52295  最早版 (383B 之前)
  87d275697db8  早期 DEVID 白名单修复
  5f6c33fd6b9c  383B 版 (能进系统, 低频回来, 但音量小)
  38e80927de02  gain20 版 (音量提升, 但 I2C_TRANSFER 故障会锁死低音) ← 不要回退到这版
  087e0b6920c3  I2CRecover 版 (= 本黄金包, 修复锁死自愈) ← 当前最佳

【怎么用】
  1) 一切正常: 什么都不用做。
  2) 以后改坏了要恢复: 挂载 EFI -> 运行 RESTORE-GOLDEN.sh -> 重启
     -> 运行 CHECK-GOLDEN.sh 确认。
  3) 守护进程没了 (声音又变尖): 双击 INSTALL-PERSISTENCE.command
     或手动: /Users/.../audio-fix/activate-node17.sh apply
  4) 注意: 开机瞬间偶尔会报 COMMUNICATION_FAILED (I2C 探测时序),
     已验证会自动恢复, 再跑一次 CHECK-GOLDEN.sh 即可, 不必惊慌。
================================================================
