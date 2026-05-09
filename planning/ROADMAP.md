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
| 3.1 | ✅ | Bulk Import stabilization — per-item LLM processing, receipt_id via prompt, Merge node removal | 2025 (~120 receipts) + 2026 (~93 receipts) validated; maxTokens 16384, 1s batch delay |
| 3+ | 🔄 | Validator as Code Node, legacy cleanup, store matching fix | See open items below |
| 4 | 🔄 | PostgreSQL migration | Enables full-text search, joins, pgvector |
| 5 | 🔄 | Dashboard (Metabase or similar) | Depends on Phase 4 |

---

## Open Items

### Phase 3+

| Item | Status | Notes |
|------|--------|-------|
| Sync Non-Bulk WF to current standard | ✅ | maxTokens 4096→16384, model gpt-4.1-mini→gpt-5.4-mini (WF: QOlE6hpQyNm2RUIj). Architecture (Structured Output Parser + receipt_id via Drive Trigger) stays unchanged. |
| Normalize discount/deposit sign | 🔄 | Model sometimes returns negative values for `discounts` and `deposits` (as printed on receipt). Decide convention and add `Math.abs()` normalization in Parse LLM output if positive-only is preferred. |
| Validator as Code Node | 🔄 | Rule: `subtotal + deposits - discounts == total_amount`. On mismatch: log or trigger error handler. Currently no validation in pipeline. |
| Consolidate legacy validators | 🔄 | `price_validator.py` and `receipt_price_check.py` are redundant. One has quantity support, the other does not. Delete once Code Node is in place. |
| Fix store matching | 🔄 | `get_store_tolerance('Rewe GmbH')` does not match `'REWE'`. Replace exact match with normalized substring match. |
| Clean up legacy scripts | 🔄 | `enhance_image*.py` (5 files) and `analyze_receipt_accuracy.py` unused since Tesseract era. `analyze_receipt_accuracy.py` also crashes (missing `datetime` import). |
| Workflow Testing Skill | 🔄 | Claude Code skill for targeted re-testing of individual receipts via Non-Bulk WF: load anomalies from GSheet, trigger by Drive file ID, compare output against expected values, suggest prompt/workflow fixes. Prerequisite: Non-Bulk WF stable + n8n API trigger clarified. |

### Known data anomalies (manual review)

**2026 folder — flagged items:**

| receipt_id | Date | Store | Issue |
|------------|------|-------|-------|
| `1eneIx6Z…` + `1cUZIQRp…` | 30.04.2026 | SB-Tankstelle | Duplicate — same receipt (€46,18 Diesel) as two Drive files |
| `138Uiu8z…` + `1ml0JxeD…` | 18.02.2026 | REWE | Duplicate — same receipt (€8,96) as two Drive files |
| `1Vo2C6m1…` | 14.01.**2025** | Kaufland | Wrong year — 2025 receipt in 2026 folder |
| `1GO08nsB…` | 27.01.**2025** | Kaufland | Wrong year — 2025 receipt in 2026 folder |
| `105blDwK…` | 21.02.**2025** | Kaufland | Wrong year — 2025 receipt in 2026 folder |
| `18nGEdPk…` | 17.02.**2025** | IKEA | Wrong year — 2025 receipt in 2026 folder |
| `1ZvWafdx…` | 19.01.**2025** | EDEKA | Wrong year — 2025 receipt in 2026 folder |
| `1qrnLdoA…` | — | Markt-Bäckerei | Confidence=1, total=0 — receipt unreadable |
| `13_pNvin…` | 29.01.2026 | HORNBACH | subtotal=13,36 inconsistent (total=29,80, tax=2,54; net≈27,26); items list likely incomplete |
| `1Nu4Qwe8…` | — | Udemy | discounts=789 (original discount shown on invoice, not a real deduction) |
| `1u2dESp1…` | — | PMI | USD, total=0 — digital receipt unreadable |
| `1jZdisn9…` | 24.01.2026 | Aesparel | total=0 — zero-amount order confirmation |

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
