# Phiếu 5 — Quái thường

Ảnh danh mục: [img/monsters.png](img/monsters.png) · [img/animals.png](img/animals.png)

Bản đồ gồm 3 vùng đồng tâm: **Thường** ở giữa (cấp 1–15), **Ash** bao quanh (cấp 15–30), **Snow**
ngoài cùng (cấp 30–45). Mỗi vùng có bộ quái riêng, không con quái thường nào xuất hiện ở hai vùng.

Kiểu AI có sẵn: `melee` (áp sát cắn/đánh), `flyer` (bay lượn), `ranged` (bắn xa), `charger`
(lao húc, có báo trước), `stationary_melee` (đứng yên canh gác).

## Hiện tại trong game

| id | Tên | Vùng | AI | Art | Ghi chú |
| --- | --- | --- | --- | --- | --- |
| `slime` | Meadow Slime | Thường | flyer | `M53` Slime | Quest q02 |
| `bat` | Dusk Bat | Thường (đêm) | flyer | `M08` BlueBat | Quest q05 |
| `shroom` | Bramble Snake | Thường | melee | `M57` Snake | Tutorial t05 |
| `boar` | Bristle Boar | Thường | charger | `A26` WildBoar | Quest q08 |
| `mossback` | Mosscap | Thường | stationary_melee | `M40` Mushroom | Tutorial t02 |
| `magma_slime` | Magma Flame | Ash | melee | `M19` Flam | |
| `skeleton_grunt` | Bone Grunt | Ash | melee | `M51` Skull | |
| `skeleton_archer` | Bone Archer | Ash | ranged | `M52` SkullBlue | Quest q13 |
| `frost_slime` | Frost Wisp | Snow | melee | `M20` Flam2 | |

Vùng Ash chưa có bản đồ riêng. Hiện quái Ash và Snow đang dùng chung bản đồ Frostvale.

## Sửa quái hiện có

Chỉ điền những con muốn đổi (tên, hình, cách đánh, mô tả).

| id | ✍️ Tên mới | ✍️ Art | ✍️ Cách đánh / đặc điểm | ✍️ Rơi đồ gì |
| --- | --- | --- | --- | --- |
| `slime` | | | | |
| `bat` | | | | |
| `shroom` | | | | |
| `boar` | | | | |
| `mossback` | | | | |
| `magma_slime` | | | | |
| `skeleton_grunt` | | | | |
| `skeleton_archer` | | | | |
| `frost_slime` | | | | |

## Quái mới theo vùng

Thiết kế dự kiến mỗi vùng có 7–10 quái. Điền thêm vào bảng (mỗi dòng một con).

### Vùng Thường (đồng cỏ, rừng, suối)

| ✍️ Tên | ✍️ Art | ✍️ Cách đánh | ✍️ Ban ngày / đêm | ✍️ Mô tả ngắn |
| --- | --- | --- | --- | --- |
| | | | | |
| | | | | |
| | | | | |

### Vùng Ash (đồng tro, phế tích, khe lửa)

| ✍️ Tên | ✍️ Art | ✍️ Cách đánh | ✍️ Ban ngày / đêm | ✍️ Mô tả ngắn |
| --- | --- | --- | --- | --- |
| | | | | |
| | | | | |
| | | | | |
| | | | | |

### Vùng Snow (đồng tuyết, rừng băng, hang băng)

| ✍️ Tên | ✍️ Art | ✍️ Cách đánh | ✍️ Ban ngày / đêm | ✍️ Mô tả ngắn |
| --- | --- | --- | --- | --- |
| | | | | |
| | | | | |
| | | | | |
| | | | | |

## Quái tinh anh (elite) và đặc biệt

- ✍️ Quái tinh anh trông khác thế nào (to hơn, đổi màu, có hào quang)?
- ✍️ Có quái **săn người mang chìa khóa** (Kindled Key) ở vùng Ash không? Tên, hình, cách săn:
- ✍️ Có quái chỉ xuất hiện vào **đêm Blood Ember** không?
- ✍️ Quái phe **Hollowfolk** (giữ trại ở vùng Ash): các loại lính, tên, hình:
