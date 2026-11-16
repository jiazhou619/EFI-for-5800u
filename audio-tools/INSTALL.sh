#!/bin/zsh
# 安装 Node 0x17 持久化守护进程(路径自动适配当前目录)。
# 在自己的终端里运行:  ./INSTALL.sh
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
LBL="com.local.node17-fix"
UID_N=$(id -u)
PLIST_DST="$HOME/Library/LaunchAgents/$LBL.plist"

echo "== 安装 Node 0x17 持久化守护进程 =="
echo "   工具目录: $DIR"

# 动态生成指向真实路径的 plist
cat > "$PLIST_DST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LBL</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/sh</string>
        <string>$DIR/node17-daemon.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$DIR/node17-daemon.out.log</string>
    <key>StandardErrorPath</key>
    <string>$DIR/node17-daemon.err.log</string>
</dict>
</plist>
EOF

launchctl bootout gui/$UID_N/$LBL 2>/dev/null || true
launchctl bootstrap gui/$UID_N "$PLIST_DST"
echo "== 状态 =="
launchctl list | grep -i node17 || echo "[警告] 未在运行"
echo "== 完成。每次登录/唤醒后会自动激活 Node 0x17 =="
echo "验证: launchctl list | grep node17"
echo "卸载: launchctl bootout gui/$UID_N/$LBL && rm $PLIST_DST"
