#!/usr/bin/env python3
"""One-off migration of docs/architecture/asset-manifest.json from schema v1 to v2.

Schema v2 replaces each record's `provenance` block with licence-oriented fields and keeps the
old block under `provenance.legacy_v1` for traceability. Run from the repository root:

    python3 -I tools/provenance/migrate_manifest_v2.py

The script is idempotent: a v2 manifest is left unchanged.
"""
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "docs/architecture/asset-manifest.json"
TODAY = "2026-11-07"

EXCLUDED_NOTE = (
    "Reference-game material obtained from the Treasure Hunter – Survival XAPK or runtime captures. "
    "Owner decision 2026-11-07: not used in the game; replace (ASSET_REPLACEMENT_PLAN §3) and retire (P0-9)."
)


def first_commit(path: str) -> str | None:
    out = subprocess.run(
        ["git", "log", "--diff-filter=A", "--format=%h %ad %an", "--date=short", "--", path],
        cwd=ROOT, capture_output=True, text=True, check=False,
    ).stdout.strip().splitlines()
    return out[-1] if out else None


def v2_provenance(record: dict) -> dict:
    legacy = record.get("provenance") or {}
    target = record.get("target_path") or ""
    if target.startswith("assets/treasure_hunter/"):
        return {
            "status": "excluded",
            "source": "Treasure Hunter – Survival 4.3.6 (Mega Combat) — "
                      + ("runtime capture" if legacy.get("status") == "user_supplied_capture_derived"
                         else "XAPK extraction via assets-ths"),
            "creator": "Mega Combat (reference game)",
            "license": None,
            "license_ref": None,
            "commercial_use": "no",
            "modification": "no",
            "attribution": None,
            "distribution_restrictions": EXCLUDED_NOTE,
            "verified_by": None,
            "verified_on": None,
            "legacy_v1": legacy,
        }
    commit = first_commit(target)
    return {
        "status": "unverified",
        "source": f"Imported into the upstream Emberfield repository ({commit})" if commit
                  else "Unknown",
        "creator": None,
        "license": None,
        "license_ref": None,
        "commercial_use": "unknown",
        "modification": "unknown",
        "attribution": None,
        "distribution_restrictions": "No licence on file. Development only until verified or replaced.",
        "verified_by": None,
        "verified_on": None,
        "legacy_v1": legacy,
    }


EXTRA_RECORDS = [
    {
        "asset_id": "branding.icon.godot_default",
        "category": "branding",
        "source_path": None,
        "target_path": "icon.svg",
        "file_format": "svg",
        "dimensions": [128, 128],
        "transparency": "transparent_or_partial",
        "animation": None,
        "usage": ["project.godot", "sense/ui/hud/hud.tscn"],
        "provenance": {
            "status": "unverified",
            "source": "Godot Engine default project icon (created with the project)",
            "creator": "Godot Engine contributors",
            "license": None,
            "license_ref": None,
            "commercial_use": "unknown",
            "modification": "unknown",
            "attribution": None,
            "distribution_restrictions": "Engine branding, not a game icon. Replace with a Cinderwild icon (P0-10).",
            "verified_by": None,
            "verified_on": None,
        },
        "evidence_status": "file_inspected",
        "integration_status": "in_use",
        "notes": ["Added by the v2 migration; was missing from the v1 manifest."],
    },
    {
        "asset_id": "generated.pixel_art.sprites",
        "category": "generated",
        "source_path": None,
        "target_path": "sense/globals/pixel_art.gd",
        "file_format": "gdscript_ascii_sprites",
        "dimensions": None,
        "transparency": "transparent_or_partial",
        "animation": "runtime SpriteFrames for some sprites",
        "usage": ["sense/globals/pixel_art.gd"],
        "provenance": {
            "status": "original",
            "source": "in-repo: sense/globals/pixel_art.gd (ASCII sprites + palettes rendered at runtime)",
            "creator": "Emberfield / Cinderwild project",
            "license": "Project-owned",
            "license_ref": None,
            "commercial_use": "yes",
            "modification": "yes",
            "attribution": None,
            "distribution_restrictions": None,
            "verified_by": "repository history",
            "verified_on": TODAY,
        },
        "evidence_status": "source_inspected",
        "integration_status": "in_use",
        "notes": ["Covers every sprite ID in PixelArt.SPRITES; textures have no res:// path."],
    },
]


def main() -> int:
    data = json.loads(MANIFEST.read_text(encoding="utf-8"))
    if data.get("schema_version") == 2:
        print("Manifest already at schema v2; nothing to do.")
        return 0
    for record in data["assets"]:
        record["provenance"] = v2_provenance(record)
    known = {r["asset_id"] for r in data["assets"]}
    data["assets"].extend(r for r in EXTRA_RECORDS if r["asset_id"] not in known)
    data["schema_version"] = 2
    data["project"] = "Cinderwild (internal project name: emberfield)"
    data["generated_from"] = data.get("generated_from", "") + f"; migrated to schema v2 on {TODAY}"
    data.pop("evidence_policy", None)
    data["provenance_policy"] = {
        "statuses": {
            "original": "Created for this project. Allowed in every build.",
            "verified": "Licence text on file and checked. Allowed per licence terms.",
            "licence_pending": "Licence document on file but not yet verified. Development builds only.",
            "unverified": "No licence on file. Development builds only.",
            "excluded": "Must not ship. Allowed in development builds only until retired.",
        },
        "release_allowed": ["original", "verified"],
        "gate": "tools/provenance/check_provenance.py and tests/ProvenanceTests.tscn",
    }
    MANIFEST.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    counts: dict[str, int] = {}
    for r in data["assets"]:
        counts[r["provenance"]["status"]] = counts.get(r["provenance"]["status"], 0) + 1
    print(f"Migrated {len(data['assets'])} records: {counts}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
