#!/usr/bin/env bash
set -euo pipefail

IMG="${1:-}"

if [ -z "$IMG" ]; then
  echo "Uso: render-image.sh /caminho/da/imagem"
  exit 1
fi

if [ ! -f "$IMG" ]; then
  echo "Arquivo não encontrado: $IMG"
  exit 1
fi

pkill -x fbi >/dev/null 2>&1 || true
chvt 1 >/dev/null 2>&1 || true

fbi -T 1 -noverbose -a "$IMG" >/dev/null 2>&1 &
