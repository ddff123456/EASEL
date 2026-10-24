#!/bin/bash
# Easel Mac 一键启动：双击本文件即可打开网页工作台。
# 工作台是网页端（浏览器访问），不是独立桌面客户端。

set -u

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT" || exit 1

PORT="${EASEL_PORT:-7860}"
URL="http://127.0.0.1:${PORT}/"
EASEL="${ROOT}/.venv/bin/easel"

echo "================================"
echo "  Easel 网页工作台"
echo "  地址: ${URL}"
echo "  关闭本窗口或按 Ctrl+C 即停止"
echo "================================"
echo

if [[ ! -x "${EASEL}" ]]; then
  echo "还没有安装好运行环境（找不到 .venv）。"
  echo "请先在本目录打开终端，执行一次："
  echo "  bash setup.sh"
  echo
  echo "安装完成后再双击本文件。"
  echo
  read -r -p "按回车键关闭窗口..." _
  exit 1
fi

if nc -z 127.0.0.1 "${PORT}" >/dev/null 2>&1; then
  echo "工作台已在运行，正在打开浏览器。"
  open "${URL}"
  echo
  read -r -p "按回车键关闭窗口..." _
  exit 0
fi

OPENER_PID=""
cleanup() {
  if [[ -n "${OPENER_PID}" ]]; then
    kill "${OPENER_PID}" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT INT TERM

(
  for _ in $(seq 1 90); do
    if nc -z 127.0.0.1 "${PORT}" >/dev/null 2>&1; then
      open "${URL}"
      exit 0
    fi
    sleep 1
  done
  echo "服务已启动较久，浏览器没有自动打开。请手动访问 ${URL}"
) &
OPENER_PID=$!

echo "正在启动，浏览器会在就绪后自动打开…"
echo
"${EASEL}" web --port "${PORT}"
STATUS=$?

echo
if [[ "${STATUS}" -ne 0 ]]; then
  echo "启动失败（退出码 ${STATUS}）。上面的报错是原因。"
  echo "常见情况：依赖没装完，可再执行一次 bash setup.sh"
fi
read -r -p "按回车键关闭窗口..." _
exit "${STATUS}"
