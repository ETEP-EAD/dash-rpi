#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="/opt/dash-rpi"
SERVICE_NAME="dash-rpi.service"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}"
ENV_DIR="/etc/dash-rpi"
DATA_DIR="/var/lib/dash-rpi"
IMAGE_DIR="${DATA_DIR}/images"
LOG_DIR="/var/log/dash-rpi"
SOURCE_FILE="/etc/dash-rpi/source.conf"
BOOT_CONFIG="/boot/config.txt"

ensure_line_in_file() {
  local line="$1"
  local file="$2"

  sudo touch "$file"

  if ! grep -qxF "$line" "$file"; then
    echo "$line" | sudo tee -a "$file" >/dev/null
  fi
}

echo "[1/10] Instalando dependências..."
sudo apt-get update
sudo apt-get install -y \
  git \
  rsync \
  curl \
  ca-certificates \
  fbset \
  fbi \
  nodejs \
  npm

echo "[2/10] Criando diretórios..."
sudo mkdir -p "$APP_DIR" "$ENV_DIR" "$DATA_DIR" "$IMAGE_DIR" "$LOG_DIR"

echo "[3/10] Registrando caminho do repositório de origem..."
echo "SOURCE_REPO_DIR=$REPO_DIR" | sudo tee "$SOURCE_FILE" >/dev/null

echo "[4/10] Copiando aplicação para $APP_DIR ..."
sudo rsync -a --delete \
  --exclude ".git" \
  --exclude "app/node_modules" \
  --exclude ".env" \
  --exclude ".DS_Store" \
  "$REPO_DIR/" "$APP_DIR/"

echo "[5/10] Instalando dependências Node..."
cd "$APP_DIR/app"
if [ -f package-lock.json ]; then
  sudo npm ci --omit=dev
else
  sudo npm install --omit=dev
fi

echo "[6/10] Instalando arquivos auxiliares..."
sudo install -m 755 "$APP_DIR/service/dash-rpi-start.sh" /usr/local/bin/dash-rpi-start.sh
sudo install -m 755 "$APP_DIR/service/render-image.sh" /usr/local/bin/render-image.sh
sudo install -m 755 "$REPO_DIR/update.sh" /usr/local/bin/dash-rpi-update.sh

echo "[7/10] Instalando service..."
sudo install -m 644 "$APP_DIR/service/dash-rpi.service" "$SERVICE_FILE"

echo "[8/10] Criando arquivo de ambiente..."
if [ ! -f "$ENV_DIR/env" ]; then
  sudo cp "$APP_DIR/config/env.example" "$ENV_DIR/env"
fi

echo "[9/10] Configurando HDMI..."
ensure_line_in_file "hdmi_force_hotplug=1" "$BOOT_CONFIG"
ensure_line_in_file "hdmi_group=2" "$BOOT_CONFIG"
ensure_line_in_file "hdmi_mode=82" "$BOOT_CONFIG"

echo "[10/10] Habilitando serviço..."
sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME"
sudo systemctl restart "$SERVICE_NAME"

echo
echo "Instalação concluída."
echo
echo "Edite a configuração em:"
echo "  sudo nano /etc/dash-rpi/env"
echo
echo "Logs do serviço:"
echo "  journalctl -u ${SERVICE_NAME} -f"
echo
echo "Pode ser necessário reiniciar o Raspberry Pi para garantir HDMI ativa:"
echo "  sudo reboot"
