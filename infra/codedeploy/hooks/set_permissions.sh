#!/bin/bash
# AfterInstall — fix ownership after CodeDeploy copies files
set -euo pipefail

APP_DIR="/opt/helloapi"

echo "[set_permissions] Setting ownership on $APP_DIR..."
chown -R kestrel:kestrel "$APP_DIR"
find "$APP_DIR" -name "*.sh" -exec chmod +x {} \;
echo "[set_permissions] Permissions set."
