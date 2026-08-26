#!/bin/bash
# ValidateService — poll /health until it returns 200 or timeout
set -euo pipefail

HEALTH_URL="http://localhost:5000/health"
MAX_RETRIES=12      # 12 × 5s = 60s total
SLEEP_SECS=5

echo "[validate_health] Polling $HEALTH_URL (max ${MAX_RETRIES} attempts, ${SLEEP_SECS}s apart)..."

for i in $(seq 1 "$MAX_RETRIES"); do
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_URL" || true)

    if [ "$HTTP_STATUS" = "200" ]; then
        echo "[validate_health] Health check passed (attempt $i) — HTTP $HTTP_STATUS"
        exit 0
    fi

    echo "[validate_health] Attempt $i/$MAX_RETRIES — got HTTP $HTTP_STATUS, retrying in ${SLEEP_SECS}s..."
    sleep "$SLEEP_SECS"
done

echo "[validate_health] FAILED: /health did not return 200 after $MAX_RETRIES attempts."
echo "[validate_health] CodeDeploy will trigger automatic rollback."
exit 1
