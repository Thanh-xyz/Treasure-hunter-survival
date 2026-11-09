# Pha E — Boss: World Boss theo lịch, giai đoạn, cảnh báo, thẻ triệu hồi, chia thưởng

Plan: `docs/plans/BRAINSTORM_CONSOLIDATED_PLAN.md` §4 pha E; phiếu 06; quyết định C3/C4 (chỉ dùng Thẻ + mảnh thẻ). Owner xác nhận 2026-11-09.
Branch `feature/phase-e-bosses` (tách từ `feature/phase-d-combat`).

## Đã làm

### Dữ liệu (`data/bosses/bosses.json`, `BossCatalog`)
- 10 boss, mỗi con có 2–3 giai đoạn (tên giai đoạn theo phiếu 06), tốc độ/sát thương/nhịp đòn riêng mỗi giai đoạn, bảng thưởng riêng:
  - World: Mire King, Infernal Dragon, Frost Leviathan.
  - Area: Cinder Colossus.
  - Dungeon: Crypt Warden.
  - Thẻ: Verdant Treant, Ash Devourer, Frost Abyss King, Ancient Dragon, Ember Overlord.
- 7 kiểu đòn, **đều có cảnh báo trước khi gây sát thương**:
  - slam (nhiều vòng), leap (vòng lớn tại chỗ hạ cánh);
  - wave (các vòng nở dần ra từ boss), nova (vòng đỏ trên boss rồi bắn đạn tỏa tròn);
  - line (dải đỏ cho hơi thở hoặc lao thẳng), rain (nhiều vòng rải quanh người chơi), summon.
- Boss gây hiệu ứng trạng thái qua `on_hit` (cháy, chậm, đóng băng).

### World Boss theo lịch (`WorldBossSchedule`, `WorldBossClock`)
- Lịch theo giờ máy/host: 09:00 Mire King, 12:00 Infernal Dragon, 15:00 Frost Leviathan, 18:00 Mire King, 21:00 Infernal Dragon, 00:00 Frost Leviathan.
- Mỗi lượt 15 phút, xuất hiện ở bàn thờ của vùng tương ứng (Greenwood / Cinderwaste / Frostvale). Hết giờ thì boss rời đi.
- Mỗi lượt có id trận `world:<boss>:<ngày>:<giờ>`. Đã hạ thì không xuất hiện lại trong cùng lượt, kể cả khi rời vùng rồi quay lại.
- Thông báo ở mọi nơi: trước 5 phút, trước 1 phút, và khi boss xuất hiện.
- Tương tác bàn thờ cho biết boss kế tiếp. Không còn triệu hồi tự do hay hẹn giờ 3 phút như trước.
- HUD hiện thời gian còn lại hoặc thời điểm boss đến vùng này. Thanh máu boss hiện `Tên [giai đoạn/tổng Tên giai đoạn] HP`.

### Area Boss
- Cinder Colossus đứng cố định ở Frostvale, hồi sinh sau 10 phút. Trước đây nó là World Boss của vùng này.

### Thẻ triệu hồi (phiếu 06 §7)
- 5 thẻ: Meadow Guardian (Rare), Ash Destroyer (Epic), Snow Titan (Epic), Dragon Lord (Legendary), Ember Overlord (Legendary). Mỗi thẻ chỉ dùng được ở vùng quy định.
- 3 loại mảnh; ghép 10 / 15 / 15 mảnh thành thẻ, không có tỉ lệ thất bại.
- Nguồn mảnh: đào ô di tích, Elite, mini-boss, thưởng boss. Thẻ Legendary chỉ rơi từ thưởng đóng góp của boss.
- Dùng thẻ ở tab Bản đồ. Thẻ chỉ bị trừ **sau khi boss đã xuất hiện**. Thẻ được giữ lại khi: sai vùng, đang ở làng/hầm ngục, hoặc đã có một boss thẻ đang sống.

### Chia thưởng (phiếu 06 §8, `BossRewards`)
- Boss ghi lại sát thương của từng người, tính cả đòn kết liễu.
- Thưởng tham gia cho người gây ≥ 2% máu boss; đứng gần mà không đánh thì không có gì.
- Người kết liễu được thêm một lượt thưởng (không lấy hết).
- Thưởng đóng góp là một lượt rút với xác suất = phần sát thương × 1.5.
- **Mỗi id trận chỉ trả một lần cho mỗi profile.** `GameState.boss_claims` lưu trong save (trường tuỳ chọn, tối đa 200, có kiểm tra hợp lệ).
- LAN: host gửi phần của từng client qua RPC `_receive_boss_reward`; client tự kiểm tra id trận, nên gửi lại sau khi kết nối lại cũng không nhận trùng. `PROTOCOL_VERSION` 8.
- Đồ không vừa túi được thả xuống đất, không mất.

### Art (CC0 Ninja Adventure, đã đăng ký provenance)
22 file mới:
- Giant Bamboo → Verdant Treant; Squid Red → Ash Devourer; Giant Blue Samurai → Frost Abyss King; Tengu Red → Ember Overlord.
- Các mảnh Dragon Green/Blue.
- Rồng được **ghép từ các mảnh** (đầu, hai cánh, chuỗi thân, đuôi), cánh vỗ và thân lắc bằng code (`DragonVisual`).
- Infernal Dragon là rồng xanh lá đổi sang đỏ bằng shader `hue_shift.gdshader`, chỉ đổi những điểm ảnh bão hoà nên mặt và sừng giữ màu.

## Kiểm chứng
- `tools/run_tests.sh`: **ALL PASSED** (runE2), thêm suite `BossTests`, gồm:
  - dữ liệu hợp lệ, ngưỡng giai đoạn, lịch (09:05, hết giờ, trước 2 phút, qua nửa đêm);
  - chia thưởng (dưới 2% không có thưởng, người kết liễu được thêm), nhận trùng bị chặn, claims còn sau save/load, giới hạn 200;
  - đổi giai đoạn và ghi đủ đóng góp;
  - 5 đòn đều có cảnh báo ≥ 0.5 giây và không gây sát thương trong lúc cảnh báo;
  - World Boss đúng vùng/lượt, không hồi lại sau khi hạ;
  - thẻ: ghép, sai vùng, giữ thẻ khi bị từ chối;
  - thông báo 5 phút / 1 phút / lúc xuất hiện, kiểm tra save.
- Render `docs/reports/art/phase_e_*.png`: Infernal Dragon với cảnh báo dạng đường, Frost Leviathan với mưa vòng đỏ, 5 boss thẻ, tab Bản đồ có lịch và thẻ.
- Cảnh báo harness đã biết: ObjectDB / RID leaked at exit.

## Chưa làm / rủi ro
- Area Boss của Meadow/Ash, dungeon mới (Gloamdeep Mines, Frozen Sepulchre) và Ember Vault → pha G.
- Boss Arena riêng: hiện boss thẻ xuất hiện ngay cạnh người chơi trên bản đồ field.
- Client LAN chưa tự dùng thẻ được (chỉ host); chưa tính thưởng cho người hồi máu (game chưa có kỹ năng hồi máu cho người khác).
- Nhạc riêng cho boss, âm thanh khi đổi giai đoạn → pha audio.
- World Boss theo giờ thật nghĩa là phải chờ đúng giờ mới đánh được; bỏ hẹn giờ 3 phút cũ có thể khó cho việc chơi thử. Đề xuất sau: thêm tuỳ chọn cho dev.
- Icon thẻ và mảnh đang là icon tạm (`NEEDS_ASSET`).
