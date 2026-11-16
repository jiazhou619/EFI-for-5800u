#!/bin/bash
# 验证当前系统是否处于"黄金状态"(重启后运行)
echo "============================================================"
echo " 黄金状态校验"
echo "============================================================"
FAIL=0
check() { # $1=描述 $2=实际 $3=期望正则
  if echo "$2" | grep -qE "$3"; then echo "  [OK] $1: $2"; else echo "  [!!] $1: $2 (期望 /$3/)"; FAIL=1; fi
}

echo "=== 运行时状态 ==="
OUT=$(ioreg -lw0 -p IOService -r -c CirrusAudioFixup 2>/dev/null)
VAL() { echo "$OUT" | grep -i "Cirrus_$1" | head -1 | sed -E 's/.*= //; s/^"//; s/"$//'; }

check "Driver_Verdict" "$(VAL Driver_Verdict)" 'READY_DSP'
check "Amplifier_Status" "$(VAL Amplifier_Status)" 'READY|PLAYING'
check "Platform_Authorized" "$(VAL Platform_Authorized)" 'Yes|True'
check "PCI_SSID" "$(VAL Platform_PCI_SSID)" '397031483'
check "Detected_Amplifiers" "$(VAL Detected_Amplifiers)" '^2$'
check "DSP_BOOT i2c0" "$(VAL DSP_BOOT_VERDICT_i2c0)" 'HEALTHY'
check "DSP_BOOT i2c1" "$(VAL DSP_BOOT_VERDICT_i2c1)" 'HEALTHY'
check "PCM_Gain i2c0" "$(VAL Tuning_PCM_Gain_i2c0)" '^20$'
check "PCM_Gain i2c1" "$(VAL Tuning_PCM_Gain_i2c1)" '^20$'
check "Tuning i2c0" "$(VAL Tuning_Source_i2c0)" 'EMBEDDED_BINCFG'
check "Read_Fail" "$(VAL Read_Fail)" '^0$'
check "Write_Fail" "$(VAL Write_Fail)" '^0$'

echo
echo "=== 守护进程 ==="
if launchctl list 2>/dev/null | grep -qi node17 || launchctl print gui/$(id -u)/com.local.node17-fix 2>/dev/null | grep -q "state = running"; then echo "  [OK] node17 守护进程运行中"; else echo "  [!!] node17 未运行 -> 双击 INSTALL-PERSISTENCE.command"; FAIL=1; fi

echo
if [ "$FAIL" -eq 0 ]; then echo "结果: 全部通过 —— 当前就是黄金状态 ✅"; else echo "结果: 有项目未达标, 见上方 [!!]"; fi
