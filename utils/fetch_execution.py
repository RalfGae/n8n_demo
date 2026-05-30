#!/usr/bin/env python3
"""
Fetch an n8n Bulk Import execution and save a structured log to logs/.

Usage:
  python3 utils/fetch_execution.py            # latest Bulk Import execution
  python3 utils/fetch_execution.py 499        # specific execution ID
"""

import json
import sys
from datetime import datetime
from pathlib import Path
import urllib.request

BASE_URL = "http://localhost:5678"
WORKFLOW_ID = "UigcQtXyleXGTRvM"


def get_api_key():
    env_path = Path(__file__).parent.parent / ".env"
    for line in env_path.read_text().splitlines():
        if line.startswith("N8N_API_KEY="):
            return line.split("=", 1)[1].strip()
    raise ValueError("N8N_API_KEY not found in .env")


def api_get(path, api_key):
    req = urllib.request.Request(
        f"{BASE_URL}{path}",
        headers={"X-N8N-API-KEY": api_key, "Accept": "application/json"},
    )
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read())


def node_items(run_data, node_name, branch=0):
    runs = run_data.get(node_name, [])
    if not runs:
        return []
    branches = runs[0].get("data", {}).get("main", [])
    if branch >= len(branches):
        return []
    return branches[branch] or []


def summarize(exec_data):
    rd = exec_data.get("data", {}).get("resultData", {}).get("runData", {})

    s = {
        "execution_id": exec_data.get("id"),
        "status": exec_data.get("status"),
        "started_at": exec_data.get("startedAt"),
        "stopped_at": exec_data.get("stoppedAt"),
        "folder_id": None,
        "files_found": len(node_items(rd, "Search files and folders")),
        "files_processed": len(node_items(rd, "Filter new files")),
        "pdf_count": len(node_items(rd, "Download file")),
        "jpg_count": len(node_items(rd, "Download file1")),
        "node_item_counts": {},
        "llm_outputs": {"PDF": [], "JPG": []},
        "successes": [],
        "errors": [],
    }

    form = node_items(rd, "On form submission")
    if form:
        s["folder_id"] = form[0].get("json", {}).get("Folder ID", "")

    # Per-node item counts (both branches) for debugging
    for node, runs in rd.items():
        if runs:
            main = runs[0].get("data", {}).get("main", [])
            s["node_item_counts"][node] = [len(b or []) for b in main]

    # LLM raw outputs
    for chain, branch_key in [("Basic LLM Chain", "PDF"), ("Basic LLM Chain1", "JPG")]:
        for item in node_items(rd, chain):
            text = item.get("json", {}).get("text", "")
            try:
                parsed = json.loads(text.strip())
                ri = parsed.get("receipt_info") or parsed.get("RECEIPT_INFO") or {}
                s["llm_outputs"][branch_key].append({
                    "receipt_id": parsed.get("receipt_id", ""),
                    "store": ri.get("store") or ri.get("store_name", ""),
                    "date": ri.get("date", ""),
                    "total_amount": ri.get("total_amount"),
                    "currency": ri.get("currency", ""),
                    "confidence": ri.get("confidence") or ri.get("confidence_score"),
                    "parse_ok": True,
                })
            except Exception as e:
                s["llm_outputs"][branch_key].append({
                    "parse_ok": False,
                    "error": str(e),
                    "text_preview": text[:150],
                })

    # Successes written to GSheet (Edit Fields nodes are the gate)
    for node, branch_key in [("Edit Fields", "PDF"), ("Edit Fields2", "JPG")]:
        for item in node_items(rd, node):
            j = item.get("json", {})
            s["successes"].append({
                "branch": branch_key,
                "receipt_id": j.get("receipt_id", ""),
                "date": j.get("date", ""),
                "store": j.get("store", ""),
                "total_amount": j.get("total_amount"),
                "currency": j.get("currency", ""),
                "confidence": j.get("confidence"),
            })

    # Errors
    for item in node_items(rd, "Append to errors sheet"):
        j = item.get("json", {})
        s["errors"].append({
            "receipt_id": j.get("receipt_id", ""),
            "filename": j.get("filename", ""),
            "error_type": j.get("error_type", ""),
            "error_message": j.get("error_message", ""),
            "drive_url": j.get("drive_url", ""),
        })

    return s


def print_summary(s):
    print(f"\nExecution {s['execution_id']}  status={s['status']}")
    print(f"  Started:  {s['started_at']}")
    print(f"  Stopped:  {s['stopped_at']}")
    print(f"  Folder:   {s['folder_id']}")
    print(f"  Found:    {s['files_found']} files  |  Processed: {s['files_processed']}")
    print(f"  PDFs:     {s['pdf_count']}  |  JPGs: {s['jpg_count']}")
    print(f"  GSheet:   {len(s['successes'])} written  |  Errors: {len(s['errors'])}")

    print("\n  LLM outputs:")
    for branch, items in s["llm_outputs"].items():
        ok = [i for i in items if i.get("parse_ok")]
        missing = [i for i in ok if not i.get("receipt_id")]
        print(f"    {branch} ({len(items)} items, {len(ok)} parseable, {len(missing)} missing receipt_id):")
        for i in items:
            if i.get("parse_ok"):
                rid = i["receipt_id"][:16] + "…" if len(i.get("receipt_id","")) > 16 else i.get("receipt_id","—")
                print(f"      {i['store']:30s}  {i['date']}  {str(i['total_amount']):>8} {i['currency']:3}  receipt_id={rid}")
            else:
                print(f"      PARSE ERROR: {i['error']}  preview={i['text_preview'][:80]}")

    if s["successes"]:
        print("\n  GSheet successes:")
        for r in s["successes"]:
            rid = r["receipt_id"][:16] + "…" if len(r.get("receipt_id","")) > 16 else r.get("receipt_id","—")
            print(f"    [{r['branch']}] {r['store']:30s}  {r['date']}  {str(r['total_amount']):>8}  receipt_id={rid}")

    if s["errors"]:
        print("\n  Errors:")
        for e in s["errors"]:
            rid = e["receipt_id"][:16] + "…" if e.get("receipt_id") else "—"
            print(f"    {e['error_type']:35s}  {e['error_message'][:60]}  receipt_id={rid}")

    print("\n  Node item counts (both branches):")
    for node, counts in sorted(s["node_item_counts"].items()):
        print(f"    {node:45s}  {counts}")


def main():
    api_key = get_api_key()

    if len(sys.argv) > 1:
        exec_id = sys.argv[1]
    else:
        data = api_get(f"/api/v1/executions?workflowId={WORKFLOW_ID}&limit=1", api_key)
        executions = data.get("data", [])
        if not executions:
            print("No executions found for Bulk Import workflow.")
            sys.exit(1)
        exec_id = executions[0]["id"]
        print(f"Latest execution: {exec_id}")

    exec_data = api_get(f"/api/v1/executions/{exec_id}?includeData=true", api_key)
    summary = summarize(exec_data)
    print_summary(summary)

    logs_dir = Path(__file__).parent.parent / "logs"
    logs_dir.mkdir(exist_ok=True)
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    out_path = logs_dir / f"execution_{exec_id}_{ts}.json"
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump({"summary": summary, "raw": exec_data}, f, indent=2, ensure_ascii=False)
    print(f"\nSaved: {out_path}")


if __name__ == "__main__":
    main()
