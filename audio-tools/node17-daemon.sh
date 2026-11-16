#!/bin/sh
# Node 0x17 持久化守护进程
# 作用:开机 / 睡眠唤醒后,自动检测 Node 0x17(功放/低音 pin)是否被 AppleALC 正确
#       激活为输出;若没有,则重放激活 verb 序列。
# 只写运行时 codec 寄存器,不改 EFI / NVRAM / kext,不影响能否进系统。
# 卸载:launchctl unload ~/Library/LaunchAgents/com.local.node17-fix.plist

DIR="$(cd "$(dirname "$0")" && pwd)"
A="$DIR/alc-verb"
N="0x17"
LOG="$DIR/node17-daemon.log"
INTERVAL=5

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG" 2>/dev/null; }

activate() {
  "$A" -q "$N" 0x701 0x00 >/dev/null 2>&1   # 连接选择 -> DAC index 0
  "$A" -q "$N" 0x705 0x00 >/dev/null 2>&1   # 电源 D0
  "$A" -q "$N" 0x3b0 0x00 >/dev/null 2>&1   # 输出 amp 取消静音
  "$A" -q "$N" 0x707 0x40 >/dev/null 2>&1   # Pin OUT 使能(关键)
}

log "daemon started"
while true; do
  # 读 Pin Widget Control;服务未就绪/被重置时不会等于 0x40
  ctl=$("$A" -q "$N" 0xF07 0x00 2>/dev/null | tr -d '[:space:]')
  if [ "$ctl" != "0x00000040" ]; then
    activate
    log "pin_ctl=$ctl -> reactivated"
  fi
  sleep "$INTERVAL"
done
