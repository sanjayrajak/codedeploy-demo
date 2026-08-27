#!/bin/bash
# AfterInstall — fix ownership and install the systemd service unit
set -euo pipefail

APP_DIR="/opt/helloapi"
SERVICE_FILE="/etc/systemd/system/helloapi.service"

echo "[set_permissions] Setting ownership on $APP_DIR..."
chown -R kestrel:kestrel "$APP_DIR"
find "$APP_DIR" -name "*.sh" -exec chmod +x {} \;
echo "[set_permissions] Permissions set."

# Install systemd unit if not already present or if updated
echo "[set_permissions] Installing systemd unit..."
cat > "$SERVICE_FILE" << 'UNIT'
[Unit]
Description=HelloApi .NET Kestrel Service
After=network.target

[Service]
User=kestrel
WorkingDirectory=/opt/helloapi
ExecStart=/usr/bin/dotnet /opt/helloapi/HelloApi.dll
Restart=on-failure
RestartSec=5
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=ASPNETCORE_URLS=http://0.0.0.0:5000

PrivateTmp=true
NoNewPrivileges=true
ProtectSystem=full

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable helloapi
echo "[set_permissions] systemd unit installed and enabled."
