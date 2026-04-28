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

### Idea 3 — LLM returns confidence score (decided: implement)
**What:** Extend prompt and schema: LLM outputs `confidence` (integer 1–5) per receipt.
Value is written as a column to the existing Gesamtposten sheet alongside the extracted data.

**Scale:**
- 5 — all values clearly readable, high certainty
- 3 — some values ambiguous (faded print, unclear handwriting)
- 1 — image barely readable, extraction largely guesswork

**Why 1–5 and not percentages:** LLM confidence is not a calibrated probability.
73% sounds more precise than it is. 1–5 is honest about the fuzziness.

**Why in the existing sheet (not a separate sheet):** Confidence is most useful
next to the extracted values — `REWE | 45.23€ | confidence: 2` is immediately actionable.
A separate sheet would require joining by receipt_id for every analysis.

**Expansion stages (implement only when data justifies it):**
- Stage 1 ✅ current plan: one `confidence` column, overall score
- Stage 2 (if needed): add `confidence_min_field` — name of the least-confident field
- Stage 3 (if needed): per-field scores (`confidence_date`, `confidence_total`, etc.)

**Pro:** Zero extra API cost, enables store-level quality analysis in the sheet,
provides before/after signal for prompt improvements.
**Con:** LLM self-assessment is unreliable — a wrong extraction can still come with confidence: 5.
Use as a signal, not as ground truth.
**Effort:** Low — extend schema, add 2 sentences to prompt, add one sheet column.

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

## Quality measurement strategy

**Principle: measure first, then decide.**
Before building automated QA systems, establish a baseline error rate.

1. **After first Bulk Import:** manually spot-check 20–30 receipts
2. **Estimate error rate:**
   - < 5%: accept, correct manually when noticed
   - 5–10%: investigate patterns, fix prompt, re-run
   - \> 10%: systematic problem — deep-dive before proceeding
3. **Use confidence scores** (once implemented) to filter low-confidence receipts
   and prioritize manual review
4. **Collect errors over time** — after ~100 receipts, create a priority list of
   error patterns sorted by frequency × impact. Fix the prompt for the highest-impact
   patterns first.
5. **Before/after comparison:** run same receipts through updated prompt,
   compare confidence scores and spot-check values.

**What multiple-run voting does NOT solve:** systematic errors. If the prompt
always misreads ALDI's receipt format, voting 5x still gives 5x the same wrong answer.
Voting only helps with random/stochastic errors.

---

## Force reprocess — decided: remove

The "Force reprocess" checkbox was removed from the Bulk Import form.

**Reason:** With the current `Append` write strategy, Force would create duplicate rows
rather than overwriting existing data — not the intended behavior. True overwriting
would require a Delete-then-Append pattern (extra nodes, extra complexity).

**Correction process for incorrectly extracted receipts:**
1. Find the row in the sheet, note `receipt_id`
2. Delete that row (and corresponding rows in Einzelposten) manually
3. Re-run Bulk Import on the same folder — the receipt will be picked up again

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

## Potential TODOs (Bulk Import & Input Validation)

These were identified during Bulk Import workflow design — deferred, not implemented.

| # | Topic | Description | Priority |
|---|-------|-------------|----------|
| 1 | Non-receipt file detection | LLM will attempt extraction on any JPG/PDF — presentations, photos, ID scans etc. produce garbage data silently. A pre-check ("is this a receipt?") would prevent bad writes. → Related to Idea 4 (Second-opinion LLM). | Medium |
| 2 | Empty folder handling | If the specified folder has no files, the Bulk Import workflow completes silently. A notification ("0 files found, check folder ID") would be helpful. | Low |
| 3 | Bulk Import processing summary | Currently no email at end of bulk run. A summary (total found / processed / skipped) would help verify the import completed correctly without manual sheet counting. | Low |
| 4 | Bulk Import status tracking | To produce the summary above, processed and skipped items need to be tracked across branches (Merge + Code Node). Deferred as overengineering for a one-time migration tool. | Low |

---

## Correction process (current state)

Until an automated solution is implemented:

1. Notice incorrect values in the sheet
2. Note the `receipt_id` of the affected receipt
3. Delete rows with that `receipt_id` from **both** sheets
4. If LLM error: improve the prompt
5. Re-run the Bulk Import workflow → only this receipt gets reprocessed
