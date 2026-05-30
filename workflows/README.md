# Workflows

Sanitized n8n workflow exports. Sensitive values (folder IDs, sheet IDs, email addresses)
are replaced with `={{ $env.VAR_NAME }}` expressions — n8n resolves these at runtime.

Raw exports (`*_raw.json`) contain real values and are excluded from commits via `.gitignore`.

## Development workflow

1. Make changes in the n8n UI
2. Run `./utils/export_workflows.sh`
   → produces `workflows/<name>_raw.json` (raw, gitignored) and `workflows/<name>.json` (sanitized)
3. Check `git diff workflows/*.json` — only the sanitized files should show changes
4. Commit only the sanitized files (`_raw.json` files are excluded automatically)

## Setup in a new environment

```bash
# 1. Create the mapping file
cp utils/workflow_var_mapping.example.json utils/workflow_var_mapping.json
# → Fill in the values in workflow_var_mapping.json (folder IDs, sheet IDs, etc.)

# 2. Create .env
cp .env.example .env
# → Fill in API keys and N8N_* variables in .env

# 3. Start the container
docker compose up -d

# 4. Import a workflow
./utils/import_workflow.sh workflows/receipt_processor_v1_baseline.json
```

After import, credentials must be mapped manually in the n8n UI:
Google Drive, OpenAI, Gmail, Google Sheets.

## Files

| File | Status | Contents |
|---|---|---|
| `*_raw.json` | gitignored | Original export with real values |
| `*.json` (without `_raw`) | committed | Sanitized export with `$env` expressions |
