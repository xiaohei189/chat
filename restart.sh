#!/bin/bash
# OpenIM Chat 本地启动/重启脚本
# 日志输出: ./_output/logs/
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="$SCRIPT_DIR/_output/logs"
mkdir -p "$LOG_DIR"

‘ usage() {
    echo "用法: $0 [start|stop|restart|status|log]"
    echo "  start   - 启动服务"
    echo "  stop    - 停止服务"
    echo "  restart - 重启服务（重新 build + 启动）"
    echo "  status  - 查看运行状态"
    echo "  log     - 实时查看日志"
    exit 1
}

do_stop() {
    echo "=== 停止 openim-chat ==="
    pkill -f "chat-api" 2>/dev/null || true
    pkill -f "chat-rpc" 2>/dev/null || true
    pkill -f "admin-api" 2>/dev/null || true
    pkill -f "admin-rpc" 2>/dev/null || true
    sleep 2
    echo "已停止"
}

do_start() {
    echo "=== 启动 openim-chat ==="
    cd "$SCRIPT_DIR"
    nohup mage start > "$LOG_DIR/openim-chat.log" 2>&1 &
    sleep 10
    echo "进程数: $(ps aux | grep -E 'chat-|admin-' | grep -v grep | wc -l)"
    echo "日志: $LOG_DIR/openim-chat.log"
}

do_build_start() {
    echo "=== 构建 openim-chat ==="
    cd "$SCRIPT_DIR"
    mage build 2>&1 | tail -5
    do_start
}

do_status() {
    echo "=== 进程 ==="
    ps aux | grep -E "chat-|admin-" | grep -v grep | awk '{printf "%-8s %-10s %s\n", $2, $3"%", $11}'
    echo ""
    echo "=== 端口 ==="
    ss -tlnp | grep -E "10008|10009"
}

do_log() {
    tail -f "$LOG_DIR/openim-chat.log"
}

case "${1:-restart}" in
    start)   do_start ;;
    stop)    do_stop ;;
    restart) do_stop; do_build_start ;;
    status)  do_status ;;
    log)     do_log ;;
    *)       usage ;;
esac
