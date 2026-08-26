#!/bin/bash
# ApplicationStop — gracefully stop the Kestrel service before deploying
set -euo pipefail

SERVICE="helloapi"

echo "[stop_service] Checking if $SERVICE is running..."

if systemctl is-active --quiet "$SERVICE"; then
    echo "[stop_service] Stopping $SERVICE..."
    systemctl stop "$SERVICE"
    echo "[stop_service] $SERVICE stopped."
else
    echo "[stop_service] $SERVICE was not running — nothing to stop."
fi
