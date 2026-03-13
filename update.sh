#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="/opt/dash-rpi"
SERVICE_NAME="dash-rpi.service"

if [ ! -d "$REPO_DIR/.git" ]; then
  echo "Erro: $REPO_DIR não parece ser um repositório git."
  exit 1
fi

BRANCH="$(git -C "$REPO_DIR" rev-parse --abbrev-ref HEAD)"

echo "[1/6] Atualizando repositório local..."
git -C "$REPO_DIR" pull --ff-only origin "$BRANCH"

echo "[2/6] Sincronizando arquivos para $APP_DIR ..."
sudo rsync -a --delete \
  --exclude ".git" \
  --exclude "app/node_modules" \
  --exclude ".env" \
  --exclude ".DS_Store" \
  "$REPO_DIR/" "$APP_DIR/"

echo "[3/6] Atualizando scripts auxiliares..."
sudo install -m 755 "$APP_DIR/service/dash-rpi-start.sh" /usr/local/bin/dash-rpi-start.sh
sudo install -m 755 "$APP_DIR/service/render-image.sh" /usr/local/bin/render-image.sh
sudo install -m 755 "$REPO_DIR/update.sh" /usr/local/bin/dash-rpi-update.sh

echo "[4/6] Instalando dependências Node..."
cd "$APP_DIR/app"
if [ -f package-lock.json ]; then
  sudo npm ci --omit=dev
else
  sudo npm install --omit=dev
fi

echo "[5/6] Recarregando systemd..."
sudo systemctl daemon-reload

echo "[6/6] Reiniciando serviço..."
sudo systemctl restart "$SERVICE_NAME"

echo
echo "Atualização concluída."
