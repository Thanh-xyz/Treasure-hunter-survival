# Phiếu 1 — Hero (nhân vật người chơi)

Ảnh danh mục: [img/characters.png](img/characters.png) · Hướng dẫn: [README.md](README.md)

Mỗi hero là một lối chơi riêng. Người chơi sưu tầm hero và nâng sao bằng mảnh hero (hero shard).
Trang bị dùng chung giữa các hero.

## Hiện tại trong game

| id | Tên | Lối đánh | Chỉ số gốc (HP/ATK/DEF/tốc độ) | 3 kỹ năng | Mở khóa | Art đề xuất |
| --- | --- | --- | --- | --- | --- | --- |
| `warden` | Warden | Cận chiến, chém vòng | 120 / 10 / 2 / 120 | Cleave, Charge, War Cry | Có sẵn | `C25` KnightGold |
| `ranger` | Ranger | Bắn tia, nhanh | 95 / 12 / 1 / 135 | Volley, Dash, Rain | 1200 vàng, cấp 5 | `C47` NinjaGreen |
| `mystic` | Mystic | Phép nổ vùng | 90 / 14 / 1 / 118 | Meteor, Frost, Mend | 2500 vàng, cấp 8 | `C49` NinjaMageBlack |

---


2. PLAYER CHARACTER — NHÂN VẬT DUY NHẤT

2.1. Kiến trúc nhân vật

Chỉ xây dựng một Player Character.

Nhân vật có:

Sprite và animation di chuyển.

Idle.

Walk.

Run.

Attack.

Take Damage.

Death.

Các animation tương tác cần thiết.

Không tạo nhiều nhân vật tương ứng với các class khác nhau.

Nếu có nhiều sprite nhân vật, chúng chỉ được sử dụng làm skin hoặc ngoại hình thay thế, không đại diện cho class.

2.2. Hệ thống chỉ số cơ bản

Nhân vật có các chỉ số:

Chỉ số

Ý nghĩa

HP

Máu tối đa

ATK

Sát thương

MOVE SPEED

Tốc độ di chuyển

DEF

Phòng thủ

CRIT RATE

Tỷ lệ chí mạng

CRIT DAMAGE

Sát thương chí mạng

LIFESTEAL

Tỷ lệ hút máu

DODGE

Tỷ lệ né tránh

chính xác, hồi máu, phản sát thương

dame lửa, băng, độc

HP, ATK và MOVE SPEED là ba chỉ số cốt lõi của hệ thống trang bị thông thường.

Các chỉ số DEF, CRIT RATE, CRIT DAMAGE, LIFESTEAL và DODGE là những chỉ số bổ trợ có thể xuất hiện trên Pet, Mount, hiệu ứng đặc biệt hoặc hệ thống nâng cấp.

Không tự ý đưa toàn bộ chỉ số phụ lên mọi món trang bị.