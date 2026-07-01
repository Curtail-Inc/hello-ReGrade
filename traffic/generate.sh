#!/usr/bin/env bash
# Drive demo traffic through the sensor proxy so ReGrade records it.
# In the walkthrough, TARGET is the sensor proxy; for a bare smoke test,
# point TARGET at the app directly (e.g. http://localhost:8001).
set -euo pipefail

TARGET="${TARGET:-http://localhost:19870}"

echo "→ logging in at ${TARGET}"
TOKEN=$(curl -sf -X POST "${TARGET}/login" \
  -H 'Content-Type: application/json' \
  -d '{"username":"demo","password":"demo"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["token"])')

echo "→ GET /products (public)"
curl -sf "${TARGET}/products" >/dev/null

echo "→ GET /orders/1001 (authed) x3"
for _ in 1 2 3; do
  curl -sf "${TARGET}/orders/1001" -H "Authorization: Bearer ${TOKEN}" >/dev/null
done

echo "✓ traffic complete"
