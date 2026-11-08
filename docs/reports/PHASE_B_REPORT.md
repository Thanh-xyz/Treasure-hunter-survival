# Pha B — save v7: đá ép 8 ô, một nhân vật, bỏ cấp/EXP, bỏ Rare

Plan: `docs/plans/BRAINSTORM_CONSOLIDATED_PLAN.md` §3 (🔒, owner duyệt cả gói 2026-11-08).
Branch `feature/phase-b-save-v7` (tách từ `feature/phase-a-loot-spawn`).

## Đã làm

### Độ hiếm (C2)
- Trang bị còn 4 bậc: common / uncommon / epic / legendary (`data/equipment/balance.json`, hệ số 1.0 / 1.3 / 1.75 / 2.3).
- `EquipmentBalance.rarity_enum` / `rarity_name` ánh xạ theo tên, không theo vị trí trong danh sách.
- `emberforged_blade` thành Epic. Save chỉ lưu id, nên đồ Rare cũ tự lên Epic.
- Vật liệu (không phải trang bị) vẫn có thể là Rare.

### Đá ép (phiếu 07 §4)
- `data/gems/gems.json`: 11 loại × 4 bậc (I–IV, màu trắng / xanh dương / tím / vàng), mỗi trang bị 8 ô, ghép 6 → 1, có giới hạn chỉ số.
- `GemCatalog` (thuần):
  - giá trị = base × hệ số bậc (1 / 3 / 8 / 20; luôn < 6× bậc dưới, nên ghép là một kênh tiêu hao);
  - giới hạn: crit 60%, crit dmg 200%, hút máu 20%, né 40%, phản 50%, làm chậm 60%;
  - DEF giảm sát thương theo `def ÷ (def + 150)`, tối đa 75%, mỗi đòn tối thiểu 1 sát thương.
- `InventoryData.socket_gem / unsocket_gem / fuse_gems`: mỗi thao tác là một giao dịch, nên đá không mất và không bị nhân đôi; túi đầy thì không tháo được.
- Combat:
  - Guardian Stone cộng DEF.
  - Crit, crit dmg, hút máu, cháy, làm chậm, độc và phản sát thương đi qua `PassiveEffectProcessor`.
  - Mới thêm: né đòn (`Combat.roll_dodge`), crit dmg (`Combat.roll`), hồi máu (`tick_regeneration`).
  - LAN host nhận thêm crit dmg / né / hồi máu từ profile của client, áp DEF bằng `GemCatalog.mitigate` và tự hồi máu cho peer. `PROTOCOL_VERSION` 7.
- `GemPanel` (thay `AugmentPanel`): 8 ô, bấm để tháo, đá trong túi có nút "Fuse 6 to 1". Khoá thao tác khi có quái trong 160 px. Ảnh: `docs/reports/art/phase_b_gem_panel.png`.
- Công thức chế: 6 công thức tạo đá bậc I (cháy, băng, độc, hút máu, crit, giáp); bậc cao hơn chỉ có qua ghép.
- Augment cố định và rune skill bị bỏ. `SkillComponent` / `SkillExecutor` được giữ cho ô "special skill" sau này, hiện chưa có nguồn skill.

### Một nhân vật, không cấp/EXP (phiếu 01, 08)
- `GameContent.PLAYER_BASE` = HP 150, ATK 12, DEF 0, SPD 120.
- Bỏ: `HEROES`, `HERO_SKILLS`, `MAX_LEVEL`, `xp_to_next`, `HeroSkillRunner`, input `hero_skill_1..3`, mảnh hero, EXP khi giết quái, EXP qua LAN.
- Bỏ khoá cấp của mount và bản đồ. Vùng giờ hiện "Monster level N".
- Tab "Heroes" thành "Character": chỉ số thật + chỉ số từ đá.
- Nhiệm vụ: bỏ EXP khỏi thưởng. q14 thành "Stone Setter" (ép 3 viên đá; objective mới `socketed_gems`). Thưởng `hero_shard` đổi sang đá. Quái/boss rơi đá thay mảnh hero.

### Save v7 (`SaveService._migrate_to_v7`)
- Augment trong túi, trên trang bị và trong Lost & Found được đổi thành đá cùng loại, cùng bậc:
  - flame → fire, frost → ice, crit → critical, lifesteal → lifesteal, power → critical_damage.
- Rune whirlwind / shield bash hoàn 200 vàng; `hero_shard` hoàn 60 vàng mỗi mảnh.
- Profile bỏ `level/xp/hero_id/heroes` và ghi vào `migration_log`. EXP trong claim đang chờ đổi sang vàng 1:1.
- Level/EXP sai kiểu bị coi là save hỏng (dùng backup), không bị xoá im lặng.
- Fixture mới `v6_stones_and_heroes.json` cùng test round-trip.

## Kiểm chứng
- `tools/run_tests.sh`: **ALL PASSED** (runB3). Không còn `SCRIPT ERROR` hay `Assertion failed` trong log.
- Release gate: INFO như trước (29 asset `unverified` cũ). Dòng `excluded=1` là fixture của unit test provenance.
- Render: `phase_b_gem_panel.png`, `phase_b_mobile_hud.png`.

## Chưa làm / rủi ro
- Icon đá đang dùng tạm icon "diamond" cho mọi loại → `NEEDS_ASSET`, chờ icon Items của Ninja Adventure (pha F).
- 8 ô đá cho pet/mount: dữ liệu và tính toán đã hỗ trợ (`get_gem_stats(extra_socket_arrays)`), nhưng chưa có ô trên pet/mount (pha C).
- Tutorial t06 theo phiếu 8 ("ép đá") chưa đổi; hiện là q14.
- Accuracy mới chỉ có tác dụng trừ né (PvP), vì quái không né.
- Bỏ cấp làm thay đổi cân bằng: chỉ số nền cố định, quái Frostvale có thể khó hơn trước. Cần chơi thử.
- Người chơi mất 3 kỹ năng hero và 2 rune skill cho tới khi có "special skill".
