# Pha C — Pet và Mount (save v8)

Plan: `docs/plans/BRAINSTORM_CONSOLIDATED_PLAN.md` §4 pha C; phiếu 03 (pet), 04 (mount). Owner xác nhận 2026-11-09.
Branch `feature/phase-c-pets-mounts` (tách từ `feature/phase-b-save-v7`).

## Đã làm

### Pet (phiếu 03 §2)
- Dữ liệu `data/companions/pets.json`: 12 loài × 4 phẩm chất = 48 biến thể; mỗi bản ghi có khoá `"<loài>:<phẩm chất>"`.
- Pet chỉ cộng chỉ số, không đánh, không hồi máu, không có kỹ năng. `PetFollower` đã bỏ toàn bộ code combat; có test kiểm tra điều này.
- Phẩm chất độc lập với loài: hệ số 1.0 / 1.4 / 2.0 / 3.0, thể hiện bằng vòng màu dưới chân pet. Không có sao, không có tiến hoá.
- Lên cấp bằng kim cương tới cấp 10 (bảng 5 → 100 kim cương). Mỗi lần tiêu kim cương đều có hộp xác nhận.
- Pet trùng đổi sang kim cương: 2 / 5 / 15 / 40.
- Chỉ 1 pet hoạt động. Mỗi pet có 8 ô đá, dùng chung hệ đá với trang bị.
- 4 loại trứng (Forest, Ash, Snow, Dragon):
  - có giá mua, tỉ lệ ra loài và phẩm chất ghi trong file dữ liệu;
  - **màn hình hiện tỉ lệ**;
  - nở trứng là một giao dịch (trừ trứng + thêm pet hoặc cộng kim cương).
- Nguồn trứng: cửa hàng trong menu Pet, rơi từ boss (Mire King, Crypt Warden, Cinder Colossus), đào đất (ô rễ cây Meadow, di tích Ash/Snow), thưởng nhiệm vụ q04.
- `pet_treat` bị bỏ vì pet không ăn để lên cấp. Các chỗ từng rơi `pet_treat` giờ rơi nguyên liệu, đá hoặc trứng.

### Mount (phiếu 04)
- `data/companions/mounts.json`: 10 mount (4 cũ + 6 mới), mở bằng vàng hoặc kim cương, không cần cấp nhân vật.
- Lên cấp (huấn luyện) bằng kim cương tới cấp 10. Mỗi mount có 8 ô đá.
- **Tiến hoá hình thái 0 → 3** khi ép đá thành công:
  - tỉ lệ 5 / 8 / 12 / 18 / 25% theo số đá sau khi ép;
  - không mất đá khi tiến hoá; tháo đá không làm lùi hình thái;
  - mỗi hình thái thêm 6% chỉ số, đổi màu và có hào quang nguyên tố. Không vẽ sprite mới.
- Đòn giậm chung `mounted_attack_stomp` (prepare → rear_up → stomp → impact → recover) cho mọi mount. Có cooldown, không chồng nhiều lần.
- Mọi mount đều đánh được: bỏ luật cũ "mount tốc độ tự xuống khi đánh". Không có chiêu riêng (quyết định C6).
- Người chơi được vẽ ngồi trên mount. Skin là danh sách {tên, màu nhuộm hoặc sprite khác, giá}.
- Chỉ số và đá của mount chỉ có hiệu lực khi đang cưỡi.

### Chỉ số và combat
- `GameState.compute_base_stats` cộng HP/ATK/DEF/SPD/vàng của pet (luôn) và mount (khi cưỡi), cộng thêm DEF từ đá trên pet/mount.
- Crit, né, chính xác, cháy, làm chậm từ pet/mount và đá của chúng đi vào `PassiveEffectProcessor`, gộp chung giới hạn với đá trang bị. LAN host nhận qua profile như các chỉ số khác.

### Save v8
- Pet cũ thành bản ghi phẩm chất Common, giữ cấp. Cấp trên 10 bị hạ về 10 và hoàn vàng theo chi phí cũ (vàng + treat × 15).
- `pet_treat` trong túi, Lost & Found và claim đang chờ được đổi sang vàng (15 mỗi cái).
- Mount được thêm level 1, form 0 và 8 ô đá. Validator kiểm tra khoá pet, cấp, form và ô đá.
- Fixture mới `v7_pets_and_treats.json` cùng test. Ghi chú: `PROTOCOL_VERSION` LAN giữ 7 vì định dạng tin nhắn không đổi.

### Art (CC0 Ninja Adventure, đã đăng ký provenance)
22 sprite mới trong `assets/ninja_adventure/Actor`. Loài/mount chưa có sprite đúng dùng sprite tạm có giấy phép và ghi `art_status: NEEDS_ASSET`:
- Pet: Moss Turtle (kappa), 3 loại Bunny (hamster), Ash Crow (vẹt).
- Mount: Shell Tortoise (kappa), Gale Stag (lừa), Frost Wolf (linh cẩu nhuộm), Iron Rhino (beast nhuộm), Storm Eagle (vẹt).

## Kiểm chứng
- `tools/run_tests.sh`: **ALL PASSED** (runC2), thêm suite `CompanionTests`. Log không có `SCRIPT ERROR` hay `Assertion failed`.
- Render (`docs/reports/art/phase_c_*.png`): cưỡi Ember Lion (Enhanced Form) với Ember Drake huyền thoại, khung giậm, menu Pet, menu Mount, panel đá của mount.
- Lỗi phát hiện nhờ render và đã sửa: sprite mount ở `z_index -1` bị nền che; người chơi bị mount che; menu Mount tràn ngang.

## Chưa làm / rủi ro
- Icon trứng tạm ("heart") → `NEEDS_ASSET` (pha F).
- 10 sprite tạm cho các loài/mount không có trong pack.
- Pet/mount chưa hiện trên avatar của người chơi khác khi chơi LAN (trước đây cũng chưa có).
- Mọi con số (giá trứng, tỉ lệ, chi phí kim cương, chỉ số) đều là đề xuất, cần cân bằng.
- Mount kim cương (Frost Wolf, Ember Lion...) theo phiếu nên lấy từ boss/sự kiện; hiện tạm mở bằng kim cương, sẽ nối vào nguồn rơi ở pha E.
