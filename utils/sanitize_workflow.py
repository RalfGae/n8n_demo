#!/usr/bin/env python3
"""
Sanitize an n8n workflow JSON by replacing sensitive values with $env expressions.
Reads from stdin or a file path (sys.argv[1]). Writes sanitized JSON to stdout.
Requires utils/workflow_var_mapping.json relative to this script.
"""
import json
import sys
import os

# Maps mapping scope → set of field names where that scope applies
SCOPE_TO_FIELDS = {
    "drive_folder":   {"folderToWatch"},
    "sheet_document": {"documentId"},
    "sheet_gid":      {"sheetName"},
    "email":          {"sendTo"},
}


def load_mappings():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    path = os.path.join(script_dir, "workflow_var_mapping.json")
    with open(path, encoding="utf-8") as f:
        return json.load(f)["mappings"]


def make_expr(var_name):
    return "={{ $env." + var_name + " }}"


def sanitize_rl(obj, mappings, field_name, stats):
    """Handle a dict with __rl: true — replace value/cachedResult fields if matched."""
    value = obj.get("value")

    # Already sanitized
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
    """Replace a plain email sendTo value with an $env expression."""
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


def main():
    if len(sys.argv) > 1:
        with open(sys.argv[1], encoding="utf-8") as f:
            data = json.load(f)
    else:
        data = json.load(sys.stdin)

    mappings = load_mappings()
    all_vars = {m["env_var"] for m in mappings}
    stats = {"values": 0, "cache_pairs": 0, "emails": 0, "used": set()}

    sanitized = walk(data, mappings, stats=stats)

    print(json.dumps(sanitized, indent=2, ensure_ascii=False))

    unused_count = len(all_vars - stats["used"])
    print(
        f"Sanitized: {stats['values']} values, {stats['cache_pairs']} cache pairs, "
        f"{stats['emails']} email fields ({unused_count} mappings unused)",
        file=sys.stderr,
    )


if __name__ == "__main__":
    main()
