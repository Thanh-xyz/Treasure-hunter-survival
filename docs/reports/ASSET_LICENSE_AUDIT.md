# Asset License Audit (SCOUT, 2026-11-07)

## Status vocabulary

| Status | Meaning | Allowed in |
| --- | --- | --- |
| **ORIGINAL** | Created for this project | Everything |
| **VERIFIED** | License text and source on file; terms allow the intended use | Per license terms |
| **UNVERIFIED** | Probably third-party; no license or source on file | Local development only; never a public/commercial build until verified or replaced |
| **PROPRIETARY — EXCLUDED** | Extracted from the reference game's app package or captured from its runtime | Nothing shipped. Remove from runtime paths. |

This audit is not legal advice. It records what evidence exists in the files.

## 1. Evidence found

- No `LICENSE`, `COPYING`, `CREDITS`, `ATTRIBUTION` or similar file anywhere in the repository or
  in `assets-ths` (search excluded `.git`, `.godot` and smali).
- `docs/architecture/asset-manifest.json` already records provenance: 56 Feb-era records as
  `status: unknown / distribution_scope: unknown`, 82 Treasure Hunter records as
  `user_supplied_extracted` or `user_supplied_capture_derived / local_only`.
- `assets-ths` READMEs (`analysis/TreasureHunter_analysis/README_VI.md`,
  `exports/TreasureHunter_UnityPy_images/README_VI.md`, `code-analysis/README.md`) describe the
  content as an apktool + UnityPy + IL2CPP decompilation of *Treasure Hunter Survival 4.3.6*
  (`com.megacombat.treasurehunter`), including analysis of its Pairip / Play Integrity layer.
- Upstream code `HauTranCong/emberfield` is a public GitHub repo with **no license**.
  Origin `Thanh-xyz/Treasure-hunter-survival` is **private**.

## 2. Determination by group

| Group | Files | Status | Reasoning |
| --- | --- | --- | --- |
| `assets-ths/**` | ~51k files | **PROPRIETARY — EXCLUDED** | Unpacked from the reference game's XAPK. The brief (§2) forbids reusing assets extracted from the reference APK/XAPK; the owner's general "authorized" statement cannot grant rights the owner does not hold, and does not override that explicit rule. |
| `assets-ths/code-analysis/configs/*.json` | 21 | **PROPRIETARY — EXCLUDED** | Game data (items, quests, boxes, dialog, language). Do not copy numbers, IDs, text or structures from it. |
| `assets/treasure_hunter/**` | 82 PNG | **PROPRIETARY — EXCLUDED** | Copied from the above, or derived from captures. Replace, then retire. |
| `docs/original-captures/**` | 114 files, 34 MB | **PROPRIETARY — EXCLUDED** | Screenshots/video of the reference game. Never ship; keep private or remove from the repo (owner decision). |
| Reference data embedded in code | `reference_equipment_catalog.gd`, `reward_box_catalog.gd` (Box IDs), `game_content.gd` q305–q311 (IDs + Vietnamese quest text copied from source), `source_card_id` fields | **PROPRIETARY — EXCLUDED** | Copied game data and text. Replace with original content. |
| `assets/tilesets/TX *` | 8 | **UNVERIFIED** | Naming matches Cainos *Pixel Art Top Down – Basic*; source and license not on file. That pack's published terms should be checked for commercial use and redistribution. |
| `assets/soldiers/**` | 12 | **UNVERIFIED** | Third-party style 96×80 sheets; source unknown. |
| `assets/enemies/skeleton_hammer/**` | 25 | **UNVERIFIED** | Source unknown. |
| `assets/items/item_icons.png` | 1 | **UNVERIFIED** | 32×32 fantasy icon sheet; source unknown. |
| `assets/Shop/**` (incl. `.aseprite`) | 6 | **UNVERIFIED** | The `.aseprite` source file suggests it may be team-made (commit `f6ce3d9` "Implement Shop Art" by a team member) — needs confirmation. |
| `assets/blacksmith/**` | 2 | **UNVERIFIED** | Source unknown. |
| `assets/Font/Pixellari.ttf` | 1 | **UNVERIFIED** | Widely distributed free pixel font; license text not on file. |
| `assets/Font/pixel.ttf` | 1 | **UNVERIFIED** | Unknown font identity. |
| `icon.svg` | 1 | **UNVERIFIED** | Appears to be the Godot default project icon (MIT/CC-BY via Godot); confirm and replace with a game icon. |
| `sense/globals/pixel_art.gd` sprites | 25 | **ORIGINAL** | Authored in-repo as ASCII. |
| Upstream Emberfield source code | — | **UNVERIFIED (code)** | Public repo with no license; owner should confirm rights from the upstream team. |

## 3. Required actions before any public or commercial release

1. Owner supplies the source URL / receipt / license text for every UNVERIFIED pack and font; add a
   `CREDITS.md` and per-pack `LICENSE` files under `assets/<pack>/`.
2. Replace every PROPRIETARY — EXCLUDED runtime reference with an original or verified asset, then
   remove the excluded files in an approved PR.
3. Decide on `docs/original-captures/` and the reference-research docs (keep private outside the
   repo, or delete in an approved PR).
4. The private Git history contains the excluded assets. A public release needs either a history
   rewrite (destructive, needs explicit approval) or a fresh repository seeded from a clean tree.
5. Add a provenance gate: a test that fails when any runtime-referenced asset lacks an ORIGINAL or
   VERIFIED record in the manifest, or when anything under `assets/treasure_hunter/` is loaded.
6. Get written confirmation of rights to the upstream `HauTranCong/emberfield` code.

## 4. What may be learned from the reference game

Only publicly documented gameplay ideas (store page, the GDWC listing, the public wiki, the brief's
own description): genre, broad mechanics such as gathering, crafting, pets, mounts, village, PvP,
and the general idea of a treasure key that exposes its carrier. Specific numbers, item/quest/
monster names, IDs, text, map layouts, UI layouts and art must not be taken from the extracted
data, the captures, or the app itself.
