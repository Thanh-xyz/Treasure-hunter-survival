# Phiếu 3 — Thú cưng

Ảnh danh mục: [img/animals.png](img/animals.png) (động vật) · [img/monsters.png](img/monsters.png) (sinh vật nhỏ cũng làm thú cưng được)

Thú cưng đi theo người chơi, đánh hoặc hỗ trợ, lên cấp bằng thức ăn và tiến hóa ở cấp 5 và 10.
Theo thiết kế, thú cưng sẽ có thêm: độ hiếm, sao, 2 ô đá ép, kỹ năng chủ động và bị động, và có
được bằng cách ấp trứng.

## Hiện tại trong game

| id | Tên | Vai trò | Mô tả hiện tại | Mở khóa | Art đề xuất |
| --- | --- | --- | --- | --- | --- |
| `ember_fox` | Ember Fox | Tấn công | Vồ kẻ địch gần | Có sẵn | `A11` DogOrange (trông như cáo) |
| `moss_turtle` | Moss Turtle | Phòng thủ | Hồi máu chậm, tăng giáp | 600 vàng | `A15` Frog (chưa có rùa) |
| `dusk_owl` | Dusk Owl | Hỗ trợ | Bắn lông vũ xa | 900 vàng | `M44` Owl |
| `lucky_cat` | Lucky Cat | Tiện ích | Hút đồ, thêm vàng | 1500 vàng | `A04` CatOrange |

---

## 2. Quy tắc Pet đã chốt — BẮT BUỘC TUÂN THỦ

### 2.1. Vai trò Pet
- Pet là thú cưng đồng hành và hệ thống tăng chỉ số cho nhân vật.
- Pet KHÔNG tấn công quái vật.
- Pet KHÔNG có kỹ năng chủ động.
- Pet KHÔNG có kỹ năng bị động riêng.
- Pet KHÔNG tham gia tính toán chiến đấu độc lập.
- Pet có thể đi theo nhân vật và có animation Idle/Follow.

### 2.2. Phẩm chất Pet

Mỗi loài Pet phải có đủ 4 phẩm chất:

| Phẩm chất | Màu |
|---|---|
| Common | Trắng |
| Uncommon | Xanh |
| Epic | Tím |
| Legendary | Vàng |

Ví dụ:
- Rabbit có đủ Rabbit trắng, xanh, tím, vàng.
- Ember Fox có đủ Ember Fox trắng, xanh, tím, vàng.
- Frost Fox có đủ Frost Fox trắng, xanh, tím, vàng.

Lưu ý:
- Phẩm chất và loài là hai thuộc tính độc lập.
- Màu đen, nâu, trắng của thỏ là biến thể ngoại hình, không phải phẩm chất.
- Không được nhầm phẩm chất với tiến hóa.
- Không có hệ thống sao.

### 2.3. Hệ thống Level
- Pet có Level.
- Người chơi sử dụng kim cương để nâng Level Pet.
- Không dùng thức ăn để tăng EXP.
- Không có hệ thống EXP Pet.
- Không có tiến hóa ở Level 5, Level 10 hoặc bất kỳ Level nào.
- Level tăng chỉ số của Pet, từ đó tăng chỉ số nhân vật.
- Không thay đổi loài khi tăng Level.
- Không tự động thay đổi phẩm chất khi tăng Level.

Level tối đa đề xuất ban đầu: 10.

Phải thiết kế bảng cấu hình:
- Level.
- Chi phí kim cương.
- Hệ số chỉ số.
- Điều kiện nâng cấp.

Các con số kinh tế chỉ là giá trị đề xuất, phải được đánh dấu là cần cân bằng, không được trình bày như dữ liệu chính xác của game tham chiếu.

### 2.4. Pet trùng
- Người chơi chỉ sở hữu một bản ghi Pet cho mỗi tổ hợp loài và phẩm chất, trừ khi tài liệu hiện tại có yêu cầu khác cần được xác minh.
- Khi nhận Pet trùng, Pet trùng được quy đổi thành kim cương.
- Số kim cương nhận được phụ thuộc phẩm chất.
- Phải có bảng quy đổi đề xuất.
- Không ghép Pet trùng để tiến hóa.
- Không ghép Pet trùng để tăng sao.
- Không dùng Pet trùng làm nguyên liệu tăng Level.

Đề xuất ban đầu:

| Phẩm chất | Kim cương nhận được |
|---|---:|
| Trắng | 2 |
| Xanh | 5 |
| Tím | 15 |
| Vàng | 40 |

Đánh dấu các giá trị trên là cấu hình đề xuất cần cân bằng.

### 2.5. Số Pet hoạt động
- Mỗi người chơi chỉ được trang bị 1 Pet tại một thời điểm.
- Người chơi có thể sở hữu nhiều Pet trong bộ sưu tập.
- Có thể thay Pet thông qua giao diện quản lý.
- Không có nhiều Pet cùng hoạt động để cộng chỉ số đồng thời.

### 2.6. Gem Slots
Tất cả Pet có chính xác 8 ô Gem Slots.

Quy tắc này phải thống nhất với:
- Equipment: 8 ô.
- Pet: 8 ô.
- Mount: 8 ô.

Không được tạo ngoại lệ 2 ô hoặc số ô khác.

Đá quý có thể cung cấp các chỉ số như:
- HP.
- Damage.
- Defense.
- Critical Chance.
- Critical Damage.
- Attack Speed.
- Movement Speed.
- Dodge.
- Accuracy.
- Lifesteal.
- Elemental Resistance.

Phải tái sử dụng hệ thống Gem chung nếu dự án đã có, không tạo một hệ thống Gem riêng cho Pet.

## 3. Danh sách Pet

Cập nhật danh sách ban đầu gồm 12 loài:

| ID | Tên | Định hướng chỉ số | Art tham chiếu |
|---|---|---|---|
| ember_fox | Ember Fox | Damage, Fire | A11 DogOrange |
| moss_turtle | Moss Turtle | HP, Defense | Cần tạo art rùa |
| dusk_owl | Dusk Owl | Critical, Accuracy | M44 Owl |
| lucky_cat | Lucky Cat | Gold, Loot | A04 CatOrange |
| shadow_bunny | Shadow Bunny | Dodge, Speed | Thỏ đen |
| brown_bunny | Brown Bunny | HP, Resource Bonus | Thỏ nâu |
| snow_bunny | Snow Bunny | Defense, Resistance | Thỏ trắng |
| ash_salamander | Ash Salamander | Fire, Damage | Kỳ giông lửa |
| ash_crow | Ash Crow | Critical, Accuracy | Quạ |
| frost_fox | Frost Fox | Freeze, Damage | Cáo tuyết |
| glacier_owl | Glacier Owl | Defense, Dodge | Cú tuyết |
| ember_drake | Ember Drake | HP, Damage, Fire | Rồng con |

Yêu cầu:
- Tất cả 12 loài đều có đủ 4 phẩm chất.
- Mỗi loài có nhóm chỉ số đặc trưng.
- Không tạo kỹ năng chiến đấu cho Pet.
- Không gán hiệu ứng tấn công độc lập.
- Không tự tạo mã sprite A/M nếu chưa tìm thấy trong asset.
- Các mã art chưa xác nhận phải được đánh dấu rõ là TODO.

Tổng số biến thể thiết kế ban đầu: 12 loài × 4 phẩm chất = 48 biến thể.

## 4. Hệ thống trứng và cách nhận Pet

Thiết kế các loại trứng theo khu vực:

| Trứng | Khu vực | Pet dự kiến |
|---|---|---|
| Forest Egg | Forest | Turtle, Bunny, Owl |
| Ash Egg | Ash | Ember Fox, Salamander, Crow |
| Snow Egg | Snow | Snow Bunny, Frost Fox, Glacier Owl |
| Dragon Egg | Endgame | Ember Drake |
| Special Egg | Event | Pet sự kiện |

Các phương thức nhận Pet:
- Ấp trứng.
- Nhiệm vụ.
- Cửa hàng NPC.
- Boss.
- Sự kiện.

Yêu cầu:
- Có bảng xác suất loài và phẩm chất.
- Tỷ lệ phải cấu hình được.
- Giao diện phải hiển thị tỷ lệ nhận.
- Không tự đặt tỷ lệ chính thức nếu chưa có dữ liệu cân bằng.
- Phải xử lý an toàn khi người chơi mất kết nối trong quá trình ấp trứng.

## 5. Giao diện cần mô tả

Thiết kế tài liệu UI/UX cho các màn hình:

### Pet Collection
- Danh sách Pet đã sở hữu.
- Phân loại theo phẩm chất.
- Hiển thị hình ảnh, tên và Level.
- Hiển thị Pet chưa sở hữu.
- Cho phép chọn Pet.

### Pet Detail
- Hình ảnh Pet.
- Tên và phẩm chất.
- Level hiện tại.
- Chỉ số cơ bản.
- Chỉ số sau khi cộng vào nhân vật.
- 8 Gem Slots.
- Nút trang bị/tháo trang bị.
- Nút nâng Level.

### Pet Upgrade
- Level hiện tại và Level tiếp theo.
- Chi phí kim cương.
- Chỉ số trước và sau nâng cấp.
- Xác nhận trước khi tiêu kim cương.
- Thông báo khi không đủ kim cương hoặc đã đạt Level tối đa.

### Pet Duplicate
- Thông báo Pet trùng.
- Phẩm chất Pet.
- Số kim cương nhận được.
- Xác nhận quy đổi.
- Chống quy đổi hai lần khi mất kết nối hoặc gửi request lặp.