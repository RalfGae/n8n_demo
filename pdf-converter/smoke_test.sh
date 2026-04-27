#!/usr/bin/env bash
# Smoke test for pdf-converter service.
# Usage: ./smoke_test.sh [path/to/test.pdf]
# Expects the service to be reachable at localhost:8000.
set -euo pipefail

BASE_URL="${PDF_CONVERTER_URL:-http://localhost:8000}"
TEST_PDF="${1:-}"

echo "--- Health check ---"
curl -sf "$BASE_URL/health" | grep -q '"ok"' && echo "OK" || { echo "FAIL"; exit 1; }

if [[ -z "$TEST_PDF" ]]; then
  echo ""
  echo "No PDF provided — skipping conversion test."
  echo "Usage: $0 path/to/test.pdf"
  exit 0
fi

if [[ ! -f "$TEST_PDF" ]]; then
  echo "ERROR: file not found: $TEST_PDF" >&2
  exit 1
fi

echo ""
echo "--- Conversion test ($TEST_PDF) ---"
OUT=$(mktemp /tmp/smoke_out_XXXXXX.jpg)
HTTP_STATUS=$(curl -s -o "$OUT" -w "%{http_code}" \
  -X POST "$BASE_URL/convert" \
  -F "file=@$TEST_PDF")

if [[ "$HTTP_STATUS" != "200" ]]; then
  echo "FAIL — HTTP $HTTP_STATUS"
  cat "$OUT"
  rm -f "$OUT"
  exit 1
fi

MIME=$(file --mime-type -b "$OUT")
if [[ "$MIME" != "image/jpeg" ]]; then
  echo "FAIL — expected image/jpeg, got $MIME"
  rm -f "$OUT"
  exit 1
fi

SIZE=$(wc -c < "$OUT")
echo "OK — JPEG, ${SIZE} bytes → $OUT"
