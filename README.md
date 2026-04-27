# n8n Receipt Processor

Personal accounting pipeline that extracts structured data from receipts using vision AI and writes it to Google Sheets.

| Phase | Status | Description |
|-------|--------|-------------|
| 0 | ✅ | Workflow versioning — sanitize pipeline |
| 1 | ✅ | Vision-based extraction via GPT-4.1-mini, JPG input |
| 2 | ✅ | PDF→JPEG conversion via pdf-converter container |
| 2.5 | ❌ | Email PDF pipeline — cancelled, handled manually |
| 3 | ✅ | Schema extension, receipt_id normalization, error handler |
| 3+ | 🔄 | Validator as Code Node, legacy cleanup |
| 4 | 🔄 | PostgreSQL migration |
| 5 | 🔄 | Dashboard |

→ Details: [planning/ROADMAP.md](planning/ROADMAP.md)

## How it works

1. Upload a receipt photo (JPG) or scan (PDF) to a Google Drive folder
2. n8n detects the new file via Drive Trigger
3. PDFs are converted to JPEG by a local pdf-converter service
4. GPT-4.1-mini extracts structured data from the image
5. Data is written to two Google Sheets tabs: Gesamtposten (receipt-level) and Einzelposten (item-level)
6. Gmail notification is sent on success; error notification on failure

## Architecture

```
Google Drive Trigger
  → Download file
  → IF mimeType == application/pdf
      true  → pdf-converter (POST /convert) → Basic LLM Chain
      false → Basic LLM Chain (JPG, direct)
  → Set receipt_id + flatten fields
  → Append receipt in sheet (Gesamtposten)
  → Append items in sheet (Einzelposten)
  → Send Gmail notification
```

Two Docker services:
- **n8n** — workflow engine (port 5678)
- **pdf-converter** — local poppler-based PDF→JPEG service (internal only)

## Setup

### 1. Clone and configure environment

```bash
cp .env.example .env
```

Edit `.env` and fill in:
- `OPENAI_API_KEY`
- `N8N_DRIVE_FOLDER_ID_UNSORTIERT`
- `N8N_SHEET_RECHNUNGEN_ID`
- `N8N_SHEET_EINZELPOSTEN_GID`
- `N8N_SHEET_GESAMTPOSTEN_GID`
- `N8N_NOTIFICATION_EMAIL`

### 2. Start services

```bash
docker compose up --build -d
```

### 3. Import workflow

```bash
cp utils/workflow_var_mapping.example.json utils/workflow_var_mapping.json
# Fill in real values in workflow_var_mapping.json (gitignored)
./utils/import_workflow.sh workflows/QOlE6hpQyNm2RUIj.json
```

Open n8n at http://localhost:5678, activate the workflow and the Error Handler.

## Workflow versioning

Workflows are exported as sanitized JSON (sensitive IDs replaced with `$env` references).

```bash
# Export all workflows from running n8n container
./utils/export_workflows.sh

# Import a specific workflow
./utils/import_workflow.sh workflows/<id>.json
```

Raw exports (`*_raw.json`) are gitignored. Only sanitized versions are committed.

## Google Sheets schema

**Gesamtposten** (one row per receipt):
`receipt_id` · `date` · `store` · `currency` · `total_amount` · `tax_amount` · `subtotal` · `deposits` · `discounts`

**Einzelposten** (one row per item):
`receipt_id` · `category` · `name` · `price` · `quantity`

`receipt_id` is the Google Drive file ID — use it to join the two sheets and to navigate back to the original file.

**Language convention:** item names are always translated to English regardless of the receipt language (German, Asian scripts, etc.). Categories use a controlled English vocabulary (Food, Beverage, Household, etc.).

## pdf-converter service

Converts PDF pages to JPEG using poppler-utils. Internal service, not exposed outside the Docker network.

```
POST http://pdf-converter:8000/convert
  Content-Type: multipart/form-data
  file: <PDF binary>
  ?page=1  (optional, default: 1)

→ 200 image/jpeg
→ 400/500 application/json { "error": "..." }
```

Smoke test (requires service running):
```bash
./pdf-converter/smoke_test.sh test_samples/your_receipt.pdf
```

## Backup & Restore

```bash
# Backup
./utils/backup_n8n.sh

# Restore with automatic system backup
./utils/restore_n8n.sh backups/n8n_backup_YYYYMMDD_HHMMSS.tar.gz --test-and-replace
```

## Project phases

| Phase | Status | Description |
|-------|--------|-------------|
| 0 | Done | Workflow versioning — sanitize pipeline for safe git commits |
| 1 | Done | Vision-based extraction via GPT-4.1-mini, JPG input |
| 2 | Done | PDF→JPEG conversion via separate pdf-converter container |
| 3 | Done | Schema extension (deposits, discounts), receipt_id normalization, error handler |
| 3+ | Planned | PostgreSQL, validator as Code Node |
| 4 | Planned | Dashboard (Metabase or similar) |

## Directory structure

```
n8n_demo/
├── docker-compose.yml          # n8n + pdf-converter services
├── Dockerfile                  # n8n image (slot for future tweaks)
├── pdf-converter/              # PDF→JPEG microservice
│   ├── app.py
│   ├── Dockerfile
│   ├── requirements.txt
│   └── smoke_test.sh
├── workflows/                  # Sanitized workflow exports
├── utils/                      # Export, import, backup, restore scripts
├── scripts/                    # Legacy Python scripts (Tesseract era)
├── logs/                       # Runtime logs (gitignored)
├── n8n_data/                   # n8n persistent data (gitignored)
├── my-files/                   # File storage for workflows (gitignored)
├── backups/                    # Backup archives (gitignored)
└── test_samples/               # Test receipts (gitignored)
```
