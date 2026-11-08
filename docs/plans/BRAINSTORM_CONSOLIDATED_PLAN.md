# Kế hoạch tổng hợp từ phiếu brainstorm 01–08

Giai đoạn: **PLAN → đã duyệt 2026-11-08**. Nguồn: `docs/design/brainstorm/01…08` (owner điền, commit `8947403`).
Ngày: 2026-11-08.

## 0. Owner duyệt (2026-11-08)

- C1 tên NPC: dùng tên đề xuất (Tamsin, Wren, Pell, Marta; Anbe/Boney hoãn).
- C3/C4 boss: gộp theo đề xuất (chỉ Thẻ triệu hồi + mảnh thẻ).
- §3 save v7: **duyệt cả gói**.
- C2 độ hiếm: **4 bậc, bỏ Rare** (Common/Uncommon/Epic/Legendary). Trong save v7 đồ Rare → Epic
  (không làm người chơi thiệt), ghi `migration_log`; `emberforged_blade` thành Epic.
- C5, C6, C7: áp dụng đề xuất mặc định.

## 1. Quyết định rút ra từ phiếu

| Mảng | Nội dung chốt trong phiếu |
|---|---|
| Nhân vật | Một nhân vật duy nhất (thay hệ 3 hero, mảnh hero, kỹ năng hero). |
| Tiến trình | **Không có cấp nhân vật, không EXP, không thanh kinh nghiệm** (phiếu 8). Sức mạnh đến từ trang bị, đá, pet, mount, chế tạo, khám phá. Mở vùng theo vật phẩm/điều kiện khu vực. |
| Pet | Chỉ cộng chỉ số (không đánh, không kỹ năng); 4 phẩm chất; nâng cấp bằng Diamond tới cấp 10; trùng → Diamond; 1 pet hoạt động; 8 ô đá; 12 loài; trứng. |
| Mount | 8 ô đá; cấp bằng Diamond; tiến hoá hình thái 0–3 theo xác suất khi ép đá; đòn chung `mounted_attack_stomp`; vẽ người chơi trên mount; 6 mount mới. |
| Trang bị | 5 ô × 3 dòng; họ Ironbark (Tank) / Ember (Damage) / Wayfarer (Balanced); tên theo độ hiếm; set vùng 2/4 món (Meadow Guardian, Ashen Warrior, Frostborn Sentinel). |
| Đá ép | 11 loại đá, 4 bậc (Trắng/Xanh/Tím/Vàng); **8 ô đá** trên trang bị, pet, mount; ghép 6→1 cùng loại cùng bậc, không thất bại; tháo đá miễn phí ở khu an toàn, không khi đang chiến đấu. |
| Quái | 4 quái thường mỗi vùng, không dùng chung giữa các vùng; Elite (3–5% thay thế lượt spawn); mini-boss ngẫu nhiên (kiểm tra mỗi 10 phút, 10%, tối đa 1/vùng); Hollowfolk (Ash, theo trại); Blood Ember (sự kiện đêm); Ash Key Hunter. |
| Boss | World Boss theo lịch tại bàn thờ (15 phút); Area Boss; Dungeon Boss; boss triệu hồi bằng thẻ; Final Boss Ember Overlord (Ember Vault); 2–3 giai đoạn; mọi đòn mạnh có vùng cảnh báo; thưởng tham gia + kết liễu + đóng góp; `boss_encounter_id` chống nhận trùng. |
| Thế giới | Hearthfire / The Snuffing / Kindler / làng Hearthmoor / Homestead; Greenwood–Cinderwaste–Frostvale; dungeon Crypt Depths, Gloamdeep Mines, Frozen Sepulchre, Ember Vault. |
| Nhiệm vụ | Chỉ Tutorial (t01–t07, NPC Orla), Season Missions, Daily (d_hunt, d_gather, d_boss). Không nhiệm vụ phụ. |
| Phá ô đất | Gameplay cốt lõi: mật độ cao, 4 loại ô mỗi vùng, độ bền tăng theo vùng, loot table theo loại ô + vùng, tái tạo theo cụm (1–3 phút), host LAN là nguồn chuẩn. |
| Sự kiện | Blood Ember Night, Ashfall, World Boss Hour, Wandering Merchant, Forge Festival, Treasure Surge, Frozen Storm, Ashfall Raid (tuỳ chọn). |

## 2. Mâu thuẫn cần owner chốt

| # | Mâu thuẫn | Đề xuất |
|---|---|---|
| C1 | Phiếu 2/8 dùng tên NPC lấy từ game tham chiếu: **Donx, Kai, Mirai/Mira, Diana, Anbe, Boney** — vi phạm quy tắc nguyên bản. | Giữ chức năng, đổi tên: Donx → **Tamsin** (ghép đá), Kai → **Wren** (nhiệm vụ mùa), Mirai → **Pell** (hộp quà), Diana → **Marta** (đổi điểm Arena). Anbe (Artifact) và Boney (khu Undead) hoãn vì hai hệ thống đó chưa có trong thiết kế. |
| C2 ✅ 4 bậc | Phiếu 7 ghi "4 độ hiếm" (Common/Uncommon/Epic/Legendary) nhưng chính phiếu vẫn dùng **Rare** (Emberforged Blade, bảng nguồn). Code hiện có 5 bậc. | Giữ **5 bậc** trang bị (Common → Legendary). Đá ép giữ 4 bậc. |
| C3 | Boss chồng chéo: phiếu 5 có 3 boss triệu hồi bằng **Seal** (Verdant Treant, Infernal Golem, Frost Titan); phiếu 6 có Verdant Treant là **World Boss** Meadow nhưng lịch World Boss lại dùng Mire King; thẻ triệu hồi trỏ tới Root Guardian / Ash Destroyer / Snow Titan / Ancient Dragon, còn mục 7.5 lại là Ash Devourer / Frost Abyss King. | Một hệ thống triệu hồi duy nhất: **Boss Summon Card + mảnh thẻ** (Seal gộp vào Card). World Boss: Mire King (Meadow), Infernal Dragon (Ash), Frost Leviathan (Snow). Boss thẻ: Verdant Treant (Rare), Ash Devourer (Epic), Frost Abyss King (Epic), Ancient Dragon (Legendary), Ember Overlord (Legendary). Bỏ Infernal Golem, Frost Titan, Root Guardian, Ash Destroyer, Snow Titan (trùng vai trò). |
| C4 | Dungeon: phiếu 6 đặt Hollow Root Queen (Root Temple) / Obsidian Titan (Ash Depths) / Glacier King (Glacier Sanctum); phiếu 8 đặt Crypt Depths / Gloamdeep Mines / Frozen Sepulchre, và Crypt Warden đã là boss Crypt Depths. | Theo phiếu 8: Crypt Depths → Crypt Warden; Gloamdeep Mines → Obsidian Titan; Frozen Sepulchre → Glacier King. Hollow Root Queen chuyển thành Area Boss thứ hai của Meadow (hoặc hoãn). |
| C5 | Phiếu 6 §9 đề xuất Snow "không mất vĩnh viễn vật phẩm quý", trái với quyết định đã chốt (bị quái hạ → mất món rơi). | Giữ **quyết định đã chốt** của owner. |
| C6 | Phiếu 4: mount "Kỹ năng riêng: không" nhưng lại mô tả đòn riêng. | Chỉ dùng `mounted_attack_stomp` chung; khác biệt mount nằm ở chỉ số, tốc độ và hình thái. |
| C7 | Vùng ghi "Level 1–15 / 15–30 / 30–45" trong khi phiếu 8 bỏ cấp nhân vật. | Con số chỉ còn là **cấp quái / bậc độ khó**, không phải cấp người chơi. |

## 3. Thay đổi 🔒 (cần duyệt riêng — đổi save)

Gộp vào **một** lần nâng save **v6 → v7** để chỉ migrate một lần:

1. **Một nhân vật**: bỏ hero roster, mảnh hero, kỹ năng hero (`hero_skill_runner.gd`). Tài nguyên hero đã có được quy đổi Diamond/Gold và ghi `migration_log`; không xoá im lặng.
2. **Bỏ cấp và EXP người chơi**: xoá level/EXP khỏi `game_state`, HUD, quest; chỉ số nền cố định; phần thưởng EXP cũ đổi sang Gold (ghi log).
3. **Bỏ độ hiếm Rare**: đồ Rare → Epic, `balance.json` còn 4 bậc.
4. **Đá ép 8 ô** thay hệ augment hiện tại (`applied_augments`, `augment_panel`): augment đã gắn trả về túi như đá tương ứng hoặc Gold nếu không có tương ứng (theo mẫu `_return_augments` của v6).
5. Pet/mount nhận mảng 8 ô đá rỗng; trường cấp pet/mount giữ nguyên.

LAN `PROTOCOL_VERSION` tăng tương ứng. Có fixture save v6 → v7 và test mất dữ liệu = 0.

## 4. Thứ tự triển khai đề xuất

| Pha | Nội dung | Save | Ghi chú |
|---|---|---|---|
| **A** | Lớp dữ liệu & dịch vụ thuần: `data/loot/` (drop table, loot ô đất theo vùng), `data/monsters/spawn.json` + Elite config, `LootService`/`SpawnDirector` thuần + test. Đổi tên hiển thị NPC (C1) và tên trang bị theo phiếu 7. | Không | An toàn, làm ngay sau khi duyệt. |
| **B 🔒** | Save v7: một nhân vật, bỏ level/EXP, đá ép 8 ô + ghép 6→1 + UI tháo/lắp. | v7 | Cần duyệt §3. |
| **C** | Pet (stat-only, 12 loài, trứng, Diamond) và mount (cấp, đá, hình thái, stomp). | dùng v7 | Cần art pet/mount (pha F). |
| **D** | Combat: Elite, mini-boss ngẫu nhiên, vùng cảnh báo đòn, hiệu ứng Burn/Slow/Freeze, roster quái mới mỗi vùng. | Không | Phụ thuộc A. |
| **E** | Boss: World Boss theo lịch, thẻ triệu hồi + mảnh, boss nhiều giai đoạn, thưởng tham gia/kết liễu, encounter id (offline + LAN host). | Có thể thêm trường | Phụ thuộc D. |
| **F** | Art free CC0: nhân vật/NPC/pet/mount, tileset thay TX, UI/icon từ Ninja Adventure Items, font, audio. Món thiếu ghi `NEEDS_ASSET`. | Không | Song song. |
| **G** | Sau: Season Missions, Hollowfolk, Blood Ember, Kindled Key + Ash Key Hunter, Homestead, Ashfall Raid, dungeon mới, Ember Vault. | Tuỳ | Từng mục lên plan riêng. |

## 5. Art còn thiếu (cần tìm nguồn CC0, không tự vẽ)

Ash Hound, Whitefang Wolf, Glacier Bear, Frost Shaman, Hollowfolk ×4, Rootfang, Ash Tyrant, Frosthorn, Glacial Colossus, Verdant Treant, Ancient Mossback, Infernal Dragon, Frost Leviathan, Obsidian Titan, Glacier King, Ember Overlord, Ash Devourer, Frost Abyss King, Ancient Dragon. Bước đầu: tra trong pack Ninja Adventure đã có (`<scratchpad>/asset_src/ninja`) trước, rồi mới tìm pack CC0 khác. Biến thể Elite dùng shader đổi màu + scale, không cần sprite mới.

## 6. Rủi ro

- Pha B đụng nhiều file (`game_state`, `player`, `quest_service`, `save_service`, HUD, menu, LAN) → chia commit nhỏ, chạy đủ bộ test + 3 harness LAN.
- Bỏ level ảnh hưởng cân bằng sát thương quái hiện tại → cần bảng chỉ số nền mới trong data.
- Thiếu art lớn cho boss/quái mới → nội dung chạy được trước bằng sprite tạm có provenance hợp lệ, đánh dấu `NEEDS_ASSET`, không coi là hoàn thành.
