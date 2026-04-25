#!/usr/bin/env bash
# Export all n8n workflows, produce raw (gitignored) and sanitized (committed) variants.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKFLOWS_DIR="$REPO_ROOT/workflows"
MAPPING_FILE="$SCRIPT_DIR/workflow_var_mapping.json"
CONTAINER="my-n8n"
CONTAINER_EXPORT_DIR="/tmp/n8n_export_in_container"

# --- Preflight checks ---
if ! docker ps --filter "name=^/${CONTAINER}$" --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  echo "ERROR: Container '${CONTAINER}' is not running. Start it with: docker compose up -d" >&2
  exit 1
fi

if [[ ! -f "$MAPPING_FILE" ]]; then
  echo "ERROR: $MAPPING_FILE not found." >&2
  echo "       Copy utils/workflow_var_mapping.example.json to utils/workflow_var_mapping.json and fill in real values." >&2
  exit 1
fi

mkdir -p "$WORKFLOWS_DIR"

# --- Export from container ---
EXPORT_DIR="$(mktemp -d -t n8n_export_XXXXXX)"
echo "Exporting workflows from container '${CONTAINER}'..."

docker exec "$CONTAINER" rm -rf "$CONTAINER_EXPORT_DIR"
docker exec "$CONTAINER" mkdir -p "$CONTAINER_EXPORT_DIR"
docker exec "$CONTAINER" n8n export:workflow --all --separate --output="$CONTAINER_EXPORT_DIR/"
docker cp "${CONTAINER}:${CONTAINER_EXPORT_DIR}/." "$EXPORT_DIR/"
docker exec "$CONTAINER" rm -rf "$CONTAINER_EXPORT_DIR"

JSON_FILES=("$EXPORT_DIR"/*.json)
if [[ ! -e "${JSON_FILES[0]}" ]]; then
  echo "ERROR: No JSON files found in export. Is n8n running and do workflows exist?" >&2
  rm -rf "$EXPORT_DIR"
  exit 1
fi

# --- Produce raw + sanitized files ---
COUNT=0
for src in "$EXPORT_DIR"/*.json; do
  base="$(basename "$src" .json)"

  # Raw copy (gitignored)
  cp "$src" "$WORKFLOWS_DIR/${base}_raw.json"

  # Sanitized version
  sanitized_path="$WORKFLOWS_DIR/${base}.json"
  if ! python3 "$SCRIPT_DIR/sanitize_workflow.py" "$src" > "$sanitized_path" 2>/tmp/sanitize_stderr_$$; then
    echo "ERROR: sanitize_workflow.py failed for $src" >&2
    echo "       Temp export dir preserved at: $EXPORT_DIR" >&2
    cat /tmp/sanitize_stderr_$$ >&2
    rm -f /tmp/sanitize_stderr_$$
    exit 1
  fi
  cat /tmp/sanitize_stderr_$$ >&2
  rm -f /tmp/sanitize_stderr_$$

  COUNT=$((COUNT + 1))
done

rm -rf "$EXPORT_DIR"
echo ""
echo "Done: exported $COUNT workflow(s)."
echo "  Raw (gitignored): $WORKFLOWS_DIR/*_raw.json"
echo "  Sanitized:        $WORKFLOWS_DIR/*.json  (excluding *_raw.json)"
