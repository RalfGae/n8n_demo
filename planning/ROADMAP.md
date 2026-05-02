# Roadmap

Legend: ✅ Done · 🔄 Open · ❌ Cancelled

---

## Phases

| Phase | Status | Description | Notes |
|-------|--------|-------------|-------|
| 0 | ✅ | Workflow versioning — sanitize pipeline for safe git commits | |
| 1 | ✅ | Vision-based extraction via GPT-4.1-mini, JPG input | Replaced Tesseract OCR pipeline |
| 2 | ✅ | PDF→JPEG conversion via separate pdf-converter container | Separate container after 3 failed attempts to extend n8n image |
| 2.5 | ❌ | Email PDF pipeline (text layer) | ~5% of receipts; handled manually for now (upload to Drive folder) |
| 3 | ✅ | Schema extension (deposits, discounts), receipt_id normalization, error handler | receipt_id = Google Drive file ID |
| 3.1 | 🔄 | Bulk Import stabilization — per-item LLM processing, receipt_id via prompt, Merge node removal | 2025 folder validated (~120 receipts); 2026 folder run pending |
| 3+ | 🔄 | Validator as Code Node, legacy cleanup, store matching fix | See open items below |
| 4 | 🔄 | PostgreSQL migration | Enables full-text search, joins, pgvector |
| 5 | 🔄 | Dashboard (Metabase or similar) | Depends on Phase 4 |

---

## Open Items

### Phase 3+

| Item | Status | Notes |
|------|--------|-------|
| Normalize discount/deposit sign | 🔄 | Model sometimes returns negative values for `discounts` and `deposits` (as printed on receipt). Decide convention and add `Math.abs()` normalization in Parse LLM output if positive-only is preferred. |
| Validator as Code Node | 🔄 | Rule: `subtotal + deposits - discounts == total_amount`. On mismatch: log or trigger error handler. Currently no validation in pipeline. |
| Consolidate legacy validators | 🔄 | `price_validator.py` and `receipt_price_check.py` are redundant. One has quantity support, the other does not. Delete once Code Node is in place. |
| Fix store matching | 🔄 | `get_store_tolerance('Rewe GmbH')` does not match `'REWE'`. Replace exact match with normalized substring match. |
| Clean up legacy scripts | 🔄 | `enhance_image*.py` (5 files) and `analyze_receipt_accuracy.py` unused since Tesseract era. `analyze_receipt_accuracy.py` also crashes (missing `datetime` import). |

### Phase 3.5

| Item | Status | Notes |
|------|--------|-------|
| Multi-page PDF handling | 🔄 | Currently first page only. REWE long receipts may span 2 pages. Workaround: scan as two separate files. Future: `?pages=all` or auto-stitch. |

### Phase 4

| Item | Status | Notes |
|------|--------|-------|
| PostgreSQL migration | 🔄 | Replace Google Sheets. Enables proper joins, full-text search, pgvector for product normalization. |
| Product normalization | 🔄 | LLM item names vary ("Kartoffeln 1kg", "Kart. 1 kg"). Option A: AI categorization (simple). Option B: embedding-based matching against product dictionary (accurate). |

### Phase 5

| Item | Status | Notes |
|------|--------|-------|
| Dashboard | 🔄 | Filter/insights by category, store, time period. Options: Metabase, Grafana, custom. Depends on Phase 4. |
