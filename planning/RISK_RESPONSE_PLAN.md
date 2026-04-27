# Risk Response Plan

## Problem: Incorrect extraction written to sheet unnoticed

The workflow writes data to the sheet on success and sends a success email.
If the LLM extracts wrong values (incorrect total, wrong store name, missing items),
there is currently no automatic detection — the error only surfaces during manual sheet review.

**Frequency:** unknown, likely rare but non-zero.
**Impact:** incorrect accounting data with no easy correction path.

---

## Ideas (unranked)

### Idea 1 — Attach receipt image to success email
**What:** Include the converted JPEG (or a thumbnail) alongside the extracted values
in the success email. User sees image + output side by side.

**Pro:** No new system needed, immediately implementable.
**Con:** Requires manual review of every email. Does not scale.
**Effort:** Low — attach binary from workflow to Gmail node.

---

### Idea 2 — Rule-based validation in workflow (Validator Node)
**What:** After the LLM Chain, check whether `subtotal + deposits - discounts ≈ total_amount`.
On deviation beyond tolerance: trigger error handler instead of writing to sheet.

**Pro:** Automatically catches the most common error class (amount mismatch).
**Con:** Does not detect wrong store names, missing items, or incorrect categories.
**Effort:** Medium — Code Node in workflow. Already planned in roadmap as "Validator as Code Node".

---

### Idea 3 — LLM returns confidence score
**What:** Extend prompt: LLM also outputs `confidence: low/medium/high`.
On `low`: skip sheet write, flag for manual review instead.

**Pro:** LLM is aware of its own uncertainty (illegible handwriting, poor scan quality).
**Con:** LLM self-assessment is unreliable — hallucinations can come with `confidence: high`.
**Effort:** Low — extend schema and prompt.

---

### Idea 4 — Second-opinion LLM (verification step)
**What:** After the first extraction, a second LLM call with image + extracted data:
"Do these values match the image? Answer with ok/mismatch + reason."

**Pro:** Independent verification, reliably catches gross errors.
**Con:** Double API cost per receipt. At 50 receipts/month minimal (~$0.05/month extra).
**Effort:** Medium — second LLM Chain node, IF on ok/mismatch.

---

### Idea 5 — Reply-to-email as correction trigger
**What:** Success email with a reply-to address. User replies with "wrong" or "correct X".
n8n polls Gmail inbox, detects replies to success emails (via thread ID),
triggers a correction workflow.

**Pro:** Intuitive UX — react directly from the email.
**Con:** Complex. Requires Gmail polling, thread matching, NLU of the reply.
**Effort:** High. Phase 5+ territory.

---

### Idea 6 — Quarantine tab instead of direct sheet write
**What:** Extraction lands first in a "Pending" tab in the sheet (or a separate sheet).
User reviews daily/weekly and moves correct entries to the main tab
(or confirms via checkbox).

**Pro:** Full control, no incorrect entry in the main sheet.
**Con:** Manual review step for every receipt. High operational overhead.
**Effort:** Low to implement, high to operate.

---

## Recommended priority (by effort/value)

| Priority | Idea | When |
|----------|------|------|
| 1 | Rule-based validation (Idea 2) | Phase 3+ — already planned |
| 2 | Attach receipt image to success email (Idea 1) | Short-term, low effort |
| 3 | Confidence score (Idea 3) | Alongside Idea 1, low barrier |
| 4 | Second-opinion LLM (Idea 4) | If error rate proves significant |
| 5 | Reply-to-email trigger (Idea 5) | Phase 5+ |
| 6 | Quarantine tab (Idea 6) | Alternative to Idea 5 if simpler |

---

## Correction process (current state)

Until an automated solution is implemented:

1. Notice incorrect values in the sheet
2. Note the `receipt_id` of the affected receipt
3. Delete rows with that `receipt_id` from **both** sheets
4. If LLM error: improve the prompt
5. Re-run the Bulk Import workflow → only this receipt gets reprocessed
