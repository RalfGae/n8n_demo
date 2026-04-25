# Workflows

Sanitisierte n8n-Workflow-Exports. Sensible Werte (Folder-IDs, Sheet-IDs, E-Mail-Adressen)
sind durch `={{ $env.VAR_NAME }}` Expressions ersetzt — n8n löst diese zur Laufzeit auf.

Rohe Exports (`*_raw.json`) enthalten echte Werte und sind via `.gitignore` vom Commit ausgeschlossen.

## Entwicklungsworkflow

1. Änderungen in der n8n-UI machen
2. `./utils/export_workflows.sh` ausführen
   → erzeugt `workflows/<name>_raw.json` (roh, gitignored) und `workflows/<name>.json` (sanitisiert)
3. `git diff workflows/*.json` prüfen — nur die sanitisierten Dateien sollten Änderungen zeigen
4. Nur die sanitisierten Dateien committen (die `_raw.json` sind automatisch ausgeschlossen)

## Setup in neuer Umgebung

```bash
# 1. Mapping-Datei anlegen
cp utils/workflow_var_mapping.example.json utils/workflow_var_mapping.json
# → Werte in workflow_var_mapping.json eintragen (Folder-IDs, Sheet-IDs etc.)

# 2. .env anlegen
cp .env.example .env
# → API-Keys und die N8N_*-Variablen in .env eintragen

# 3. Container starten
docker compose up -d

# 4. Workflow importieren
./utils/import_workflow.sh workflows/receipt_processor_v1_baseline.json
```

Nach dem Import müssen Credentials in der n8n-UI manuell gemappt werden:
Google Drive, OpenAI, Gmail, Google Sheets.

## Dateien

| Datei | Status | Inhalt |
|---|---|---|
| `*_raw.json` | gitignored | Original-Export mit echten Werten |
| `*.json` (ohne `_raw`) | committed | Sanitisierter Export mit `$env`-Expressions |
