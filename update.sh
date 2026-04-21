#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="/opt/dash-rpi"
SERVICE_NAME="dash-rpi.service"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}"

if [ ! -d "$REPO_DIR/.git" ]; then
  echo "Erro: $REPO_DIR não parece ser um repositório git."
  exit 1
fi

BRANCH="$(git -C "$REPO_DIR" rev-parse --abbrev-ref HEAD)"

echo "[1/7] Atualizando repositório local..."
git -C "$REPO_DIR" fetch origin
git -C "$REPO_DIR" reset --hard "origin/$BRANCH"

echo "[2/7] Sincronizando arquivos para $APP_DIR ..."
sudo rsync -a --delete \
  --exclude ".git" \
  --exclude "app/node_modules" \
  --exclude ".env" \
  --exclude ".DS_Store" \
  "$REPO_DIR/" "$APP_DIR/"

echo "[3/7] Atualizando scripts auxiliares..."
sudo install -m 755 "$APP_DIR/service/dash-rpi-start.sh" /usr/local/bin/dash-rpi-start.sh
sudo install -m 755 "$REPO_DIR/update.sh" /usr/local/bin/dash-rpi-update.sh

echo "[4/7] Atualizando service..."
sudo install -m 644 "$APP_DIR/service/${SERVICE_NAME}" "$SERVICE_FILE"

echo "[5/7] Instalando dependências Node..."
cd "$APP_DIR/app"

if [ -f package-lock.json ]; then
  sudo npm ci --omit=dev --no-audit --no-fund
else
  sudo npm install --omit=dev --no-audit --no-fund
fi

echo "[6/7] Recarregando systemd..."
sudo systemctl daemon-reload

echo "[7/7] Reiniciando serviço..."
sudo systemctl restart "$SERVICE_NAME"

echo
echo "Atualização concluída."
