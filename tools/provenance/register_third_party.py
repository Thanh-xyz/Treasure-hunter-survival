#!/usr/bin/env python3
"""Register verified third-party asset packs in docs/architecture/asset-manifest.json.

Every image/audio/font file under a pack's folder gets a `verified` record that points at the
licence file shipped with the pack. Licence facts below were read from the files inside each
downloaded archive (2026-11-08), not only from web pages.

    python3 -I tools/provenance/register_third_party.py          # add missing records
    python3 -I tools/provenance/register_third_party.py --check  # exit 1 if any file is unrecorded
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "docs/architecture/asset-manifest.json"
MEDIA = {".png", ".wav", ".ogg", ".mp3", ".ttf", ".otf"}

PACKS = {
    "assets/ninja_adventure": {
        "pack": "ninja_adventure",
        "source": "https://pixel-boy.itch.io/ninja-adventure-asset-pack (Ninja Adventure - Asset Pack.zip)",
        "creator": "Pixel-boy & AAA",
        "license": "CC0-1.0",
        "license_ref": "assets/ninja_adventure/LICENSE.txt",
        "attribution": "Ninja Adventure Asset Pack by Pixel-boy & AAA (CC0; credit appreciated, not required)",
    },
    "assets/kenney_tiny_dungeon": {
        "pack": "kenney_tiny_dungeon",
        "source": "https://kenney.nl/assets/tiny-dungeon (kenney_tiny-dungeon.zip, v1.0)",
        "creator": "Kenney (www.kenney.nl)",
        "license": "CC0-1.0",
        "license_ref": "assets/kenney_tiny_dungeon/License.txt",
        "attribution": "Tiny Dungeon by Kenney (CC0; credit appreciated, not required)",
    },
    "assets/kenney_tiny_town": {
        "pack": "kenney_tiny_town",
        "source": "https://kenney.nl/assets/tiny-town (kenney_tiny-town.zip)",
        "creator": "Kenney (www.kenney.nl)",
        "license": "CC0-1.0",
        "license_ref": "assets/kenney_tiny_town/License.txt",
        "attribution": "Tiny Town by Kenney (CC0; credit appreciated, not required)",
    },
    "assets/the_pack": {
        "pack": "the_pack",
        "source": "THE PACK.zip by pixel_ankousse (https://www.instagram.com/pixel_ankousse/)",
        "creator": "pixel_ankousse",
        "license": "Custom free licence (free and commercial use, modification allowed, credit optional)",
        "license_ref": "assets/the_pack/READ ME.txt",
        "attribution": "THE PACK by pixel_ankousse (credit appreciated, not required)",
        "verified_on": "2026-11-09",
    },
    "assets/gridwright": {
        "pack": "gridwright",
        "source": "Gridwright Jam Pack v1.0 (free-pixel-art-game-assets-jam-pack-jam-pack.zip), https://gridwrightstudio.itch.io",
        "creator": "Gridwright",
        "license": "Gridwright Jam Pack licence (personal and commercial use, modification; no resale or redistribution as assets; no AI training or NFTs)",
        "license_ref": "assets/gridwright/LICENSE.txt",
        "attribution": "Art by Gridwright (credit appreciated, not required)",
        "restrictions": "Ship only inside the game; do not resell or redistribute the files as assets; no AI training, no NFTs.",
        "verified_on": "2026-11-09",
    },
    "assets/kenney_pixel_ui": {
        "pack": "kenney_pixel_ui",
        "source": "https://kenney.nl/assets/pixel-ui-pack (kenney_pixel-ui-pack.zip)",
        "creator": "Kenney Vleugels & Lynn Evers for Kenney (www.kenney.nl)",
        "license": "CC0-1.0",
        "license_ref": "assets/kenney_pixel_ui/License.txt",
        "attribution": "Pixel UI Pack by Kenney (CC0; credit appreciated, not required)",
    },
}


def asset_id(pack: str, rel: Path) -> str:
    stem = "/".join(rel.with_suffix("").parts).lower().replace(" ", "_")
    return f"thirdparty.{pack}.{stem.replace('/', '.')}"


def records_for(folder: str, info: dict) -> list[dict]:
    base = ROOT / folder
    if not base.exists():
        return []
    out = []
    for path in sorted(base.rglob("*")):
        if path.suffix.lower() not in MEDIA:
            continue
        rel_to_root = path.relative_to(ROOT).as_posix()
        out.append({
            "asset_id": asset_id(info["pack"], path.relative_to(base)),
            "category": "third_party",
            "source_path": None,
            "target_path": rel_to_root,
            "file_format": path.suffix.lower().lstrip("."),
            "dimensions": None,
            "transparency": "transparent_or_partial",
            "animation": None,
            "usage": [],
            "provenance": {
                "status": "verified",
                "source": info["source"],
                "creator": info["creator"],
                "license": info["license"],
                "license_ref": info["license_ref"],
                "commercial_use": "yes",
                "modification": "yes",
                "attribution": info["attribution"],
                "distribution_restrictions": info.get("restrictions"),
                "verified_by": "licence file inside the downloaded archive",
                "verified_on": info.get("verified_on", "2026-11-08"),
            },
            "evidence_status": "licence_file_inspected",
            "integration_status": "in_use",
            "notes": [],
        })
    return out


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args(argv)
    data = json.loads(MANIFEST.read_text(encoding="utf-8"))
    known = {r.get("target_path") for r in data["assets"]}
    missing = []
    for folder, info in PACKS.items():
        if (ROOT / folder).exists() and not (ROOT / info["license_ref"]).exists():
            print(f"licence file missing: {info['license_ref']}")
            return 1
        missing += [r for r in records_for(folder, info) if r["target_path"] not in known]
    if args.check:
        for r in missing:
            print(f"unrecorded third-party file: {r['target_path']}")
        return 1 if missing else 0
    data["assets"].extend(missing)
    MANIFEST.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"added {len(missing)} third-party records")
    return 0


if __name__ == "__main__":
    sys.exit(main())
