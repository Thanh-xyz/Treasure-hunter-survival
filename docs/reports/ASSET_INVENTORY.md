# Asset Inventory (SCOUT, 2026-11-07)

Covers the repository's `assets/` folder, the runtime-generated sprites, and the external library
`/home/thanh/Documents/1.Projects/assets-ths`. License status for every row is in
[ASSET_LICENSE_AUDIT.md](ASSET_LICENSE_AUDIT.md). Per-file metadata for repository assets already
exists in `docs/architecture/asset-manifest.json` (138 records); this report summarises it and
adds the external library.

## 1. Repository assets — usable candidates

| Path | Format | Dimensions / layout | Frames | Intended use | Related system | License |
| --- | --- | --- | --- | --- | --- | --- |
| `assets/tilesets/TX Tileset Grass.png` | PNG | 256×256 | — | ground tiles | World | UNVERIFIED |
| `assets/tilesets/TX Tileset Stone Ground.png` | PNG | 256×256 | — | paths/floors | World | UNVERIFIED |
| `assets/tilesets/TX Tileset Wall.png` | PNG | 512×512 | — | walls | World/Dungeon | UNVERIFIED |
| `assets/tilesets/TX Plant.png`, `TX Shadow Plant.png` | PNG | 512×512 | — | trees, bushes + shadows | World/Gathering | UNVERIFIED |
| `assets/tilesets/TX Props.png`, `TX Struct.png`, `TX Shadow.png` | PNG | 512×512 | — | props, structures, shadows | World/Village | UNVERIFIED |
| `assets/soldiers/{idle,walk,attack}/*` | PNG strips | 768×80 → 8 × 96×80 | 8 per dir, 4 dirs | player / heroes (recoloured) | Character | UNVERIFIED |
| `assets/enemies/skeleton_hammer/**` (25) | PNG strips | 1024×128 → 8 × 128×128 | 8 dirs idle/walk/attack + death | skeleton enemies, crypt bosses (tinted) | Enemies | UNVERIFIED |
| `assets/items/item_icons.png` | PNG sheet | 512×867, 32×32 cells, 16 columns | — | item icons via `ItemIconAtlas` | Items | UNVERIFIED |
| `assets/Shop/General-shop/*` | PNG + `.aseprite` | Merchant 96×32 (3 frames), cart 64×64 | 3 | merchant NPC | NPC/Shop | UNVERIFIED |
| `assets/Shop/UI-element/*` | PNG | coin 32×32, panel 128×128, row 54×12 | — | shop UI | UI | UNVERIFIED |
| `assets/blacksmith/black_smith_objects.png` | PNG | 1024×1536 | — | forge building/objects | NPC/Crafting | UNVERIFIED |
| `assets/blacksmith/fire_frames.png` | PNG | 1024×1024 | animated | forge fire | VFX | UNVERIFIED |
| `assets/Font/Pixellari.ttf`, `pixel.ttf` | TTF | — | — | all UI text | UI | UNVERIFIED |

## 2. Runtime-generated original sprites (`sense/globals/pixel_art.gd`)

ASCII rows + palettes → `ImageTexture`, cached. License: **ORIGINAL (project-owned)**.

| Group | Sprite IDs |
| --- | --- |
| Monsters | `slime` (frost / magma / king palettes), `bat`, `boar`, `mushroom`, `mosquito`, `snail` |
| Pets | `pet_fox`, `pet_turtle`, `pet_owl`, `pet_cat` |
| Mounts | `mount_pony`, `mount_stag`, `mount_boar`, `mount_tortoise` |
| World | `altar`, `plot`, `field_stump` |
| HUD glyphs | `hud_helmet`, `hud_heart`, `hud_sword`, `hud_boot`, `hud_world`, `hud_coin` |
| Misc | `bolt`, `unknown`, plus a generated starter-avatar `SpriteFrames` (`make_guest_frames`) |

Note: `mosquito` and `snail` were drawn to stand in for reference monsters (Mosqui, Snailu). The
pixels are original, but names, roles and stats tied to them should be redesigned in BRAINSTORM.

## 3. Repository assets — reference-derived (exclude and replace)

All in `assets/treasure_hunter/` (82 PNG, ~1.3 MB), provenance `user_supplied_extracted` or
`user_supplied_capture_derived`, scope `local_only`.

| Path | Count | Content |
| --- | --- | --- |
| `field/` | 4 | bush, stump, tree cluster, medium tree |
| `monsters/` | 7 | Astromophy, Mosqui (+atlas), Snailu (+atlas), Turtle atlas + icon |
| `npcs/donx/` | 2 | Donx icon and portrait |
| `items/weapons/` | 3 | Card 28–30 weapon icons |
| `items/ingredients/` | 3 | Card 64/66/69 stone icons |
| `items/potions/` | 6 | Card 900–905 elixir icons |
| `ui/reference/` | 57 | buttons, frames, hotbar, joystick, icons, panels |

## 4. External library `assets-ths` (1.7 GB) — reference-derived, excluded

| Path | Content | Size / count |
| --- | --- | --- |
| `source/` | `com.megacombat.treasurehunter_4.3.6.xapk`, `Treasure+Hunter+-+MMORPG_4.3.6_APKPure.xapk` | 2 × ~190 MB |
| `analysis/TreasureHunter_analysis/decoded/` | apktool-decoded base + arm64 split APK | 22,648 smali, 449 XML, 9 `.so` |
| `analysis/.../extracted_images/` | Android raster/vector drawables, contact sheet, inventory CSV | 331 PNG + 1 JPEG, 97 XML |
| `analysis/.../unity_bundle_file_list.txt` | list of Unity Addressables bundles | 4,687 bundles |
| `exports/TreasureHunter_UnityPy_images/unity_data/` | UnityPy textures + atlas sprites from `assets/bin/Data` | 16,216 PNG |
| `exports/TreasureHunter_UnityPy_images/addressables/` | UnityPy textures + sprites from bundles | 7,289 PNG |
| `code-analysis/configs/` | Extracted gameplay JSON (Arena, Box, Card, Item, Quest, Dialog, Language, RemoteConfig, ServerInfo…) | 21 files |
| `code-analysis/native/`, `android/`, `tables/`, `reports/` | IL2CPP metadata strings, RPC identifiers, Pairip / Play Integrity analysis, MonoBehaviour tables | — |
| `scripts/` | Extraction/analysis Python scripts | 4 |

Coarse keyword classification of the 23,505 UnityPy images (heuristic on asset names, not
verified): character/monster parts ~7,700, UI ~1,000, item/equipment ~770, VFX ~340, environment
~270, unclassified ~13,400. Naming is `<UnityAssetName>__<PathID>.png`.

No audio, font, or tileset in this library is usable for the original game.

## 5. Gaps — assets the game still needs

| Need | Have now | Gap |
| --- | --- | --- |
| Player/hero animation sets (idle, walk, run, attack, hurt, death, gather, interact, skill) | soldier (idle/run/attack, 4 dir) | hurt, death, gather, interact, skill; distinct look per hero |
| Biome tilesets: grassland, forest, cave, ruins, mountain, danger zone | 1 grass/stone/wall set | 4–5 biome sets |
| Resource nodes: trees, ore tiers, herbs, crops, rare plants | trees/rocks (TX + extracted) | ore tiers, herbs, crops, rare nodes; replace extracted field props |
| Monsters per biome + bosses | skeleton, ASCII slimes/bat/boar/mushroom/insects | full roster with animations; boss art |
| NPCs | merchant, blacksmith | village roster; replace Donx |
| Item icons incl. Mythic | 32×32 sheet | Mythic frame, new categories; replace 12 extracted icons |
| UI kit | shop UI + extracted reference kit | complete original HUD/menu kit |
| Treasure: chests, keys, maps | dig plots, chest pickups | key/map/marked-carrier visuals |
| Village buildings, walls, towers, traps | blacksmith set, TX structures | buildings with upgrade tiers |
| VFX | fire, ring FX, telegraphs | hit sparks, gather particles, level-up, loot glow |
| Audio | none | all music and SFX |
| Branding | `icon.svg` | logo, store icon |
