#!/usr/bin/env bash
# Import a workflow JSON into the running n8n container.
set -euo pipefail

CONTAINER="my-n8n"
CONTAINER_IMPORT_PATH="/tmp/workflow_to_import.json"

# --- Usage check ---
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <path-to-workflow.json>" >&2
  echo "  Example: $0 workflows/receipt_processor_v1_baseline.json" >&2
  exit 1
fi

WORKFLOW_FILE="$1"

if [[ ! -f "$WORKFLOW_FILE" ]]; then
  echo "ERROR: File not found: $WORKFLOW_FILE" >&2
  exit 1
fi

# --- Warn on raw import ---
if [[ "$WORKFLOW_FILE" == *_raw.json ]]; then
  echo "WARNING: You are importing a raw (unsanitized) workflow."
  echo "         This is fine locally but a raw file should never be committed. Proceed? (y/N)"
  read -r answer
  if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
  fi
fi

# --- Container check ---
if ! docker ps --filter "name=^/${CONTAINER}$" --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  echo "ERROR: Container '${CONTAINER}' is not running. Start it with: docker compose up -d" >&2
  exit 1
fi

# --- Import ---
echo "Importing $WORKFLOW_FILE into container '${CONTAINER}'..."
docker cp "$WORKFLOW_FILE" "${CONTAINER}:${CONTAINER_IMPORT_PATH}"
docker exec "$CONTAINER" n8n import:workflow --input="$CONTAINER_IMPORT_PATH"
docker exec "$CONTAINER" rm -f "$CONTAINER_IMPORT_PATH"

echo ""
echo "Workflow imported successfully."
echo "NOTE: For execution, ensure env vars in .env are set."
echo "      If .env changed since last start, restart the container: docker compose restart"
echo "      Credentials (Google Drive, OpenAI, Gmail, Google Sheets) must be mapped manually in the n8n UI."
