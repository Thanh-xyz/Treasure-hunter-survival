# Survival RPG slice (branch `feat/survival-rpg`)

Bản dọc (portrait) 2D pixel action-survival RPG, chơi offline, xây trên nền Emberfield
và đang được chỉnh theo bản Treasure Hunter Survival 4.3.6 mà chủ project cung cấp.
Gameplay mở rộng vẫn dùng code/data local của project. Visual pass hiện dùng một bộ
assets tối thiểu đã tuyển chọn từ nguồn XAPK/capture của chủ project để đạt độ giống
cao khi chạy riêng; không đưa toàn bộ kho giải nén 1.7 GB vào repository.

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
| `LanSession` (autoload) | `sense/network/lan_session.gd` | ENet UDP 24567, Host/Join IP, handshake, host relay vị trí/zone, avatar remote nội suy |
| `PixelArt` | `sense/globals/pixel_art.gd` | Sprite ASCII sang ImageTexture cho nội dung chưa có frame nguồn phù hợp |
| THS curated visuals | `assets/treasure_hunter/` | Cây, bụi, gốc cây và Mosqui/Snailu/Astromophy đã tuyển chọn; nearest-neighbor, tổng dung lượng rất nhỏ |
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

1. Thị trấn (hub) → mở Map → **Greenwood Meadow**: Mosqui, dơi, Snailu và Astromophy.
2. Chặt cây / đập đá để lấy wood/stone. Quái rơi gold, potion, pet treat, hero shard.
3. **World boss Mire King** xuất hiện ở bàn thờ theo timer, hoặc gọi ngay bằng cách tương tác với bàn thờ.
4. Về **Homestead** xây Lumber Mill / Quarry / Herb Garden (tự sản xuất theo thời gian thực, kể cả khi offline), Training Hall / Watchtower / Stable (cộng chỉ số).
5. Nâng cấp: chiêu mộ hero (Ironwarden, Thornwind, Ashveil) và lên sao bằng hero shard; cho pet ăn để lên level và tiến hóa; nhận mount (speed / attack / defense) và mua skin.
6. **Crypt Depths** (cổng ở thị trấn): dungeon nhiều phòng, boss Crypt Warden. **Frostvale Ruins** (Lv6+): boss Bone Colossus.
7. Khi chết: chờ 3 giây rồi chọn hồi sinh tại chỗ hoặc về thị trấn. Không mất đồ.

## Màn hình dọc và UI cũ

- Viewport logic 720x1600, cửa sổ kiểm tra 360x800 và camera zoom 2.
- HUD cũ được giữ lại: minimap và loot feed. Thanh HP/stamina cũ và hotbar ngang bị ẩn, thay bằng player card và cụm nút cảm ứng.
- Popup cũ thiết kế cho 1280x720 (shop, blacksmith, crafting) được `MobileHUD._fit_legacy_popup` tự scale cho vừa chiều ngang.

## Wi-Fi/LAN foundation

- Ở màn hình đầu, một máy chọn **Host Wi-Fi**. Máy còn lại nhập IPv4 của host rồi chọn **Join Wi-Fi**.
- Cả hai thiết bị phải cùng mạng Wi-Fi; UDP `24567` cần không bị firewall chặn.
- Đã đồng bộ thật: handshake, kết nối/rời phiên, vị trí/hướng nhân vật, avatar remote, zone và registry/spawn/di chuyển/HP/chết của quái do host quyết định.
- Client gửi yêu cầu đánh theo ID quái; host kiểm tra peer, zone, khoảng cách và cooldown rồi mới tính damage. Client không tự trừ HP quái.
- Loot item/vàng từ quái có ID do host cấp. Item được reserve tới khi client ACK sức chứa: túi đầy giữ nguyên loot, nhặt một phần cập nhật số lượng còn lại, ACK lặp không cộng đồ lần hai. Vàng/XP vẫn commit ngay vì không chiếm ô túi.
- Mỗi peer gửi profile combat được giới hạn; host giữ HP hiện tại, dùng ATK cùng Critical/LifeSteal đã clamp cho hit request, áp dụng DEF/iframe khi quái đánh, quyết định chết và xác nhận hồi sinh tại spawn của map.
- Health potion của client được host xác nhận theo `item_id`; lượng heal luôn tra từ `ItemDatabase`, sau đó host phát HP authoritative. Request bị từ chối sẽ trả potion về túi.
- Khi ngắt LAN, client nạp lại snapshot local an toàn rồi replay cả phần thưởng đã nhận và consumable host đã duyệt, nên không mất loot, không hồi lại potion đã dùng và không ghi nhầm zone mô phỏng.
- Chưa đồng bộ: equipment/crafting/selling, chest/gather/dig, stamina/timed buff, quest theo từng peer, pet/mount và save thế giới.
- Ba harness hai tiến trình: `tests/LanPeerRunner.tscn`, `tests/LanCombatPeerRunner.tscn`, `tests/LanPlayerPeerRunner.tscn`.

## Còn lại (theo roadmap)

- LAN co-op (Milestone 4): transform, enemy/player HP-death-respawn, loot capacity ACK và health consumable authority đã xong; tiếp theo là equipment/crafting/chest/gather/dig authority và reconnect migration.
- Sprite chuyên biệt cho từng hero (hiện là soldier đổi màu), âm thanh, tutorial.
- Cân bằng số liệu: mọi con số nằm trong `GameContent` để chỉnh dễ.

## Visual parity và quyền phân phối

- Nền cỏ giữ màu đo trực tiếp `#3c784a`; cây/bụi/gốc cây đã thay style Emberfield
  bằng pixel art nguồn có viền đen và bóng xanh đậm như capture gốc.
- Mosqui (`31x33`), Snailu (`25x22`) và Astromophy (`38x35`) dùng sprite tuyển chọn
  từ bộ assets người dùng cung cấp; logic AI, HP, va chạm và LAN vẫn do Godot xử lý.
- Bộ này phục vụ bản clone local/private theo yêu cầu. Trước khi phát hành công khai,
  cần xác nhận quyền phân phối hoặc thay bằng assets được cấp phép/tự dựng tương đương.
