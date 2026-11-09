# Pha D — Combat: đội hình theo vùng, hiệu ứng trạng thái, cảnh báo đòn, Elite, mini-boss

Plan: `docs/plans/BRAINSTORM_CONSOLIDATED_PLAN.md` §4 pha D; phiếu 05 (quái), 06 §6.2 (tên Elite). Owner xác nhận 2026-11-09.
Branch `feature/phase-d-combat` (tách từ `feature/phase-c-pets-mounts`). Không đổi save.

## Đã làm

### Đội hình theo vùng (phiếu 05 §4, §16)
| Vùng | Bản đồ | 4 quái thường | Mini-boss |
|---|---|---|---|
| Meadow | Greenwood | Meadow Slime, Dusk Bat, Bramble Snake, Bristle Boar (+ Mosscap Guardian hiếm) | Slime Monarch, Rootfang |
| Ash | **Cinderwaste (mới)** | Magma Flame, Bone Grunt, Bone Archer, **Ash Hound** | Cinder Warlord, Ash Tyrant |
| Snow | Frostvale | Frost Wisp, **Whitefang Wolf**, **Glacier Bear**, **Frost Shaman** | Frosthorn, Glacial Colossus |

- Không quái thường nào xuất hiện ở hai vùng. HP và sát thương trung bình tăng dần Meadow < Ash < Snow (có test).
- Cinderwaste là bản đồ field mới, sinh từ `FieldMap` + dữ liệu `ZONES`, có 4 loại ô đất Ash. Bản đồ đồng tâm liền mạch vẫn là việc riêng (R15).
- Nhiệm vụ q12 đổi đích đến từ Frostvale sang Cinderwaste cho đúng thứ tự vùng (id giữ nguyên).
- Tên Elite theo phiếu 06.2: Alpha Bristle Boar, Ancient Mosscap, Cinder Bone Knight, Infernal Hound, Frostfang Alpha, Ancient Glacier Bear.

### Hiệu ứng trạng thái (`StatusEffects`, `data/combat/statuses.json`)
- Cháy và độc gây sát thương mỗi giây, xuyên DEF. Chậm và đóng băng giảm tốc chạy (tối đa 60% và 90%).
- Áp lại cùng hiệu ứng thì lấy mức mạnh hơn và thời gian dài hơn, không cộng dồn.
- Quái gây hiệu ứng qua `on_hit` (đánh gần và đạn):
  - Bramble Snake → độc;
  - Ash → cháy;
  - Snow → chậm hoặc đóng băng.
- Người chơi đổi màu và hiện chữ tên hiệu ứng; chết thì xoá hết hiệu ứng.
- LAN: máy host giữ hiệu ứng cho từng client và tự trừ máu khi cháy/độc. **Chưa** gửi hiệu ứng chậm cho client (client tự điều khiển di chuyển).

### Đòn có cảnh báo (phiếu 05/06: đòn mạnh luôn báo trước)
- `slam`: vòng đỏ dưới chân quái đầy dần trong `warn` giây; chỉ gây sát thương khi vòng đầy (có test).
- Dùng cho Glacier Bear và mọi mini-boss. Lao húc (charger) vẫn dùng đường đỏ báo trước như cũ.

### Hỗ trợ và triệu hồi
- Frost Shaman: mỗi 5 giây che chắn quái gần đó, giảm 20% sát thương chúng nhận trong 3 giây (có vòng xanh).
- Slime Monarch tách ra 3 slime khi còn nửa máu; Cinder Warlord gọi 2 Bone Grunt. Mỗi con chỉ gọi một lần.

### Elite (phiếu 05 §6)
- Đã có từ trước: to hơn 25%, HP ×2.6, sát thương ×1.5. Mới thêm:
  - vòng sáng vàng nhấp nháy, thanh máu dài hơn;
  - thông báo và vòng sáng khi xuất hiện;
  - thêm một lượt rơi đồ từ bảng `elite_bonus` (đá bậc I, Power Fragment).
- Vẫn giữ 4% mỗi lượt sinh quái, tối đa 2 con mỗi vùng (Pha A).

### Mini-boss ngẫu nhiên (phiếu 05 §7)
- `FieldMap` dùng `SpawnRules.MiniBossScheduler`: kiểm tra mỗi 10 phút với tỉ lệ 10%, tối đa 1 con mỗi vùng, hồi 15 phút sau khi chết.
- Xuất hiện cách điểm an toàn ≥ 400 px, có thông báo.
- Thưởng: rơi đồ riêng + bảng thưởng theo vùng (`mini_boss_meadow/ash/snow`: đá bậc II–III, trang bị, trứng; Snow có 5% trứng rồng).

### Art (CC0 Ninja Adventure, đã đăng ký provenance)
5 sprite mới: Bear, Spirit, Beast, Reptile2, Panda. Sprite tạm được ghi `NEEDS_ASSET`:
- Ash Hound: linh cẩu nhuộm.
- Whitefang Wolf: chó trắng.
- Glacier Bear: panda.
- Rootfang: reptile.
- Ash Tyrant: beast.
- Frosthorn: beast nhuộm băng.
- Glacial Colossus: panda nhuộm.

Slime Monarch và Cinder Warlord là sprite gốc phóng to và nhuộm màu.

## Kiểm chứng
- `tools/run_tests.sh`: **ALL PASSED** (runD2), thêm suite `CombatTests`: đội hình, hiệu ứng trạng thái, tỉ lệ on-hit, đòn giậm có báo trước, che chắn, triệu hồi, Elite, mini-boss.
- Cảnh báo harness đã biết: "ObjectDB instances leaked at exit" (cả ở Legacy/Survival/InventoryTransaction) và "RID allocations leaked" khi render. Không ảnh hưởng kết quả.
- Render: `docs/reports/art/phase_d_cinderwaste.png`, `phase_d_frostvale.png` — mini-boss đang báo trước đòn giậm, Elite phát sáng, người chơi bị Cháy/Chậm.

## Chưa làm / rủi ro
- Nền đất Cinderwaste/Frostvale vẫn là tileset cỏ nhuộm màu → thay tileset ở pha F.
- Client LAN chưa bị làm chậm thật (chỉ máy host và chơi offline).
- Hollowfolk, Blood Ember, Ash Key Hunter, hành vi ban đêm của Dusk Bat → pha G.
- Hành vi chi tiết từng con theo phiếu (sói gọi bầy, cung thủ bắn hai phát, vũng dung nham khi chết) chưa làm; hiện dùng các AI chung kèm hiệu ứng.
- Mọi chỉ số đều là đề xuất, cần cân bằng; bỏ cấp nhân vật nên vùng Snow có thể rất khó lúc đầu.
