#!/bin/zsh
# Node 0x17 运行时探测 / 激活 / 回滚
# 全部通过 AppleALC alcverbs=1 用户态接口,仅改运行时寄存器,重启即失效。
# 不改 EFI / NVRAM / kext,不会影响能否进系统。
#
# 用法:
#   ./activate-node17.sh probe    # 只读探测(安全)
#   ./activate-node17.sh apply    # 应用激活 verb 序列
#   ./activate-node17.sh revert   # 回滚(关闭 node 0x17 输出)
#   ./activate-node17.sh status   # 读回当前状态

set -u
A="$(cd "$(dirname "$0")" && pwd)/alc-verb"
N=0x17

if [[ ! -x "$A" ]]; then
  echo "找不到 alc-verb: $A" >&2
  exit 1
fi

probe() {
  echo "===== Node 0x17 (功放/低音 pin) ====="
  echo -n "  WIDGET_CAP    "; "$A" -q $N 0xF00 0x09
  echo -n "  PIN_CAP       "; "$A" -q $N 0xF00 0x0C
  echo -n "  CONNLIST_LEN  "; "$A" -q $N 0xF00 0x0E
  echo -n "  POWER_STATE   "; "$A" -q $N 0xF05 0x00
  echo -n "  PIN_WIDGET_CTL"; "$A" -q $N 0xF07 0x00
  echo -n "  EAPD          "; "$A" -q $N 0xF0C 0x00
  echo -n "  CONFIG_DEFAULT"; "$A" -q $N 0xF1C 0x00
  echo -n "  CONN_SELECT   "; "$A" -q $N 0xF01 0x00
  echo "----- 对照 Node 0x14 (高音 pin,正常) -----"
  echo -n "  PIN_CAP       "; "$A" -q 0x14 0xF00 0x0C
  echo -n "  POWER_STATE   "; "$A" -q 0x14 0xF05 0x00
  echo -n "  PIN_WIDGET_CTL"; "$A" -q 0x14 0xF07 0x00
  echo -n "  CONFIG_DEFAULT"; "$A" -q 0x14 0xF1C 0x00
}

apply() {
  echo "应用 Node 0x17 激活序列(运行时,重启失效):"
  echo "  1) 0x701 0x00  连接选择 -> DAC index 0"
  "$A" -q $N 0x701 0x00 >/dev/null
  echo "  2) 0x705 0x00  电源状态 -> D0 全功率"
  "$A" -q $N 0x705 0x00 >/dev/null
  echo "  3) 0x3b0 0x00  输出 amp 取消静音 0dB"
  "$A" -q $N 0x3b0 0x00 >/dev/null
  echo "  4) 0x707 0x40  Pin OUT 使能 (启动 BCLK/I2S) <- 关键"
  "$A" -q $N 0x707 0x40 >/dev/null
  echo "  注: PIN_CAP=0x1c 无 EAPD,跳过 0x70c。"
  echo "完成后读回:"
  status
}

revert() {
  echo "回滚:关闭 Node 0x17 输出(或重启即可)"
  "$A" -q $N 0x707 0x00 >/dev/null
  "$A" -q $N 0x705 0x03 >/dev/null
  status
}

status() {
  echo -n "  POWER_STATE   "; "$A" -q $N 0xF05 0x00
  echo -n "  PIN_WIDGET_CTL"; "$A" -q $N 0xF07 0x00
  echo -n "  CONN_SELECT   "; "$A" -q $N 0xF01 0x00
}

case "${1:-probe}" in
  probe)  probe  ;;
  apply)  apply  ;;
  revert) revert ;;
  status) status ;;
  *) echo "用法: $0 {probe|apply|revert|status}" >&2; exit 1 ;;
esac
