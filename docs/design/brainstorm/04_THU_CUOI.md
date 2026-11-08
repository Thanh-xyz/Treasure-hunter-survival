# Phiếu 4 — Thú cưỡi (mount)

Ảnh danh mục: [img/animals.png](img/animals.png) · [img/monsters.png](img/monsters.png)

Thú cưỡi tăng tốc chạy, mỗi con có một kiểu (tốc độ / tấn công / phòng thủ) và một số skin.
Theo thiết kế, thú cưỡi sẽ có thêm: cấp độ (huấn luyện ở chuồng), yên và giáp, 2 ô đá ép, và một
chiêu đặc trưng.

## Hiện tại trong game

| id | Tên | Kiểu | Mở khóa | Art đề xuất |
| --- | --- | --- | --- | --- |
| `dust_pony` | Dust Pony | Tốc độ | Cấp 3, miễn phí | `A17` Horse hoặc `A13` Donkey |
| `tusk_boar` | Tusk Boar | Tấn công | 1000 vàng, cấp 6 | `A26` WildBoar |
| `shell_tortoise` | Shell Tortoise | Phòng thủ | 1000 vàng, cấp 6 | _chưa có rùa — chọn con khác hoặc tìm thêm_ |
| `gale_stag` | Gale Stag | Tốc độ | 3000 vàng, cấp 10 | _chưa có hươu — chọn con khác hoặc tìm thêm_ |


## 1. Tổng quan hệ thống

Thú cưỡi là hệ thống đồng hành giúp nhân vật di chuyển nhanh hơn, tăng chỉ số và hỗ trợ chiến đấu thông qua đặc tính riêng.

Mỗi Mount có:
- Một kiểu chuyên môn: Tốc độ / Tấn công / Phòng thủ / Tiện ích.
- Một chiêu đặc trưng.
- 8 ô đá ép (Gem Slots).
- Nhiều Skin.
- Khả năng tiến hóa hình thái khi ép đá quý thành công.

### Điểm khác biệt giữa Pet và Mount

| Đặc điểm | Pet | Mount |
|---|---|---|
| Đi theo nhân vật | Có | luôn cưỡi |
| Tăng chỉ số | Có | Có |
| Level | Có | Có |
| Kỹ năng riêng | Không | không |
| Gem Slots | 8 | 8 |
| Tiến hóa hình thái | Không | Có xác suất khi ép đá |
| Sử dụng | Một Pet hoạt động | Một Mount đang được cưỡi |

---

## 2. Danh sách Mount hiện tại

### 2.1. Mount: `dust_pony`

- **Tên hiển thị:** Dust Pony
- **Art chọn:** A17 Horse. Nếu sprite không phù hợp với kích thước hoặc góc nhìn của game thì sử dụng A13 Donkey.
- **Kiểu:** Tốc độ.
- **Chiêu đặc trưng:** Wind Dash — tăng tốc đột ngột trong một khoảng thời gian ngắn, giúp né đòn và vượt địa hình.
- **Mô tả ngắn:** Chú ngựa nhỏ nhanh nhẹn, bền bỉ và dễ huấn luyện. Là thú cưỡi đầu tiên dành cho những nhà thám hiểm mới.
- **Cách có được:** Mở khóa miễn phí khi nhân vật đạt Level 3.
- **Skin:**
  - Brown Pony — nâu.
  - White Pony — trắng.
  - Black Pony — đen.
  - Golden Pony — vàng.
  - Desert Pony — màu cát.

### 2.2. Mount: `tusk_boar`

- **Tên hiển thị:** Tusk Boar.
- **Art chọn:** A26 WildBoar.
- **Kiểu:** Tấn công.
- **Chiêu đặc trưng:** Tusk Charge — lao thẳng về phía trước, gây sát thương và đẩy lùi kẻ địch trên đường đi.
- **Mô tả ngắn:** Lợn rừng có cặp nanh lớn, thân hình khỏe và khả năng lao tới cực mạnh. Phù hợp với người chơi thích áp sát và tấn công.
- **Cách có được:** Mua với 1.000 vàng, yêu cầu nhân vật Level 6.
- **Skin:**
  - Wild Boar — nâu tự nhiên.
  - Dark Boar — đen.
  - Ash Boar — xám tro.
  - Crimson Boar — đỏ sẫm.
  - Golden Tusk — vàng.

### 2.3. Mount: `shell_tortoise`

- **Tên hiển thị:** Shell Tortoise.
- **Art chọn:** Cần tìm hoặc tạo sprite rùa riêng. Không sử dụng Frog A15 làm rùa vì sai hình thái.
- **Kiểu:** Phòng thủ.
- **Chiêu đặc trưng:** Shell Guard — rùa thu mình vào mai, giảm sát thương nhận vào trong thời gian ngắn.
- **Mô tả ngắn:** Rùa khổng lồ mang chiếc mai cứng chắc. Di chuyển chậm nhưng có khả năng bảo vệ người cưỡi trước những đòn tấn công nguy hiểm.
- **Cách có được:** Mua với 1.000 vàng, yêu cầu nhân vật Level 6.
- **Skin:**
  - Forest Shell — xanh lá.
  - Stone Shell — xám đá.
  - Ocean Shell — xanh biển.
  - Ancient Shell — mai cổ đại.
  - Golden Shell — vàng.

### 2.4. Mount: `gale_stag`

- **Tên hiển thị:** Gale Stag.
- **Art chọn:** Cần tìm hoặc tạo sprite hươu có sừng riêng. Không sử dụng sprite ngựa thông thường nếu không có chỉnh sửa hình thái phù hợp.
- **Kiểu:** Tốc độ.
- **Chiêu đặc trưng:** Gale Leap — nhảy vọt về phía trước, tạo luồng gió giúp tăng tốc và vượt qua một số chướng ngại.
- **Mô tả ngắn:** Hươu thần tốc với cặp sừng lớn, có khả năng di chuyển nhẹ nhàng và nhanh như gió.
- **Cách có được:** Mua với 3.000 vàng, yêu cầu nhân vật Level 10.
- **Skin:**
  - Forest Stag — nâu rừng.
  - Moon Stag — trắng bạc.
  - Shadow Stag — đen.
  - Crystal Stag — xanh pha lê.
  - Golden Stag — vàng.

---

## 3. Sáu Mount mới

### 3.1. Mount mới: `frost_wolf`

- **Tên hiển thị:** Frost Wolf.
- **Art chọn:** Sói tuyết. Tìm trong thư mục Animals/Monsters hoặc sử dụng asset mới có giấy phép phù hợp.
- **Vùng / cách có được:** Snow Region; rơi từ Frost Boss hoặc mua bằng vật phẩm sự kiện.
- **Kiểu + chiêu đặc trưng:** Tốc độ + Frost Trail — tăng tốc khi di chuyển và để lại vệt băng trong thời gian ngắn, làm chậm kẻ địch chạm phải.
- **Mô tả:** Sói tuyết nhanh nhẹn, có khả năng sinh tồn trong môi trường băng giá.

### 3.2. Mount mới: `ember_lion`

- **Tên hiển thị:** Ember Lion.
- **Art chọn:** Sư tử lửa, cần sprite riêng.
- **Vùng / cách có được:** Ash Region; phần thưởng từ boss lửa.
- **Kiểu + chiêu đặc trưng:** Tấn công + Flame Roar — gầm lên tạo sóng lửa gây sát thương trong phạm vi xung quanh.
- **Mô tả:** Sư tử mang sức mạnh nguyên tố lửa, có bờm rực cháy và khả năng tấn công mạnh mẽ.

### 3.3. Mount mới: `crystal_drake`

- **Tên hiển thị:** Crystal Drake.
- **Art chọn:** Rồng nhỏ có cánh, lớp vảy pha lê.
- **Vùng / cách có được:** Crystal Cave; phần thưởng hiếm từ boss.
- **Kiểu + chiêu đặc trưng:** Tấn công + Crystal Breath — phun luồng năng lượng pha lê về phía trước.
- **Mô tả:** Rồng pha lê hiếm gặp, sở hữu sức mạnh ma thuật và khả năng tấn công tầm xa.

### 3.4. Mount mới: `iron_rhino`

- **Tên hiển thị:** Iron Rhino.
- **Art chọn:** Tê giác bọc giáp, cần sprite phù hợp.
- **Vùng / cách có được:** Rocky Highlands; mua bằng vàng hoặc nhận từ nhiệm vụ đặc biệt.
- **Kiểu + chiêu đặc trưng:** Phòng thủ + Iron Fortress — tạo trạng thái tăng phòng thủ và giảm hiệu ứng đẩy lùi.
- **Mô tả:** Tê giác có lớp da dày và chiếc sừng cứng như kim loại. Là thú cưỡi chuyên phòng thủ.

### 3.5. Mount mới: `phantom_fox`

- **Tên hiển thị:** Phantom Fox.
- **Art chọn:** Cáo ma, có hiệu ứng linh hồn.
- **Vùng / cách có được:** Shadow Forest; rơi từ boss hoặc trứng sự kiện đặc biệt.
- **Kiểu + chiêu đặc trưng:** Tiện ích + Phantom Blink — lướt nhanh một khoảng cách ngắn, giúp né tránh nguy hiểm.
- **Mô tả:** Cáo linh hồn có khả năng di chuyển bí ẩn, phù hợp với người chơi thích né tránh và cơ động.

### 3.6. Mount mới: `storm_eagle`

- **Tên hiển thị:** Storm Eagle.
- **Art chọn:** Đại bàng lớn, có thể cưỡi, cần sprite riêng.
- **Vùng / cách có được:** Sky Ruins; phần thưởng từ thử thách hoặc boss trên không.
- **Kiểu + chiêu đặc trưng:** Tốc độ + Storm Dive — lao nhanh về phía trước, tạo luồng gió và đẩy lùi kẻ địch.
- **Mô tả:** Đại bàng khổng lồ có đôi cánh mạnh mẽ, sở hữu tốc độ di chuyển vượt trội.

---

## 4. Hệ thống Level và huấn luyện Mount

- Mỗi Mount có Level riêng.
- Level tăng giúp cải thiện chỉ số cơ bản của Mount.
- Không đồng nhất Level với tiến hóa hình thái.
- Tiến hóa hình thái là một hệ thống riêng, liên quan đến việc ép đá quý.
-nâng cấp mất kim cương

Đề xuất ban đầu:
- Level tối đa: 10.
- Các mốc Level có thể tăng chỉ số 
- Không tự động tiến hóa hình thái chỉ vì đạt Level nhất định.


---

## 6. Hệ thống Gem và tiến hóa hình thái

Đây là cơ chế đặc trưng quan trọng nhất của Mount.

### 6.1. Số ô đá

- Mỗi Mount có chính xác 8 ô Gem Slots.
- Sử dụng hệ thống Gem chung với Equipment và Pet.
- Người chơi có thể ép đá vào từng ô.
- Gem cung cấp chỉ số cho Mount hoặc nhân vật khi đang cưỡi.

### 6.2. Xác suất tiến hóa hình thái

Khi ép đá vào Mount, có xác suất kích hoạt tiến hóa hình thái.

Tiến hóa có thể làm thay đổi:
- Màu sắc cơ thể.
- Kích thước hoặc một số chi tiết ngoại hình.
- Sừng, cánh, mai, bờm hoặc lớp giáp.
- Hiệu ứng ánh sáng, lửa, băng, gió hoặc năng lượng.
- Hiệu ứng khi di chuyển.

Không phải mọi lần ép đá đều thành công tiến hóa.

### 6.3. Các giai đoạn hình thái đề xuất

| Giai đoạn | Tên | Mô tả |
|---|---|---|
| Form 0 | Base Form | Hình thái ban đầu |
| Form 1 | Awakened Form | Xuất hiện dấu hiệu nguyên tố hoặc thay đổi ngoại hình nhẹ |
| Form 2 | Enhanced Form | Thay đổi ngoại hình rõ rệt, có hiệu ứng đặc biệt |
| Form 3 | Ascended Form | Hình thái cao cấp nhất, có hiệu ứng riêng |

Mỗi Mount có thể có bộ hình thái tiến hóa khác nhau, phù hợp với loài và nguyên tố.

### 6.4. Quy tắc tiến hóa

- Tiến hóa được kích hoạt khi ép Gem thành công theo điều kiện cấu hình.
- Xác suất có thể phụ thuộc loại Gem, phẩm chất Gem, số ô đã ép hoặc tiến trình tiến hóa hiện tại.
- Không được để tiến hóa làm mất Gem đã ép nếu không có quy tắc được thông báo trước.
- Không tự động tiến hóa khi nâng Level.
- Không áp dụng cơ chế tiến hóa của Pet cho Mount.

### 6.5. Xác suất tham khảo ban đầu

Các tỷ lệ sau chỉ là đề xuất để thử nghiệm:

| Điều kiện | Xác suất tiến hóa |
|---|---:|
| Ép Gem lần đầu | 5% |
| Đã có 2 Gem | 8% |
| Đã có 4 Gem | 12% |
| Đã có 6 Gem | 18% |
| Đã có 8 Gem | 25% |

Đây là xác suất cơ sở tham khảo, chưa phải thông số cuối cùng. Cần cân bằng để tránh người chơi phải ép quá nhiều đá hoặc tiến hóa quá dễ.

Cần quyết định thêm:
- Mỗi Mount có thể tiến hóa tối đa mấy lần?
- Khi tiến hóa có giữ nguyên Skin đang dùng không?
- Tiến hóa có cộng chỉ số hay chỉ thay đổi ngoại hình?
- Có cần Gem đặc biệt để mở khóa Form cao hơn không?

Đề xuất: Tiến hóa nên vừa thay đổi ngoại hình vừa tăng một lượng chỉ số nhỏ, nhưng sức mạnh chính vẫn đến từ Level, Gem và trang bị. Như vậy, ngoại hình tiến hóa có giá trị mà không khiến người chơi bắt buộc phải tiến hóa mới có thể chơi tốt.

---

## 8. Quy tắc cưỡi và chiến đấu

### 8.1. Tấn công khi đang cưỡi

- Người chơi có thể sử dụng đòn đánh cơ bản khi đang cưỡi Mount.
- Khi người chơi thực hiện đòn đánh, Mount sẽ thực hiện animation tấn công đặc trưng chung:
  1. Mount vẫn di chuyển
  2. Hai chân trước đồng thời nhấc cao khỏi mặt đất.
  3. Phần thân trước nâng lên, tạo tư thế chồm về phía sau.
  4. Hai chân trước giẫm mạnh xuống mặt đất.
  5. Tạo hiệu ứng va chạm tại vị trí tiếp đất.
  6. Mount trở về tư thế cưỡi bình thường.
- Animation này áp dụng thống nhất cho **tất cả Mount**, bao gồm Dust Pony, Tusk Boar, Shell Tortoise, Gale Stag và toàn bộ Mount mới.
- Không tạo animation tấn công riêng theo từng loài.
- Có thể điều chỉnh tỷ lệ cơ thể, vị trí chân và biên độ chuyển động để phù hợp với hình dáng từng Mount, nhưng hành động chính phải giống nhau.
- Đòn đánh được tính theo hệ thống chiến đấu của nhân vật; animation Mount là chuyển động thể hiện hành động tấn công.
- Không cho phép Mount tự động tấn công độc lập khi không có người chơi điều khiển.
- Chiêu đặc trưng của Mount vẫn có thể được kích hoạt bằng nút riêng và sử dụng animation riêng của từng Mount.

### 8.3. Hiển thị người chơi trên Mount

- Khi cưỡi, nhân vật hiển thị tư thế ngồi hoặc tư thế cưỡi trên lưng thú.
- Sprite Mount và Sprite nhân vật được ghép thành một trạng thái hiển thị thống nhất.
- Khi tấn công, animation nhân vật và animation Mount phải đồng bộ.
- Khi Mount nhấc hai chân trước, nhân vật phải có chuyển động tương ứng để tạo cảm giác đang điều khiển thú cưỡi.
- Khi hai chân trước giẫm xuống, cần đồng bộ hiệu ứng va chạm và chuyển động của nhân vật.
- Khi xuống Mount, nhân vật trở lại animation bình thường.
- Mỗi Mount có thể có tư thế ngồi và vị trí nhân vật riêng để phù hợp với kích thước, hình dáng của từng loài.
- Tuy nhiên, animation tấn công nhấc hai chân trước rồi giẫm xuống phải được áp dụng thống nhất cho toàn bộ Mount.

### 8.4. Quy chuẩn animation chung

Tạo một animation dùng chung với tên đề xuất `mounted_attack_stomp`.

Các giai đoạn:
- `prepare`: Mount chuẩn bị chồm lên.
- `rear_up`: Nhấc đồng thời hai chân trước.
- `stomp`: Giẫm mạnh hai chân trước xuống.
- `impact`: Hiệu ứng va chạm tại thời điểm tiếp đất.
- `recover`: Trở về tư thế cưỡi bình thường.

Yêu cầu kỹ thuật:
- Tất cả Mount phải có animation này.
- Không thay đổi bản chất chuyển động giữa các loài.
- Có thể điều chỉnh animation theo tỷ lệ sprite và cấu trúc cơ thể.
- Không yêu cầu Mount có chân trước giống hệt nhau về mặt hình học; cần xử lý phù hợp với từng sprite.
- Animation không được làm nhân vật bị lệch khỏi vị trí cưỡi.
- Không để animation tấn công bị lặp vô hạn.
- Phải có cơ chế tránh kích hoạt chồng nhiều animation tấn công cùng lúc.
- Nếu người chơi tiếp tục tấn công, animation cần được xử lý theo hệ thống cooldown hoặc hàng đợi hành động.