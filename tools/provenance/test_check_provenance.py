#!/usr/bin/env python3
"""Unit tests for check_provenance.py. Run: python3 -I tools/provenance/test_check_provenance.py"""
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_provenance as cp  # noqa: E402


def record(asset_id, target, status):
    return {"asset_id": asset_id, "target_path": target, "provenance": {"status": status}}


class ProvenanceGateTests(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.root = Path(self._tmp.name)
        (self.root / "sense").mkdir()
        (self.root / "tests").mkdir()
        (self.root / "docs/architecture").mkdir(parents=True)
        for name in ("ok.png", "bad.png", "dev.png"):
            (self.root / name).write_bytes(b"x")
        self.records = [
            record("a.ok", "ok.png", "original"),
            record("a.bad", "bad.png", "excluded"),
            record("a.dev", "dev.png", "unverified"),
        ]
        self.write_manifest()

    def tearDown(self):
        self._tmp.cleanup()

    def write_manifest(self, version=2):
        data = {"schema_version": version, "assets": self.records}
        self.manifest = self.root / "docs/architecture/asset-manifest.json"
        self.manifest.write_text(json.dumps(data), encoding="utf-8")

    def scene(self, rel, body):
        path = self.root / rel
        path.write_text(body, encoding="utf-8")

    def run_check(self, mode):
        return cp.check(self.root, self.manifest, mode)

    def test_original_asset_passes_release(self):
        self.scene("sense/a.tscn", '[ext_resource path="res://ok.png" type="Texture2D"]')
        self.assertEqual(self.run_check("release").errors, [])

    def test_unrecorded_asset_fails_both_modes(self):
        (self.root / "new.png").write_bytes(b"x")
        self.scene("sense/a.gd", 'var t = preload("res://new.png")')
        for mode in ("dev", "release"):
            errors = self.run_check(mode).errors
            self.assertTrue(any("unrecorded asset new.png" in e for e in errors), (mode, errors))

    def test_excluded_asset_warns_in_dev_and_fails_release(self):
        self.scene("sense/a.gd", 'var t = load("res://bad.png")')
        dev = self.run_check("dev")
        self.assertEqual(dev.errors, [])
        self.assertTrue(any("excluded: bad.png" in w for w in dev.warnings))
        self.assertTrue(any("excluded asset bad.png" in e for e in self.run_check("release").errors))

    def test_unverified_asset_fails_release(self):
        self.scene("sense/a.tscn", '[ext_resource path="res://dev.png"]')
        self.assertEqual(self.run_check("dev").errors, [])
        self.assertTrue(self.run_check("release").errors)

    def test_asset_id_reference_is_resolved(self):
        self.scene("sense/a.gd", 'const ART := "a.bad"')
        self.assertTrue(any("id:a.bad" in e for e in self.run_check("release").errors))

    def test_tests_dir_is_ignored_in_release(self):
        self.scene("tests/t.gd", 'var t = load("res://bad.png")')
        self.assertEqual(self.run_check("release").errors, [])

    def test_external_source_path_is_forbidden(self):
        self.scene("sense/a.gd", 'var p = "/home/someone/assets-ths/x.png"')
        errors = self.run_check("dev").errors
        self.assertTrue(any("assets-ths" in e for e in errors), errors)

    def test_tests_may_mention_external_source(self):
        self.scene("tests/t.gd", '_check(not path.contains("assets-ths"), "no external source")')
        self.assertEqual(self.run_check("dev").errors, [])

    def test_missing_target_file_is_reported(self):
        self.records.append(record("a.gone", "gone.png", "original"))
        self.write_manifest()
        self.assertTrue(any("missing on disk: gone.png" in e for e in self.run_check("dev").errors))

    def test_wrong_schema_version_is_rejected(self):
        self.write_manifest(version=1)
        with self.assertRaises(ValueError):
            self.run_check("dev")

    def test_invalid_status_is_rejected(self):
        self.records.append(record("a.weird", "ok.png", "local_only"))
        self.write_manifest()
        with self.assertRaises(ValueError):
            self.run_check("dev")

    def test_main_exit_codes(self):
        self.scene("sense/a.gd", 'var t = load("res://bad.png")')
        args = ["--root", str(self.root), "--quiet"]
        self.assertEqual(cp.main(args + ["--mode", "dev"]), 0)
        self.assertEqual(cp.main(args + ["--mode", "release"]), 1)
        self.write_manifest(version=1)
        self.assertEqual(cp.main(args), 2)


if __name__ == "__main__":
    unittest.main(verbosity=1)
