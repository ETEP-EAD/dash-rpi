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

# mata qualquer instância anterior
pkill -x fbi >/dev/null 2>&1 || true

# força ir pro tty1
chvt 1 >/dev/null 2>&1 || true

# pequena pausa ajuda estabilidade
sleep 0.2

# limpa tela (importante!)
clear >/dev/tty1 2>/dev/null || true

# renderiza
fbi -T 1 -noverbose -a "$IMG" >/dev/null 2>&1 &
