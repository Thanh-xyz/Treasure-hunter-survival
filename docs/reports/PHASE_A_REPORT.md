# Pha A — dữ liệu ô đất, loot và luật spawn

Plan: `docs/plans/BRAINSTORM_CONSOLIDATED_PLAN.md` §4 (owner duyệt 2026-11-08). Branch `feature/phase-a-loot-spawn`.

## Đã làm
- `data/world/dig_tiles.json`: 12 loại ô (4/vùng Meadow, Ash, Snow — phiếu 8 §4.2). Mỗi ô có độ bền, khoảng tái tạo, màu và bảng loot. Độ bền tăng theo vùng; ô di tích hiếm hơn và cứng hơn.
- `data/world/loot_tables.json`: 12 bảng loot theo loại ô. `gold`/`diamonds` cộng thẳng vào tiền tệ thay vì vật phẩm.
- `data/monsters/spawn_rules.json`: Elite 4% mỗi lượt spawn, tối đa 2 Elite/vùng. Mini-boss kiểm tra mỗi 600 s, tỉ lệ 10%, tối đa 1/vùng, hồi 900 s (phiếu 5 §6–7).
- Dịch vụ thuần: `LootTableData` (`sense/items/loot_table_data.gd`), `DigTileCatalog`, `SpawnRules` + `SpawnRules.MiniBossScheduler`.
- `DigSpot` lấy độ bền, thời gian tái tạo, màu và loot theo loại ô. `FieldMap` chọn loại ô theo vùng (Greenwood → meadow, Frostvale → snow); Elite có giới hạn số lượng. Bỏ `GameContent.DIG_*` và `ELITE_CHANCE`.
- Mật độ ô đất: Greenwood 42 → 64, Frostvale 46 → 70 (thời gian tái tạo giờ 45–300 s thay vì 24 s).
- Đổi tên NPC lấy từ game tham chiếu trong phiếu 02/08 (Tamsin, Wren, Pell, Marta). NPC Artifact/Undead hoãn.

## Chưa làm (theo plan)
- Mini-boss: mới có bộ lập lịch và test, chưa nối vào bản đồ (Pha D, cần art và định nghĩa quái).
- Vùng Ash chưa có bản đồ, nên bảng ô Ash mới chỉ có dữ liệu.
- Trạng thái ô đất chưa đồng bộ qua LAN; vẫn là local như trước (phiếu 8 §4.6 → Pha E).
- Loot của quái vẫn nằm trong `GameContent.MONSTERS`; chuyển ra file dữ liệu cùng Pha B (bỏ `hero_shard`).

## Kiểm chứng
- `tools/run_tests.sh`: ALL PASSED (thêm suite `WorldDataTests`: validate dữ liệu, roll tất định, phân phối ±2%, tỉ lệ Elite, giới hạn Elite, lập lịch mini-boss, phần thưởng tiền tệ).
- Release gate vẫn INFO như trước: 29 asset `unverified` cũ.
- Render: `docs/reports/art/phase_a_ground_dig.png`, `phase_a_field.png`.

## Sự cố trong lúc làm
Lúc đầu mình ghi đè nhầm `sense/items/loot_table.gd` (class `LootTable` có sẵn). Đã khôi phục từ git (diff rỗng) và đổi tên class mới thành `LootTableData`.

## Rủi ro
Tỉ lệ loot, độ bền và thời gian tái tạo đều tạm thời, cần chỉnh sau khi chơi thử.

## Bước tiếp theo
Pha B 🔒 (đã duyệt): save v7 — một nhân vật, bỏ cấp/EXP, bỏ Rare (→ Epic), đá ép 8 ô.
