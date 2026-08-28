#!/bin/bash
# ApplicationStop — drain this instance from HAProxy, then stop Kestrel
set -euo pipefail

SERVICE="helloapi"
HAPROXY_SOCK="/run/haproxy/admin.sock"

# ---------------------------------------------------------------
# Determine which backend server name this instance is in HAProxy.
# HAProxy config names servers api1, api2 etc by private IP.
# ---------------------------------------------------------------
MY_IP=$(curl -s --max-time 3 http://169.254.169.254/latest/meta-data/local-ipv4 || true)
echo "[stop_service] My private IP: $MY_IP"

# ---------------------------------------------------------------
# Drain this server in HAProxy (if HAProxy socket is reachable)
# Sets server to MAINT mode — HAProxy stops sending new requests
# and drains existing connections gracefully
# ---------------------------------------------------------------
if [ -S "$HAPROXY_SOCK" ]; then
    # Find the server name matching our IP
    SERVER_NAME=$(echo "show servers state api_servers" | socat stdio "$HAPROXY_SOCK" 2>/dev/null \
        | awk -v ip="$MY_IP" '$4 == ip {print $2}' | head -1 || true)

    if [ -n "$SERVER_NAME" ]; then
        echo "[stop_service] Setting HAProxy server api_servers/$SERVER_NAME to MAINT (draining)..."
        echo "set server api_servers/$SERVER_NAME state maint" | socat stdio "$HAPROXY_SOCK"
        echo "[stop_service] Waiting 10s for connections to drain..."
        sleep 10
        echo "[stop_service] Server drained."
    else
        echo "[stop_service] Could not find server in HAProxy — skipping drain."
    fi
else
    echo "[stop_service] HAProxy socket not found at $HAPROXY_SOCK — skipping drain."
    echo "[stop_service] (This is normal if HAProxy is on a separate instance)"
fi

# ---------------------------------------------------------------
# Stop the Kestrel service
# ---------------------------------------------------------------
if systemctl is-active --quiet "$SERVICE"; then
    echo "[stop_service] Stopping $SERVICE..."
    systemctl stop "$SERVICE"
    echo "[stop_service] $SERVICE stopped."
else
    echo "[stop_service] $SERVICE was not running — nothing to stop."
fi
