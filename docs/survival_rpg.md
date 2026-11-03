# Survival RPG slice (branch `feat/survival-rpg`)

Bản dọc (portrait) 2D pixel action-survival RPG, chơi offline, xây trên nền Emberfield.
Cơ chế lấy cảm hứng từ thể loại (hero / pet / mount / boss / quest / xây làng).
Toàn bộ tên, nhân vật, quái và đồ họa mới đều là bản gốc của dự án: dùng asset
sẵn có của Emberfield cộng với pixel art ASCII sinh lúc chạy (`PixelArt`).

## Cách chạy

| Việc | Lệnh |
| --- | --- |
| Chơi (desktop, cửa sổ dọc 450x800) | `godot --path .` |
| Test toàn bộ (legacy + survival) | `godot --headless --path . res://tests/LegacySystemTests.tscn` |
| Chỉ test survival | `godot --headless --path . res://tests/SurvivalTests.tscn` |

Phím trên desktop: WASD/mũi tên để di chuyển, A để đánh (giữ phím = đánh liên tục),
Z/X/C cho skill hero, Q/E/R/F cho skill trang bị, G cho gear skill, H để uống potion,
M để lên/xuống mount, E để tương tác, B mở túi đồ, Esc đóng menu.
Chuột được giả lập thành cảm ứng (`emulate_touch_from_mouse`), nên có thể click
thẳng vào joystick và các nút.

## Kiến trúc mới

| Thành phần | File | Vai trò |
| --- | --- | --- |
| `GameContent` (class) | `sense/globals/game_content.gd` | Dữ liệu tĩnh: heroes, skills, pets, mounts, monsters, zones, buildings, quests, đường cong XP |
| `GameState` (autoload) | `sense/globals/game_state.gd` | Profile: level/XP, hero, pet, mount, ô đất xây dựng, bộ đếm; tổng hợp chỉ số; spend/grant |
| `QuestService` (autoload) | `sense/globals/quest_service.gd` | Chuỗi quest chính 15 nhiệm vụ + 3 daily, nghe domain event |
| `SaveService` (autoload) | `sense/globals/save_service.gd` | JSON có version, ghi atomic, có `.bak`, autosave 60s, khi đổi zone và khi app pause/đóng |
| `PixelArt` | `sense/globals/pixel_art.gd` | Sprite ASCII sang ImageTexture, đổi màu bằng palette |
| Combat | `sense/combat/` | `Combat` (helper), `Projectile`, `Telegraph` (vòng cảnh báo AoE), `DamageNumber`, `RingFX`, `HeroSkillRunner` |
| Quái | `sense/entities/enemies/monster/` | `Monster` (melee / flyer / ranged / charger, elite), `Boss` (2 phase: slam, leap, nova, summon) |
| Pet | `sense/entities/pets/pet_follower.gd` | Đi theo, tấn công, hồi máu, tiến hóa ở Lv5/Lv10 |
| Field | `sense/maps/field/` | `FieldMap` sinh map xác định theo seed: cỏ, đường đá, cây, đá, bãi quái respawn, bàn thờ world boss, cổng |
| Homestead | `sense/maps/homestead/` | 6 ô đất xây công trình |
| Mobile UI | `sense/ui/mobile/` | `MobileHUD`, `VirtualJoystick`, `ActionButton` (multi-touch), `GameMenu` (Hero/Pet/Mount/Quest/Map/Village/System), `UiTheme` |

Các domain event mới trong `GameEvent`: `enemy_killed`, `resource_gathered`,
`zone_entered`, `building_built`, `player_died/respawned`, `boss_*`,
`world_boss_timer`, `toast`, `open_menu`.

## Gameplay loop

1. Thị trấn (hub) → mở Map → **Greenwood Meadow**: slime, dơi, nấm bắn đạn, heo rừng lao tới.
2. Chặt cây / đập đá để lấy wood/stone. Quái rơi gold, potion, pet treat, hero shard.
3. **World boss Mire King** xuất hiện ở bàn thờ theo timer, hoặc gọi ngay bằng cách tương tác với bàn thờ.
4. Về **Homestead** xây Lumber Mill / Quarry / Herb Garden (tự sản xuất theo thời gian thực, kể cả khi offline), Training Hall / Watchtower / Stable (cộng chỉ số).
5. Nâng cấp: chiêu mộ hero (Ironwarden, Thornwind, Ashveil) và lên sao bằng hero shard; cho pet ăn để lên level và tiến hóa; nhận mount (speed / attack / defense) và mua skin.
6. **Crypt Depths** (cổng ở thị trấn): dungeon nhiều phòng, boss Crypt Warden. **Frostvale Ruins** (Lv6+): boss Bone Colossus.
7. Khi chết: chờ 3 giây rồi chọn hồi sinh tại chỗ hoặc về thị trấn. Không mất đồ.

## Màn hình dọc và UI cũ

- Viewport logic 720x1280, camera zoom 3 (nhìn thấy khoảng 240 px thế giới theo chiều ngang).
- HUD cũ được giữ lại: minimap và loot feed. Thanh HP/stamina cũ và hotbar ngang bị ẩn, thay bằng player card và cụm nút cảm ứng.
- Popup cũ thiết kế cho 1280x720 (shop, blacksmith, crafting) được `MobileHUD._fit_legacy_popup` tự scale cho vừa chiều ngang.

## Còn lại (theo roadmap)

- LAN co-op (Milestone 4): đã tách sẵn dữ liệu (content ID ổn định, seed map xác định, domain event) nhưng chưa có ENet.
- Sprite chuyên biệt cho từng hero (hiện là soldier đổi màu), âm thanh, tutorial.
- Cân bằng số liệu: mọi con số nằm trong `GameContent` để chỉnh dễ.
