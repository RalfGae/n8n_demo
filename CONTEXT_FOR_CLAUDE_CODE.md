# Context for Claude Code Session

## Projekt-Ziel
Buchhaltung aus Kassenbelegen — nicht nur auf Einkaufs-, sondern auf Produkt-Ebene.
Filter/Einblicke: "Wofür habe ich Geld ausgegeben?" pro Kategorie/Produkt/Zeitraum.

## Aktuelle Pipeline
1. Kassenzettel werden via **Google Drive Scan-App** als PDF in Google Cloud abgelegt
2. n8n-Workflow (lokal, Docker) lädt PDF runter
3. OCR-Extraktion → AI-Strukturierung → (geplante) DB
4. Fallback: bei schlechter OCR-Qualität Vision-AI statt Text-OCR (teurer, daher Fallback)

## Architektur-Entscheidung (bereits getroffen)
- n8n läuft **lokal in Docker** (dieses Repo)
- Keine Claude Routines, keine VM-Provisionierung, kein Cloud-n8n
- Begründung: deterministische Datenpipeline mit State (DB) → n8n ist richtig, Routines wären Overhead

## Offene technische Frage: Poppler-Verhalten
User sagt "Poppler erkennt besser als Tesseract". Das ist technisch merkwürdig, weil
Poppler keine OCR-Engine ist. Zwei mögliche Erklärungen:
- **(A)** PDFs haben bereits Text-Layer (Drive-Scan hat OCR eingebettet) → `pdftotext` liest diesen
- **(B)** User nutzt `pdfimages`/`pdftoppm` um Bilder höherer Qualität rauszuholen → Tesseract läuft darauf

Drive-Scan auf iOS bettet OCR NICHT ins PDF ein (verifiziert). Android-Verhalten unklar.

**→ Erster Test den Claude Code machen soll:**
```bash
# Einen Beleg in das Repo legen und:
pdftotext <beleg>.pdf -        # Output prüfen: Text oder leer?
pdfimages -list <beleg>.pdf    # Welche Bilder sind eingebettet, welche DPI?
```

Ergebnis entscheidet, ob Tesseract-Pipeline ganz wegfällt oder bleibt.

## Issues im Repo (von vorheriger Review identifiziert)

### 🔴 Kritisch
- **Workflow-Logik nicht versioniert**: n8n-Workflows liegen nur in `n8n_data/database.sqlite`,
  nicht als JSON im Repo. Kein Git-Diff, kein Review, kein sauberes Rollback.
  → Fix: Workflows als JSON exportieren, in `workflows/`-Ordner committen.

### 🟠 Bugs/Logik
- **`scripts/analyze_receipt_accuracy.py`**: Nutzt `datetime.now()` ohne Import. Crasht.
- **Validierung ignoriert Pfand/Rabatte**: `price_validator.py` summiert Items und vergleicht
  mit Total. Bei REWE/EDEKA sind Pfand-Zeilen separat → künstliche Mismatches.
  → Fix: Extraktion auf `{items, subtotal, deposits, discounts, total}` erweitern.
  Validator: `subtotal + deposits - discounts == total`.
- **Zwei redundante Validatoren**: `price_validator.py` und `receipt_price_check.py`
  machen fast dasselbe, einer mit quantity einer ohne. Konsolidieren.
- **Store-Matching brittle**: `get_store_tolerance('Rewe GmbH')` matcht nicht `'REWE'`.
  Substring-Match statt exact match.

### 🟡 Aufräumen
- **5× `enhance_image*.py`**: Legacy aus Tesseract-Ära. Dockerfile installiert nicht mal
  Tesseract — nur poppler/python3/Pillow. Scripts vermutlich tot. Nach Poppler-Test
  entscheiden was bleibt.
- **Dockerfile**: n8n v2.1.4 ist von ~Dez 2025. Aktuell (April 2026) gibt's neuere
  2.x-Versionen. Nicht dringend aber beim nächsten Rebuild updaten.

### 🔒 Security (aus Release Notes)
- **CVE-2026-21877** (Code Injection) betrifft n8n ≤ 0.121.2. Version 2.1.4 ist
  vermutlich nicht betroffen, aber beim Upgrade im Auge behalten.

## Priorisierter Plan
1. **Workflow-JSON exportieren** → `workflows/`-Ordner (15 min, riesiger Hebel)
2. **Poppler-Test** mit echtem Beleg → entscheidet Pipeline-Form
3. **Extraktion erweitern** auf `{items, subtotal, deposits, discounts, total}`
4. **Validator konsolidieren**, Pfand/Rabatte berücksichtigen
5. **Enhance-Scripts aufräumen** (Legacy-Löschung nach Poppler-Test)
6. **Dann erst** DB-Schema für Persistenz + Filter/Einblicke-Ebene

## Was Claude Code noch braucht
- **Ein Beispiel-Beleg-PDF** (für Poppler-Test) — bitte vom User bereitstellen lassen
- **Aktuelles Workflow-JSON** (via n8n-UI exportieren, drei-Punkte-Menü → Download)
- **Beispiel-Output** des aktuellen AI-Extraktions-Steps (JSON, das in Validator fließt)

## Nicht diskutierte Themen (für später)
- DB-Wahl: SQLite → PostgreSQL (für Full-Text + evtl. pgvector-Embeddings bei Produkt-Normalisierung)
- Produkt-Normalisierung: AI-Kategorisierung (einfach) vs. Embedding-Matching (komplexer)
- Frontend für Filter/Einblicke: Metabase/Grafana vs. eigenes
