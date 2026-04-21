#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="dash-rpi.service"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}"
APP_DIR="/opt/dash-rpi"
ENV_DIR="/etc/dash-rpi"
DATA_DIR="/var/lib/dash-rpi"
LOG_DIR="/var/log/dash-rpi"

echo "========================================"
echo "  Dash RPi - Uninstall"
echo "========================================"
echo

# --- parar serviço ---
echo "[1/6] Parando serviço..."
if systemctl is-active --quiet "$SERVICE_NAME"; then
  sudo systemctl stop "$SERVICE_NAME"
fi

# --- desabilitar serviço ---
echo "[2/6] Desabilitando serviço..."
if systemctl is-enabled --quiet "$SERVICE_NAME"; then
  sudo systemctl disable "$SERVICE_NAME"
fi

# --- remover service ---
echo "[3/6] Removendo service..."
if [ -f "$SERVICE_FILE" ]; then
  sudo rm -f "$SERVICE_FILE"
  sudo systemctl daemon-reload
fi

# --- remover scripts ---
echo "[4/6] Removendo scripts auxiliares..."
sudo rm -f /usr/local/bin/dash-rpi-start.sh
sudo rm -f /usr/local/bin/render-image.sh
sudo rm -f /usr/local/bin/dash-rpi-update.sh

# --- confirmar remoção de dados ---
echo
read -p "Deseja remover TODOS os dados e aplicação? (y/N): " CONFIRM

if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "[5/6] Removendo diretórios..."

  sudo rm -rf "$APP_DIR"
  sudo rm -rf "$ENV_DIR"
  sudo rm -rf "$DATA_DIR"
  sudo rm -rf "$LOG_DIR"

  echo "✔ Dados removidos."
else
  echo "[5/6] Dados preservados."
fi

# --- opcional: reativar getty ---
echo "[6/6] Restaurando login na tela (tty1)..."
sudo systemctl enable getty@tty1 || true
sudo systemctl start getty@tty1 || true

echo
echo "Uninstall concluído."
echo

echo "Se quiser remover dependências instaladas (opcional):"
echo "  sudo apt remove --purge -y fbi fbset nodejs npm"
echo "  sudo apt autoremove -y"
