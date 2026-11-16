#!/bin/bash
# ============================================================
# 一键恢复"已知可用"黄金状态 (2026-11-16 21:51 验证全绿)
#   Driver_Verdict=READY_DSP / DSP_HEALTHY x2 / Gain=20
#   383B authorized / 2 amps / I2C 读写零失败
# 用法: 先挂载 EFI, 再运行本脚本, 完成后重启
# ============================================================
set -e
G="$(cd "$(dirname "$0")" && pwd)"
EFI_ROOT="/Volumes/NO NAME/EFI/oc"
EFI_KEXT="$EFI_ROOT/Kexts/CirrusAudioFixup.kext"
EFI_CFG="$EFI_ROOT/config.plist"
GOLD_SHA="087e0b6920c302df8d935f9958a585ab5ed5bbe7a0b13a38760130f6910b9cdb"

echo "============================================================"
echo " 恢复黄金状态 (I2CRecover 版 / 2026-11-16 验证全绿)"
echo "============================================================"
if [ ! -d "$EFI_ROOT/Kexts" ]; then
    echo "!! EFI 未挂载。请先把 EFI 分区挂载到 /Volumes/NO NAME 再运行。"
    exit 1
fi

TS=$(date +%Y%m%d-%H%M%S)
BK="$G/pre-golden-restore-$TS"
mkdir -p "$BK"
echo "[1/4] 备份当前状态 -> $BK"
[ -d "$EFI_KEXT" ] && cp -R "$EFI_KEXT" "$BK/CirrusAudioFixup.kext.current" || true
[ -f "$EFI_CFG" ] && cp "$EFI_CFG" "$BK/config.plist.current" || true

echo "[2/4] 恢复 kext"
rm -rf "$EFI_KEXT"
cp -R "$G/Kexts/CirrusAudioFixup.kext" "$EFI_KEXT"

echo "[3/4] 恢复 config.plist (boot-args: alcid=21 / alcverbs=1, 无 nodsp)"
cp "$G/config.plist" "$EFI_CFG"

echo "[4/4] 校验"
NEW_SHA=$(shasum -a 256 "$EFI_KEXT/Contents/MacOS/CirrusAudioFixup" | awk '{print $1}')
echo "  kext SHA: $NEW_SHA"
if [ "$NEW_SHA" = "$GOLD_SHA" ]; then
    echo "  kext 校验: OK (与黄金版一致)"
else
    echo "  !! kext 校验失败, 预期 $GOLD_SHA"; exit 1
fi
/usr/libexec/PlistBuddy -c 'Print :NVRAM:Add:7C436110-AB2A-4BBB-A880-FE41995C9F82:boot-args' "$EFI_CFG"

# 卸载 EFI 确保落盘
diskutil unmount "/Volumes/NO NAME" >/dev/null 2>&1 || true
echo "============================================================"
echo " 完成。EFI 已卸载。"
echo " 下一步: 重启 -> 运行 CHECK-GOLDEN.sh 验证"
echo " (守护进程若未运行, 双击 INSTALL-PERSISTENCE.command 重装一次)"
echo "============================================================"
