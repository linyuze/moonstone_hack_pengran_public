#!/usr/bin/env bash
# CookPulse 一键启动。真正的运行时载荷在 app/cookpulse.pkg（AES-256-GCM），
# 由同目录的 cookpulse 启动器在内存/临时目录中解密后运行。
set -euo pipefail
cd "$(dirname "$0")"
exec ./cookpulse "$@"
