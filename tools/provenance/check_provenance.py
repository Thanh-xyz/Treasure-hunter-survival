#!/usr/bin/env python3
"""Static asset-provenance gate.

Scans project files for `res://` asset references and asset IDs, resolves each one to a record in
docs/architecture/asset-manifest.json (schema v2), and fails when an asset is unrecorded or its
status isn't allowed for the chosen build mode.

    python3 -I tools/provenance/check_provenance.py --mode dev       # default
    python3 -I tools/provenance/check_provenance.py --mode release
    python3 -I tools/provenance/check_provenance.py --write-credits  # regenerate CREDITS.md

Modes:
  dev      every recorded status is allowed (excluded/unverified are reported as warnings)
  release  only `original` and `verified` are allowed; shipped files only (tests/ ignored)

Exit code 0 = pass, 1 = violations, 2 = usage or manifest error.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

ASSET_EXTENSIONS = ("png", "svg", "jpg", "jpeg", "webp", "ttf", "otf", "fnt", "wav", "ogg", "mp3", "aseprite")
RES_PATTERN = re.compile(r"res://([^\"'\s\)\]]+\.(?:%s))\b" % "|".join(ASSET_EXTENSIONS), re.IGNORECASE)
SCAN_SUFFIXES = (".gd", ".tscn", ".tres", ".godot", ".cfg")
SKIP_DIRS = {".git", ".godot", "docs", "tools", "android", "build"}
SHIPPED_ROOTS = ("sense", "assets", "project.godot", "export_presets.cfg")
FORBIDDEN_SOURCES = ("assets-ths", "/home/")
STATUSES = ("original", "verified", "licence_pending", "unverified", "excluded")
RELEASE_ALLOWED = ("original", "verified")


@dataclass
class Report:
    errors: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)
    by_status: dict[str, set[str]] = field(default_factory=dict)


def load_manifest(path: Path) -> tuple[dict[str, dict], dict[str, dict]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if data.get("schema_version") != 2:
        raise ValueError(f"{path}: expected schema_version 2, got {data.get('schema_version')!r}")
    by_path: dict[str, dict] = {}
    by_id: dict[str, dict] = {}
    for record in data["assets"]:
        status = (record.get("provenance") or {}).get("status")
        if status not in STATUSES:
            raise ValueError(f"{record.get('asset_id')}: invalid provenance status {status!r}")
        if record.get("target_path"):
            by_path[record["target_path"]] = record
        by_id[record["asset_id"]] = record
    return by_path, by_id


def iter_scan_files(root: Path, mode: str):
    for path in sorted(root.rglob("*")):
        if not path.is_file() or path.suffix not in SCAN_SUFFIXES:
            continue
        rel = path.relative_to(root)
        if rel.parts and rel.parts[0] in SKIP_DIRS:
            continue
        if mode == "release":
            if not any(str(rel) == r or rel.parts[0] == r for r in SHIPPED_ROOTS):
                continue
        yield path, rel


def collect_references(root: Path, mode: str, asset_ids: set[str]) -> tuple[dict[str, set[str]], list[str]]:
    refs: dict[str, set[str]] = {}
    forbidden: list[str] = []
    id_pattern = re.compile(r"[\"'](%s)[\"']" % "|".join(re.escape(i) for i in sorted(asset_ids))) if asset_ids else None
    for path, rel in iter_scan_files(root, mode):
        text = path.read_text(encoding="utf-8", errors="ignore")
        for match in RES_PATTERN.findall(text):
            refs.setdefault(match, set()).add(str(rel))
        if id_pattern is not None and path.suffix == ".gd":
            for match in id_pattern.findall(text):
                refs.setdefault(f"id:{match}", set()).add(str(rel))
        shipped = rel.parts[0] in SHIPPED_ROOTS or str(rel) in SHIPPED_ROOTS
        for token in FORBIDDEN_SOURCES:
            # Tests may name forbidden sources in assertions; only shipped files are checked.
            if shipped and token in text and path.suffix in (".gd", ".tscn", ".tres", ".godot"):
                for lineno, line in enumerate(text.splitlines(), 1):
                    if token in line:
                        forbidden.append(f"{rel}:{lineno}: references external source '{token}'")
    return refs, forbidden


def check(root: Path, manifest: Path, mode: str) -> Report:
    report = Report()
    by_path, by_id = load_manifest(manifest)
    refs, forbidden = collect_references(root, mode, set(by_id))
    report.errors.extend(forbidden)
    for ref, users in sorted(refs.items()):
        record = by_id.get(ref[3:]) if ref.startswith("id:") else by_path.get(ref)
        where = ", ".join(sorted(users)[:3]) + (" …" if len(users) > 3 else "")
        if record is None:
            report.errors.append(f"unrecorded asset {ref} (used by {where})")
            continue
        status = record["provenance"]["status"]
        report.by_status.setdefault(status, set()).add(record["asset_id"])
        if mode == "release" and status not in RELEASE_ALLOWED:
            report.errors.append(f"{status} asset {ref} not allowed in release (used by {where})")
        elif status in ("excluded", "licence_pending", "unverified") and mode == "dev":
            report.warnings.append(f"{status}: {ref}")
    for target in sorted(by_path):
        if not (root / target).exists():
            report.errors.append(f"manifest target missing on disk: {target}")
    return report


def write_credits(root: Path, manifest: Path) -> Path:
    data = json.loads(manifest.read_text(encoding="utf-8"))
    groups: dict[str, list[dict]] = {}
    for record in data["assets"]:
        groups.setdefault(record["provenance"]["status"], []).append(record)
    lines = [
        "# Credits",
        "",
        "Generated from `docs/architecture/asset-manifest.json` by",
        "`python3 -I tools/provenance/check_provenance.py --write-credits`. Do not edit by hand.",
        "",
    ]
    attributions = sorted({r["provenance"]["attribution"] for r in data["assets"]
                           if r["provenance"].get("attribution") and r["provenance"]["status"] in RELEASE_ALLOWED})
    lines += ["## Attributions", ""] + ([f"- {a}" for a in attributions] or ["- None required yet."]) + [""]
    lines += ["## Asset status summary", "", "| Status | Records | Shippable |", "| --- | --- | --- |"]
    for status in STATUSES:
        lines.append(f"| {status} | {len(groups.get(status, []))} | {'yes' if status in RELEASE_ALLOWED else 'no'} |")
    lines += ["", "Assets that are not shippable must be verified or replaced before any public build.", ""]
    out = root / "CREDITS.md"
    out.write_text("\n".join(lines), encoding="utf-8")
    return out


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--mode", choices=("dev", "release"), default="dev")
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--manifest", type=Path, default=None)
    parser.add_argument("--write-credits", action="store_true")
    parser.add_argument("--quiet", action="store_true", help="hide per-asset warnings")
    args = parser.parse_args(argv)
    root = args.root.resolve()
    manifest = args.manifest or root / "docs/architecture/asset-manifest.json"
    try:
        if args.write_credits:
            print(f"Wrote {write_credits(root, manifest)}")
            return 0
        report = check(root, manifest, args.mode)
    except (OSError, ValueError, KeyError) as exc:
        print(f"provenance: {exc}", file=sys.stderr)
        return 2
    if not args.quiet:
        for warning in report.warnings:
            print(f"WARN  {warning}")
    for error in report.errors:
        print(f"ERROR {error}")
    summary = ", ".join(f"{s}={len(report.by_status.get(s, ()))}" for s in STATUSES)
    verdict = "FAIL" if report.errors else "PASS"
    print(f"provenance [{args.mode}] {verdict}: referenced assets by status: {summary}; errors={len(report.errors)}")
    return 1 if report.errors else 0


if __name__ == "__main__":
    sys.exit(main())
