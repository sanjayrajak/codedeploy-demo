#!/bin/bash
# BeforeInstall — wipe the old deployment so no stale files linger
set -euo pipefail

APP_DIR="/opt/helloapi"

echo "[clean_old_files] Cleaning $APP_DIR..."
rm -rf "${APP_DIR:?}"/*
echo "[clean_old_files] Clean complete."
