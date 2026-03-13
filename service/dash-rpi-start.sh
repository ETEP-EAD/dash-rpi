#!/usr/bin/env bash
set -euo pipefail

cd /opt/dash-rpi/app

setterm -blank 0 -powerdown 0 -powersave off >/dev/tty1 2>/dev/null || true

exec /usr/bin/node main.js
