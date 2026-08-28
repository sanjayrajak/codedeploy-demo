#!/bin/bash
# ApplicationStart — start Kestrel, then restore this instance in HAProxy
set -euo pipefail

SERVICE="helloapi"
HAPROXY_SOCK="/run/haproxy/admin.sock"

# ---------------------------------------------------------------
# Start the Kestrel service
# ---------------------------------------------------------------
echo "[start_service] Reloading systemd and starting $SERVICE..."
systemctl daemon-reload
systemctl enable "$SERVICE"
systemctl start "$SERVICE"
echo "[start_service] $SERVICE started."

# ---------------------------------------------------------------
# Wait for /health to return 200 before restoring in HAProxy
# ---------------------------------------------------------------
MAX_RETRIES=12
SLEEP_SECS=5
echo "[start_service] Waiting for /health to be ready before restoring HAProxy..."

for i in $(seq 1 "$MAX_RETRIES"); do
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/health || true)
    if [ "$HTTP_STATUS" = "200" ]; then
        echo "[start_service] Health check passed (attempt $i)."
        break
    fi
    echo "[start_service] Attempt $i/$MAX_RETRIES — HTTP $HTTP_STATUS, waiting ${SLEEP_SECS}s..."
    sleep "$SLEEP_SECS"
done

# ---------------------------------------------------------------
# Restore this server in HAProxy (remove MAINT, set back to READY)
# ---------------------------------------------------------------
MY_IP=$(curl -s --max-time 3 http://169.254.169.254/latest/meta-data/local-ipv4 || true)

if [ -S "$HAPROXY_SOCK" ]; then
    SERVER_NAME=$(echo "show servers state api_servers" | socat stdio "$HAPROXY_SOCK" 2>/dev/null \
        | awk -v ip="$MY_IP" '$4 == ip {print $2}' | head -1 || true)

    if [ -n "$SERVER_NAME" ]; then
        echo "[start_service] Restoring HAProxy server api_servers/$SERVER_NAME to READY..."
        echo "set server api_servers/$SERVER_NAME state ready" | socat stdio "$HAPROXY_SOCK"
        echo "[start_service] Server restored in HAProxy."
    else
        echo "[start_service] Could not find server in HAProxy — HAProxy health checks will restore it automatically."
    fi
else
    echo "[start_service] HAProxy socket not found — HAProxy health checks will restore automatically."
fi
