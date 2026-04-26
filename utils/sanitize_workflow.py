#!/usr/bin/env python3
"""
Sanitize an n8n workflow JSON by replacing sensitive values with $env expressions
and stripping account-specific metadata blocks (shared, instanceId).

Reads from stdin or a file path (sys.argv[1]). Writes sanitized JSON to stdout.
Requires utils/workflow_var_mapping.json relative to this script.

Handles both single-workflow exports (top-level dict) and CLI exports
(top-level list of workflows).
"""
import json
import sys
import os

SCOPE_TO_FIELDS = {
    "drive_folder":   {"folderToWatch"},
    "sheet_document": {"documentId"},
    "sheet_gid":      {"sheetName"},
    "email":          {"sendTo"},
}

STRIP_TOP_LEVEL_KEYS = {"shared"}


def load_mappings():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    path = os.path.join(script_dir, "workflow_var_mapping.json")
    with open(path, encoding="utf-8") as f:
        return json.load(f)["mappings"]


def make_expr(var_name):
    return "={{ $env." + var_name + " }}"


def sanitize_rl(obj, mappings, field_name, stats):
    value = obj.get("value")
    if isinstance(value, str) and value.startswith("={{ $env."):
        return obj
    value_str = str(value) if value is not None else None
    for m in mappings:
        applicable = SCOPE_TO_FIELDS.get(m["scope"], set())
        if field_name not in applicable:
            continue
        if value_str == m["value"]:
            var = m["env_var"]
            new_obj = dict(obj)
            new_obj["value"] = make_expr(var)
            new_obj["cachedResultName"] = var
            new_obj["cachedResultUrl"] = var
            stats["values"] += 1
            stats["cache_pairs"] += 1
            stats["used"].add(var)
            return new_obj
    return obj


def sanitize_sendto(v, mappings, stats):
    if not isinstance(v, str):
        return v
    if v.startswith("={{ "):
        return v
    for m in mappings:
        if m["scope"] == "email" and v == m["value"]:
            stats["emails"] += 1
            stats["used"].add(m["env_var"])
            return make_expr(m["env_var"])
    return v


def walk(obj, mappings, field_name=None, stats=None):
    if isinstance(obj, dict):
        if obj.get("__rl") is True and field_name is not None:
            return sanitize_rl(obj, mappings, field_name, stats)
        result = {}
        for k, v in obj.items():
            if k == "sendTo":
                result[k] = sanitize_sendto(v, mappings, stats)
            else:
                result[k] = walk(v, mappings, field_name=k, stats=stats)
        return result
    if isinstance(obj, list):
        return [walk(item, mappings, field_name=field_name, stats=stats) for item in obj]
    return obj


def _strip_one(workflow, stats):
    """Strip account/instance metadata from a single workflow dict."""
    if not isinstance(workflow, dict):
        return
    for key in list(STRIP_TOP_LEVEL_KEYS):
        if key in workflow:
            del workflow[key]
            stats["stripped"].append(key)
    if isinstance(workflow.get("meta"), dict) and "instanceId" in workflow["meta"]:
        del workflow["meta"]["instanceId"]
        stats["stripped"].append("meta.instanceId")


def strip_metadata(data, stats):
    """Remove metadata. Handles single workflow (dict) or list of workflows."""
    if isinstance(data, list):
        for item in data:
            _strip_one(item, stats)
    else:
        _strip_one(data, stats)
    return data


def main():
    if len(sys.argv) > 1:
        with open(sys.argv[1], encoding="utf-8") as f:
            data = json.load(f)
    else:
        data = json.load(sys.stdin)

    mappings = load_mappings()
    all_vars = {m["env_var"] for m in mappings}
    stats = {"values": 0, "cache_pairs": 0, "emails": 0, "used": set(), "stripped": []}

    data = strip_metadata(data, stats)
    sanitized = walk(data, mappings, stats=stats)
    print(json.dumps(sanitized, indent=2, ensure_ascii=False))

    unused_count = len(all_vars - stats["used"])
    stripped_str = (
        f", stripped {', '.join(stats['stripped'])}" if stats["stripped"] else ""
    )
    print(
        f"Sanitized: {stats['values']} values, {stats['cache_pairs']} cache pairs, "
        f"{stats['emails']} email fields ({unused_count} mappings unused){stripped_str}",
        file=sys.stderr,
    )


if __name__ == "__main__":
    main()
