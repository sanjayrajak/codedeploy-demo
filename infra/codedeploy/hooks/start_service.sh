#!/bin/bash
# ApplicationStart — enable and start the Kestrel service
set -euo pipefail

SERVICE="helloapi"

echo "[start_service] Reloading systemd and starting $SERVICE..."
systemctl daemon-reload
systemctl enable "$SERVICE"
systemctl start "$SERVICE"
echo "[start_service] $SERVICE started."
