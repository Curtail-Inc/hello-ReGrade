#!/usr/bin/env bash
# Drive demo traffic through the sensor proxy so ReGrade records it.
# In the walkthrough, TARGET is the sensor proxy; for a bare smoke test,
# point TARGET at the app directly (e.g. http://localhost:8001).
set -euo pipefail

TARGET="${TARGET:-http://localhost:19870}"

if ! curl -sf "${TARGET}/products" >/dev/null 2>&1; then
  echo "✗ Can't reach ${TARGET}." >&2
  echo "  Make sure the demo is up (docker compose up -d) and, for recording, the sensor proxy is running on that port." >&2
  exit 1
fi

echo "→ logging in at ${TARGET}"
TOKEN=$(curl -sSf -X POST "${TARGET}/login" \
  -H 'Content-Type: application/json' \
  -d '{"username":"demo","password":"demo"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["token"])')

echo "→ GET /products (public)"
curl -sSf "${TARGET}/products" >/dev/null

echo "→ GET /orders/1001 (authed) x3"
for _ in 1 2 3; do
  curl -sSf "${TARGET}/orders/1001" -H "Authorization: Bearer ${TOKEN}" >/dev/null
done

echo "✓ traffic complete"
