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
# PHIẾU 5 — QUÁI THƯỜNG (MONSTER SYSTEM)

## 1. Tổng quan hệ thống

Bản đồ thế giới được chia thành 3 vùng đồng tâm:

| Vùng | Cấp nhân vật | Độ khó | Đặc điểm |
|---|---:|---|---|
| Thường (Meadow) | 1–15 | Dễ | Đồng cỏ, rừng, suối, sinh vật tự nhiên |
| Ash | 15–30 | Trung bình – khó | Đồng tro, phế tích, khe núi lửa, sinh vật bị biến đổi |
| Snow | 30–45 | Khó | Đồng tuyết, rừng băng, hang băng, sinh vật băng giá |

Quy tắc:
- Mỗi vùng có chính xác 4 loại quái thường chính.
- Quái thường của mỗi vùng không xuất hiện ở vùng khác.
- Không sử dụng chung một loại quái thường cho hai vùng.
- Các vùng có thể có quái tinh anh, mini-boss và boss riêng.
- Mini-boss có xác suất xuất hiện ngẫu nhiên trên bản đồ ở cả 3 vùng.
- Người chơi có thể đào/phá các ô đất để tìm vật phẩm triệu hồi boss.
- Độ khó tăng dần theo vùng, không chỉ tăng HP mà còn tăng sát thương, tốc độ, khả năng gây hiệu ứng và độ phức tạp AI.

## 2. Quy chuẩn phân loại quái

Mỗi vùng có 4 vai trò quái thường:

| Vai trò | Đặc điểm | Cách đối phó |
|---|---|---|
| Speed | Tốc độ cao, HP thấp, áp sát nhanh | Né tránh, ưu tiên tiêu diệt |
| Tank | HP và phòng thủ cao, sát thương thấp hoặc vừa | Tấn công liên tục, sử dụng kỹ năng xuyên giáp |
| Damage | Sát thương cao, có thể gây nguy hiểm nếu bị áp sát | Né đòn, ưu tiên tiêu diệt |
| Ranged/Special | Tấn công tầm xa hoặc gây hiệu ứng đặc biệt | Áp sát, ngắt đòn hoặc tránh vùng tấn công |

### Kiểu AI

- `melee`: Áp sát và tấn công cận chiến.
- `flyer`: Bay lượn, di chuyển trên không và tấn công.
- `ranged`: Giữ khoảng cách, bắn hoặc phóng vật thể.
- `charger`: Có animation/cảnh báo trước khi lao húc.
- `stationary_melee`: Đứng canh gác tại một vị trí, chỉ tấn công khi người chơi vào phạm vi.
- `ambusher`: Ẩn nấp, bất ngờ lao ra tấn công.
- `support`: Hỗ trợ quái khác bằng hồi máu hoặc tăng sức mạnh.

Các kiểu AI mới chỉ được sử dụng nếu cần thiết; không nên tạo quá nhiều AI phức tạp ngay từ phiên bản đầu.

---

## 3. Sửa quái hiện có

### Bảng cập nhật

| ID | Tên hiển thị | Art | Cách đánh / đặc điểm | Rơi đồ |
|---|---|---|---|---|
| `slime` | Meadow Slime | M53 Slime | Di chuyển chậm, nhảy về phía người chơi và gây sát thương thấp. Khi chết có thể tạo một vùng dịch nhỏ tồn tại ngắn. | Gold, Slime Gel, nguyên liệu thường |
| `bat` | Dusk Bat | M08 BlueBat | Bay nhanh, thường tấn công theo từng đợt rồi bay lùi. HP thấp, khó đánh trúng nếu không căn thời gian. Xuất hiện chủ yếu ban đêm. | Gold, Bat Wing, nguyên liệu thường |
| `shroom` | Bramble Snake | M57 Snake | Trườn nhanh, áp sát và cắn liên tục. Có xác suất nhỏ gây Poison trong thời gian ngắn. | Gold, Venom Fang, nguyên liệu rừng |
| `boar` | Bristle Boar | A26 WildBoar | Có cảnh báo trước khi lao húc. Sát thương cao, có thể đẩy lùi người chơi. | Gold, Boar Tusk, Hide |
| `mossback` | Mosscap Guardian | M40 Mushroom | Chuyển thành quái canh gác hiếm hoặc quái tinh anh của Meadow. Đứng yên bảo vệ khu rừng, đánh cận chiến mạnh và có HP cao. | Gold, Moss Core, nguyên liệu hiếm |

### Quái vùng Ash

| ID | Tên hiển thị | Art | Cách đánh / đặc điểm | Rơi đồ |
|---|---|---|---|---|
| `magma_slime` | Magma Flame | M19 Flam | Di chuyển chậm, áp sát và gây sát thương lửa. Khi bị tiêu diệt có thể để lại vùng dung nham nhỏ. | Ash Core, Flame Gel, Gold |
| `skeleton_grunt` | Bone Grunt | M51 Skull | Chiến đấu cận chiến, HP trung bình, có thể dùng kiếm hoặc vũ khí xương. | Bone Fragment, Gold, nguyên liệu Ash |
| `skeleton_archer` | Bone Archer | M52 SkullBlue | Giữ khoảng cách, bắn tên xương. Có thể bắn liên tiếp hai phát sau khi báo hiệu. | Bone Arrow, Ancient Bone, Gold |
| `ash_hound` | Ash Hound | Cần tìm hoặc tạo art chó sói tro | Quái tốc độ cao, sử dụng AI `charger` hoặc `melee`, có khả năng truy đuổi người chơi trong phạm vi rộng. | Ash Fang, Charred Hide, Gold |

### Quái vùng Snow

| ID | Tên hiển thị | Art | Cách đánh / đặc điểm | Rơi đồ |
|---|---|---|---|---|
| `frost_slime` | Frost Wisp | M20 Flam2 | Di chuyển và áp sát, gây sát thương băng. Có xác suất làm chậm người chơi. | Frost Core, Ice Gel, Gold |
| `snow_wolf` | Whitefang Wolf | Cần tìm art sói tuyết | Di chuyển rất nhanh, truy đuổi và cắn liên tiếp. Có thể gọi thêm một con sói nếu ở gần bầy. | Wolf Fang, Frost Hide, Gold |
| `snow_bear` | Glacier Bear | Cần tìm art gấu tuyết | HP rất cao, di chuyển chậm, đòn đánh mạnh và có thể gây choáng ngắn. | Bear Claw, Thick Fur, Gold |
| `ice_shaman` | Frost Shaman | Cần tìm art pháp sư băng | Đánh xa bằng đạn băng, tạo vùng băng làm chậm người chơi. Có thể tăng sức mạnh cho quái gần đó. | Frozen Essence, Ice Crystal, Gold |

Ghi chú:
- Mã art mới là TODO, không được tự gán mã A/M khi chưa kiểm tra ảnh danh mục.
- `mossback` vẫn được giữ ID để tránh phá vỡ các nhiệm vụ/tutorial hiện tại.
- Cần kiểm tra lại các quest đang tham chiếu `shroom`, `mossback` và các ID khác trước khi đổi tên hiển thị.
- Tên hiển thị có thể thay đổi mà không cần thay đổi ID trong dữ liệu game.

---

## 4. Quái mới theo vùng

### 4.1. Vùng Thường — Meadow (Level 1–15)

<Phân loại>
- 4 quái thường: Meadow Slime, Dusk Bat, Bramble Snake, Bristle Boar.
- Mosscap Guardian là quái canh gác hiếm, không tính vào 4 loại quái thường.
- Đây là vùng hướng dẫn người chơi làm quen với các kiểu tấn công.

| Quái | Vai trò | AI | Đặc điểm |
|---|---|---|---|
| Meadow Slime | Tank nhẹ | melee | HP tương đối, sát thương thấp, di chuyển chậm |
| Dusk Bat | Speed | flyer | HP thấp, tốc độ cao, xuất hiện ban đêm |
| Bramble Snake | Damage | melee | Cắn nhanh, có xác suất gây độc |
| Bristle Boar | Charger | charger | Lao húc mạnh, có cảnh báo trước |

#### Mô tả chi tiết

**Meadow Slime**
- Sinh vật chất nhầy sinh sống trên đồng cỏ.
- Di chuyển bằng cách nhảy từng đoạn.
- Có thể nhảy về phía người chơi để tấn công.
- Khi chết có tỷ lệ rơi Slime Gel dùng làm nguyên liệu chế tạo.

**Dusk Bat**
- Dơi sống trong rừng, hang nhỏ và khu vực tối.
- Ban ngày xuất hiện ít, ban đêm xuất hiện thường xuyên hơn.
- Bay vòng quanh người chơi rồi lao xuống tấn công.
- Có thể né đòn nếu người chơi đứng yên quá lâu.

**Bramble Snake**
- Rắn sống trong bụi cây.
- Có thể ẩn nấp trước khi người chơi đến gần.
- Tấn công bằng cách lao tới cắn.
- Có tỷ lệ nhỏ gây Poison.

**Bristle Boar**
- Lợn rừng có bộ lông cứng.
- Có thể phát hiện người chơi từ khoảng cách tương đối xa.
- Trước khi lao húc, nó cúi đầu và phát ra âm thanh cảnh báo.
- Khi lao trúng vật cản, nó bị khựng lại trong thời gian ngắn.

### 4.2. Vùng Ash (Level 15–30)

<Phân loại>
- 4 quái thường: Magma Flame, Bone Grunt, Bone Archer, Ash Hound.
- Ngoài ra có Hollowfolk ở các trại riêng.
- Độ khó cao hơn Meadow về sát thương, HP và hiệu ứng nguyên tố.

| Quái | Vai trò | AI | Đặc điểm |
|---|---|---|---|
| Magma Flame | Tank / Elemental | melee | HP cao, gây Burn |
| Bone Grunt | Melee | melee | Cận chiến, sát thương trung bình |
| Bone Archer | Ranged | ranged | Bắn tên xương, gây áp lực từ xa |
| Ash Hound | Speed | charger | Truy đuổi nhanh, sát thương cao |

#### Mô tả chi tiết

**Magma Flame**
- Sinh vật dung nham hình thành từ tro nóng.
- Di chuyển chậm nhưng có khả năng gây sát thương lửa.
- Khi HP thấp, tốc độ tấn công có thể tăng.
- Khi chết có xác suất để lại vùng dung nham tồn tại trong thời gian ngắn.

**Bone Grunt**
- Bộ xương chiến binh lang thang trong phế tích.
- Sử dụng vũ khí cận chiến.
- Có thể chặn một phần sát thương phía trước bằng khiên nếu phiên bản có trang bị khiên.
- HP và sát thương cao hơn Bone Grunt ở các cấp đầu Meadow.

**Bone Archer**
- Bộ xương cung thủ.
- Tấn công từ xa và cố gắng giữ khoảng cách.
- Có thể bắn tên thường hoặc tên lửa tro.
- Khi người chơi áp sát, nó lùi lại để tìm vị trí bắn mới.

**Ash Hound**
- Chó săn bị biến đổi bởi tro và nhiệt độ cao.
- Di chuyển nhanh, có thể truy đuổi người chơi.
- Trước khi lao tới có animation gầm và hạ thấp thân.
- Có thể gây Burn nhẹ khi tấn công trúng.

### 4.3. Vùng Snow (Level 30–45)

<Phân loại>
- 4 quái thường: Frost Wisp, Whitefang Wolf, Glacier Bear, Frost Shaman.
- Quái Snow có khả năng gây hiệu ứng Freeze/Slow.
- Đây là vùng có độ khó cao nhất trong ba vùng.

| Quái | Vai trò | AI | Đặc điểm |
|---|---|---|---|
| Frost Wisp | Elemental | melee | Gây sát thương băng, làm chậm |
| Whitefang Wolf | Speed | melee | Tốc độ cao, truy đuổi |
| Glacier Bear | Tank / Damage | melee | HP và sát thương rất cao |
| Frost Shaman | Ranged / Support | ranged / support | Bắn băng, hỗ trợ quái gần đó |

#### Mô tả chi tiết

**Frost Wisp**
- Sinh vật băng nhỏ, có thể bay lơ lửng gần mặt đất.
- Tấn công bằng những luồng năng lượng lạnh.
- Có tỷ lệ làm chậm người chơi.
- HP thấp nhưng khó chịu khi xuất hiện cùng quái khác.

**Whitefang Wolf**
- Sói tuyết sống theo bầy.
- Có tốc độ cao, liên tục áp sát.
- Có thể thực hiện đòn nhảy vồ.
- Nếu có nhiều cá thể gần nhau, chúng có thể thay phiên truy đuổi người chơi.

**Glacier Bear**
- Gấu tuyết khổng lồ.
- Có lượng HP và phòng thủ cao nhất trong nhóm quái thường Snow.
- Đòn vung tay gây sát thương lớn.
- Có thể tạo sóng chấn động nhỏ khi đập xuống mặt đất.
- Trước đòn mạnh cần có animation báo hiệu rõ ràng.

**Frost Shaman**
- Sinh vật phép thuật sống trong rừng băng và hang tuyết.
- Bắn đạn băng theo đường thẳng hoặc tạo vùng băng trên mặt đất.
- Có thể tăng một lượng phòng thủ nhỏ cho quái gần đó.
- Nên ưu tiên tiêu diệt trước khi xử lý các quái cận chiến.

---

## 5. Cân bằng độ khó giữa các vùng

Không nên chỉ tăng HP và sát thương theo cấp. Mỗi vùng cần có nhịp độ chiến đấu khác nhau.

| Thuộc tính | Meadow | Ash | Snow |
|---|---|---|---|
| HP quái | Thấp | Trung bình | Cao |
| Sát thương | Thấp | Trung bình – cao | Cao |
| Tốc độ | Thấp – trung bình | Trung bình – cao | Cao |
| Phòng thủ | Thấp | Trung bình | Cao |
| Hiệu ứng nguyên tố | Rất ít | Burn | Freeze / Slow |
| AI | Đơn giản | Có phối hợp | Phối hợp phức tạp |
| Quái tầm xa | Ít | Có | Có |
| Mini-boss | Có | Có | Có |

### Nguyên tắc cân bằng

- Meadow phải đủ dễ để người chơi mới học né đòn, đánh và thu thập nguyên liệu.
- Ash cần bắt đầu có các combo quái cận chiến và tầm xa.
- Snow cần buộc người chơi quan tâm đến trang bị, Gem và chỉ số kháng nguyên tố.
- Không để một quái thường có lượng HP lớn đến mức giống mini-boss.
- Các đòn gây sát thương lớn cần có animation hoặc vùng cảnh báo.
- Không để quái tầm xa xuất hiện quá nhiều cùng lúc khiến người chơi không thể tiếp cận.

---

## 6. Quái tinh anh (Elite)

### 6.1. Ngoại hình

Quái tinh anh là biến thể mạnh hơn của quái thường.

Đặc điểm nhận diện:
- Kích thước lớn hơn khoảng 15–30%.
- Có viền sáng hoặc hào quang quanh cơ thể.
- Màu sắc đậm hoặc khác biệt so với quái thường.
- Có biểu tượng Elite phía trên đầu.
- Có thanh HP riêng hoặc thanh HP dài hơn.
- Có thể có thêm một đòn đánh đặc biệt.

Không cần tạo một sprite hoàn toàn mới cho tất cả Elite. Có thể dùng:
- Sprite gốc.
- Thay đổi màu bằng shader.
- Hiệu ứng viền.
- Hiệu ứng hạt.
- Thay đổi kích thước có kiểm soát.

### 6.2. Elite theo vùng

| Vùng | Tên | Biến thể từ | Đặc điểm |
|---|---|---|---|
| Meadow | Ancient Mosscap | Mosscap Guardian | HP cao, đập đất tạo sóng nhỏ |
| Meadow | Alpha Bristle Boar | Bristle Boar | Lao húc hai lần liên tiếp |
| Ash | Cinder Bone Knight | Bone Grunt | Có giáp, sát thương cận chiến cao |
| Ash | Infernal Hound | Ash Hound | Lao nhanh, để lại vệt lửa |
| Snow | Frostfang Alpha | Whitefang Wolf | Gọi thêm sói thường |
| Snow | Ancient Glacier Bear | Glacier Bear | Đập đất tạo vùng sát thương rộng |

### 6.3. Cơ chế xuất hiện

- Elite có xác suất xuất hiện thay thế một quái thường.
- Không xuất hiện liên tục trong cùng một khu vực.
- Khi xuất hiện có hiệu ứng hoặc âm thanh cảnh báo.
- Elite rơi nhiều Gold và nguyên liệu hơn quái thường.
- Có tỷ lệ nhỏ rơi vật phẩm hiếm, Gem hoặc vật phẩm triệu hồi boss.

Tỷ lệ đề xuất:
- 3–5% xác suất một lượt sinh quái thường được thay thế bằng Elite.
- Không tính tỷ lệ này trên từng frame hoặc từng giây.
- Phải sử dụng hệ thống spawn có kiểm soát để tránh quá nhiều Elite xuất hiện đồng thời.

---

## 7. Mini-boss xuất hiện ngẫu nhiên trên bản đồ

Đây là hệ thống riêng, hoạt động ở cả 3 vùng.

### 7.1. Quy tắc chung

- Mini-boss có thể xuất hiện ngẫu nhiên trên bản đồ.
- Mỗi vùng có tối thiểu 2 mini-boss.
- Mini-boss không xuất hiện ở vị trí quá gần điểm hồi sinh hoặc khu vực an toàn.
- Có thời gian hồi sinh sau khi bị tiêu diệt.
- Mỗi mini-boss có khu vực và điều kiện xuất hiện riêng.
- Mini-boss mạnh hơn Elite rõ rệt.
- Khi xuất hiện, có thông báo nhỏ trên màn hình và hiệu ứng âm thanh.
- Không bắt buộc người chơi phải có vật phẩm triệu hồi để gặp mini-boss ngẫu nhiên.

### 7.2. Mini-boss Meadow

**A. Rootfang — Ancient Forest Beast**

- ID: `mini_boss_rootfang`
- Art: Cần tạo hoặc tìm art quái thú rừng lớn.
- Vùng: Meadow Forest.
- Cấp đề xuất: 10–15.
- Kiểu AI: `charger` + `melee`.
- Đặc điểm:
  - Thân hình lớn, có gai và rễ cây.
  - Lao húc về phía người chơi.
  - Đập chân xuống đất tạo vùng rễ cây.
  - Có thể làm chậm người chơi trong vùng rễ.
- Phần thưởng:
  - Gold.
  - Ancient Root.
  - Rare Ingredient.
  - Tỷ lệ nhỏ rơi vật phẩm triệu hồi boss Meadow.

**B. Slime Monarch — King of Slimes**

- ID: `mini_boss_slime_monarch`
- Art: M53 Slime được biến thể kích thước và màu sắc.
- Vùng: Meadow Plains.
- Cấp đề xuất: 8–15.
- Kiểu AI: `melee`.
- Đặc điểm:
  - Kích thước lớn.
  - Nhảy mạnh tạo sóng chấn động.
  - Khi HP xuống thấp có thể tách thành các Slime nhỏ.
  - Có thể hấp thụ Slime gần đó để hồi một lượng HP.
- Phần thưởng:
  - Slime Core.
  - Gold.
  - Gem cấp thấp.
  - Vật phẩm triệu hồi boss Meadow.

### 7.3. Mini-boss Ash

**A. Cinder Warlord**

- ID: `mini_boss_cinder_warlord`
- Art: Bộ xương chiến binh lớn, giáp tro.
- Vùng: Ash Ruins.
- Cấp đề xuất: 23–30.
- Kiểu AI: `melee`.
- Đặc điểm:
  - Có vũ khí lớn.
  - Đánh mạnh theo vùng hình quạt.
  - Có đòn đập đất tạo vùng lửa.
  - Có thể triệu hồi Bone Grunt hỗ trợ.
- Phần thưởng:
  - Cinder Core.
  - Ancient Bone.
  - Gold.
  - Vật phẩm triệu hồi boss Ash.

**B. Ash Tyrant**

- ID: `mini_boss_ash_tyrant`
- Art: Quái thú tro lớn, cần art mới.
- Vùng: Ash Ravine.
- Cấp đề xuất: 25–30.
- Kiểu AI: `charger`.
- Đặc điểm:
  - Lao húc rất nhanh.
  - Để lại vệt lửa.
  - Có đòn giậm chân tạo vòng lửa.
  - Khi HP thấp tăng tốc độ tấn công.
- Phần thưởng:
  - Ash Heart.
  - Flame Ingredient.
  - Gold.
  - Vật phẩm triệu hồi boss Ash.

### 7.4. Mini-boss Snow

**A. Frosthorn**

- ID: `mini_boss_frosthorn`
- Art: Quái thú tuyết có sừng lớn.
- Vùng: Snow Field.
- Cấp đề xuất: 35–40.
- Kiểu AI: `charger`.
- Đặc điểm:
  - Lao thẳng về phía người chơi.
  - Có thể húc tạo vùng băng nhọn.
  - Khi trúng đòn tạo hiệu ứng làm chậm.
- Phần thưởng:
  - Frost Horn.
  - Frozen Core.
  - Gold.
  - Vật phẩm triệu hồi boss Snow.

**B. Glacial Colossus**

- ID: `mini_boss_glacial_colossus`
- Art: Người tuyết khổng lồ hoặc quái đá băng.
- Vùng: Ice Cave.
- Cấp đề xuất: 40–45.
- Kiểu AI: `stationary_melee` + `ranged`.
- Đặc điểm:
  - HP rất cao.
  - Đập đất tạo vùng băng.
  - Ném khối băng về phía người chơi.
  - Có thể tạo lá chắn băng trong thời gian ngắn.
- Phần thưởng:
  - Glacial Heart.
  - Ice Crystal.
  - Rare/Legendary Ingredient.
  - Vật phẩm triệu hồi boss Snow.

### 7.5. Xác suất xuất hiện mini-boss

Đề xuất:
- Mỗi vùng có một bộ mini-boss riêng.
- Mỗi 10 phút có một lượt kiểm tra khả năng xuất hiện mini-boss.
- Xác suất mỗi lượt kiểm tra: 10%.
- Nếu xuất hiện, chọn ngẫu nhiên một mini-boss phù hợp với vùng.
- Mỗi vùng chỉ có tối đa một mini-boss ngẫu nhiên đang hoạt động tại cùng thời điểm.
- Sau khi bị tiêu diệt, mini-boss cần thời gian hồi sinh.
- Người chơi ở khu vực đó nhận được thông báo khi mini-boss xuất hiện.

Các giá trị trên là cấu hình thử nghiệm, cần cân bằng sau khi chơi thực tế.

---

## 8. Hệ thống đào đất và vật phẩm triệu hồi Boss

### 8.1. Đào đất

Người chơi có thể phá các ô đất trên bản đồ để thu thập:
- Gold.
- Nguyên liệu chế tạo.
- Gem.
- Vật phẩm hồi phục.
- Vật phẩm hiếm.
- Vật phẩm triệu hồi boss.

Mỗi vùng có bảng phần thưởng riêng.

### 8.2. Vật phẩm triệu hồi

Mỗi vùng có một vật phẩm triệu hồi boss riêng:

| ID | Tên | Vùng | Công dụng |
|---|---|---|---|
| `summon_meadow_seal` | Meadow Summon Seal | Meadow | Triệu hồi boss Meadow |
| `summon_ash_seal` | Ash Summon Seal | Ash | Triệu hồi boss Ash |
| `summon_snow_seal` | Snow Summon Seal | Snow | Triệu hồi boss Snow |

### 8.3. Tỷ lệ rơi vật phẩm triệu hồi

Tỷ lệ đề xuất trên mỗi ô đất được phá thành công:

| Vật phẩm | Vùng | Tỷ lệ |
|---|---|---:|
| Meadow Summon Seal | Meadow | 0,10% |
| Ash Summon Seal | Ash | 0,15% |
| Snow Summon Seal | Snow | 0,20% |

Lưu ý:
- Đây là tỷ lệ đề xuất, chưa phải thông số chính thức.
- Tỷ lệ không được tính lại liên tục trên cùng một ô đất.
- Một ô đất chỉ có thể tạo phần thưởng một lần.
- Tỷ lệ có thể tăng nhẹ nhờ chỉ số tăng Ingredient Drop Rate hoặc hiệu ứng vật phẩm.
- Không nên để tỷ lệ quá cao vì sẽ khiến boss bị triệu hồi liên tục.
- Có thể bổ sung cơ chế bảo hiểm (pity) sau một số lượng ô đất nhất định chưa nhận được vật phẩm triệu hồi.

### 8.4. Sử dụng vật phẩm triệu hồi

Quy trình:
1. Người chơi nhận vật phẩm triệu hồi khi đào đất.
2. Mở Inventory.
3. Chọn vật phẩm triệu hồi phù hợp với vùng.
4. Sử dụng tại khu vực hợp lệ.
5. Hiện vòng tròn hoặc dấu hiệu triệu hồi trên mặt đất.
6. Boss xuất hiện sau animation triệu hồi.
7. Người chơi chiến đấu và nhận phần thưởng khi tiêu diệt boss.

Quy tắc:
- Không thể triệu hồi boss tại khu vực an toàn.
- Không thể triệu hồi boss sai vùng.
- Vật phẩm chỉ bị tiêu thụ khi hệ thống xác nhận triệu hồi thành công.
- Nếu người chơi mất kết nối trong lúc triệu hồi, server hoặc hệ thống lưu game phải đảm bảo không tiêu thụ vật phẩm hai lần.
- Có thể cho phép nhóm tối đa 4 người tham gia đánh boss.
- Phần thưởng cần được xử lý riêng cho từng người chơi hợp lệ để tránh tranh chấp.

### 8.5. Boss được triệu hồi

Mỗi vùng có một boss chính:

**Meadow Boss — Verdant Treant**
- ID: `boss_verdant_treant`
- Cấp đề xuất: 15.
- Ngoại hình: Cây cổ thụ khổng lồ có tay và rễ cây.
- Đòn đánh:
  - Đập rễ xuống đất.
  - Tạo gai cây từ mặt đất.
  - Gọi Slime hoặc sinh vật rừng hỗ trợ.
- Phần thưởng:
  - Verdant Core.
  - Rare Gem.
  - Ancient Root.
  - Gold.
  - Xác suất nhỏ rơi nguyên liệu chế tạo trang bị.

**Ash Boss — Infernal Golem**
- ID: `boss_infernal_golem`
- Cấp đề xuất: 30.
- Ngoại hình: Golem đá đen có lõi dung nham.
- Đòn đánh:
  - Đập đất tạo sóng lửa.
  - Ném đá dung nham.
  - Tạo vùng dung nham.
  - Khi HP thấp, lõi phát sáng và tăng sát thương.
- Phần thưởng:
  - Infernal Core.
  - Epic/Legendary Ingredient.
  - Gem.
  - Gold.
  - Nguyên liệu chế tạo Yên và Giáp Mount.

**Snow Boss — Frost Titan**
- ID: `boss_frost_titan`
- Cấp đề xuất: 45.
- Ngoại hình: Titan băng khổng lồ.
- Đòn đánh:
  - Đập băng tạo sóng chấn động.
  - Triệu hồi cột băng.
  - Tạo bão tuyết làm chậm.
  - Tạo lá chắn băng khi HP thấp.
- Phần thưởng:
  - Frost Titan Core.
  - Legendary Ingredient.
  - Gem hiếm.
  - Gold.
  - Nguyên liệu nâng cấp trang bị và Mount.

---

## 9. Quái săn người mang Kindled Key

Có một loại quái đặc biệt tại vùng Ash chuyên săn người đang giữ Kindled Key.

### Ash Key Hunter

- ID: `ash_key_hunter`
- Tên hiển thị: Ash Key Hunter.
- Art: Một chiến binh Hollowfolk hoặc quái thú tro có dấu hiệu nhận biết riêng.
- Vùng: Ash.
- AI: `ambusher` + `charger`.
- Vai trò: Quái đặc biệt săn người giữ chìa khóa.

Đặc điểm:
- Bình thường có xác suất nhỏ xuất hiện tại các khu vực Ash.
- Khi người chơi đang giữ Kindled Key, hệ thống có thể tăng xác suất xuất hiện.
- Khi phát hiện người giữ chìa khóa, nó chuyển sang trạng thái truy đuổi.
- Có thể gọi thêm một số quái Ash hỗ trợ.
- Không được biết chính xác vị trí người chơi trên toàn bản đồ nếu chưa có cơ chế phát hiện hợp lệ.

Cách săn:
1. Tuần tra tại các điểm spawn ở Ash.
2. Phát hiện người giữ Kindled Key trong phạm vi.
3. Có animation hoặc âm thanh báo hiệu.
4. Truy đuổi và cố gắng tấn công.
5. Nếu tiêu diệt người chơi, chìa khóa có thể rơi ra theo quy tắc của hệ thống Key.

Phần thưởng:
- Gold.
- Ash Hunter Token.
- Rare Ingredient.
- Có tỷ lệ nhỏ rơi vật phẩm đặc biệt.

---

## 10. Sự kiện Blood Ember

Blood Ember là sự kiện ban đêm đặc biệt.

Quy tắc đề xuất:
- Chỉ diễn ra vào một số đêm được hệ thống lựa chọn.
- Khi sự kiện bắt đầu, bầu trời và ánh sáng chuyển sang màu đỏ sẫm.
- Quái thường có thể mạnh hơn một chút.
- Một số quái đặc biệt chỉ xuất hiện trong thời gian sự kiện.
- Tăng cơ hội gặp Elite và mini-boss nhưng vẫn phải có giới hạn spawn.

### Blood Ember Stalker

- ID: `blood_ember_stalker`
- Vùng: Ash.
- AI: `ambusher`.
- Ngoại hình: Quái săn mồi có mắt đỏ và lớp tro cháy.
- Đặc điểm:
  - Ẩn nấp trong bóng tối.
  - Đột ngột xuất hiện phía sau hoặc bên cạnh người chơi.
  - Có đòn lao nhanh.
  - Gây Burn hoặc hiệu ứng suy yếu nhẹ.
- Phần thưởng:
  - Blood Ember Shard.
  - Rare Ash Ingredient.
  - Gold.
  - Vật phẩm sự kiện.

### Blood Ember Wraith

- ID: `blood_ember_wraith`
- Vùng: Ash.
- AI: `flyer` + `ranged`.
- Ngoại hình: Linh hồn đỏ bay lơ lửng.
- Đặc điểm:
  - Bay quanh người chơi.
  - Bắn đạn năng lượng.
  - Có thể dịch chuyển ngắn.
- Phần thưởng:
  - Ember Essence.
  - Blood Ember Shard.
  - Rare Gem.

---

## 11. Phe Hollowfolk tại vùng Ash

Hollowfolk là phe sinh vật có tổ chức, giữ các trại và phế tích tại Ash.

Không nên coi toàn bộ Hollowfolk là quái thường. Đây là nhóm kẻ địch có tổ chức, có thể có nhiều vai trò chiến đấu.

### Các loại Hollowfolk

| ID | Tên | AI | Vai trò | Đặc điểm |
|---|---|---|---|---|
| `hollowfolk_grunt` | Hollowfolk Grunt | melee | Cận chiến | Lính cơ bản, sử dụng vũ khí thô sơ |
| `hollowfolk_archer` | Hollowfolk Archer | ranged | Tầm xa | Bắn tên hoặc lao nhọn |
| `hollowfolk_guard` | Hollowfolk Guard | stationary_melee | Canh gác | HP cao, bảo vệ cổng và trại |
| `hollowfolk_shaman` | Hollowfolk Shaman | support | Hỗ trợ | Tăng sức mạnh hoặc hồi máu cho đồng đội |

### Cách tổ chức

- Hollowfolk xuất hiện chủ yếu tại các trại ở Ash.
- Không xuất hiện ngẫu nhiên khắp bản đồ như quái thường.
- Các trại có thể có lính canh, lính tuần tra và thủ lĩnh.
- Khi người chơi tấn công một lính, các lính gần đó có thể cùng tham chiến.
- Một số trại có rương chứa nguyên liệu hiếm.
- Có thể liên kết với nhiệm vụ và hệ thống Kindled Key.

### Art

- Tìm asset phù hợp trong thư mục Monsters.
- Nếu không có, tạo bộ sprite mới có giấy phép rõ ràng.
- Phân biệt rõ Grunt, Archer, Guard và Shaman bằng hình dáng, vũ khí và màu sắc.

---

## 12. Hệ thống phần thưởng và Drop Table

### 12.1. Nhóm vật phẩm

| Nhóm | Mục đích |
|---|---|
| Gold | Tiền tệ cơ bản |
| Common Ingredient | Chế tạo và nâng cấp cơ bản |
| Rare Ingredient | Chế tạo trang bị và vật phẩm cao cấp |
| Gem | Ép vào Equipment, Pet và Mount |
| Health Potion | Hồi HP |
| Boss Summon Seal | Triệu hồi boss |
| Elite Token | Trao đổi phần thưởng |
| Special Material | Nâng cấp đặc biệt, sự kiện |

### 12.2. Phân bổ phần thưởng theo vùng

| Vùng | Quái thường | Elite | Mini-boss | Boss triệu hồi |
|---|---|---|---|---|
| Meadow | Gold, Common Ingredient | Rare Ingredient | Rare Gem, Boss Seal | Gem, Rare Ingredient |
| Ash | Gold, Ash Ingredient | Rare Gem, Ash Token | Epic Ingredient | Epic Gem, Mount Material |
| Snow | Gold, Frost Ingredient | Epic Ingredient | Epic/Legendary Material | Legendary Ingredient, Gem hiếm |

### 12.3. Quy tắc Drop

- Mỗi quái có Drop Table riêng.
- Không phải quái nào cũng rơi tất cả vật phẩm.
- Quái thường chủ yếu rơi Gold và nguyên liệu theo vùng.
- Elite có tỷ lệ rơi vật phẩm hiếm cao hơn.
- Mini-boss có phần thưởng tốt hơn Elite.
- Boss triệu hồi có phần thưởng cao nhất.
- Tỷ lệ rơi phải được cấu hình bằng dữ liệu, không hardcode trong AI.
- Cần chống trường hợp người chơi đánh một quái nhiều lần để nhận phần thưởng trùng không hợp lệ.

---

## 13. Quy tắc spawn và quản lý bản đồ

### Quái thường
- Spawn theo các khu vực được định nghĩa trước.
- Có giới hạn số lượng quái cùng tồn tại.
- Có thời gian respawn sau khi bị tiêu diệt.
- Không spawn bên trong khu vực an toàn hoặc vị trí không thể tiếp cận.

### Quái ban ngày và ban đêm
- Dusk Bat xuất hiện nhiều hơn vào ban đêm.
- Blood Ember Stalker và Blood Ember Wraith chỉ xuất hiện trong sự kiện Blood Ember.
- Những quái còn lại có thể xuất hiện cả ngày lẫn đêm.

### Elite
- Có xác suất thay thế quái thường.
- Giới hạn số lượng Elite trong từng khu vực.

### Mini-boss
- Spawn ngẫu nhiên theo bộ đếm thời gian.
- Không xuất hiện quá gần người chơi mới.
- Có giới hạn một mini-boss ngẫu nhiên trên mỗi vùng.

### Boss triệu hồi
- Chỉ xuất hiện khi người chơi sử dụng vật phẩm hợp lệ.
- Có thể tổ chức chiến đấu nhóm.
- Không ảnh hưởng đến spawn của quái thường.

---

## 14. Data Structure đề xuất

MonsterDefinition:
- monster_id
- display_name
- region_id
- level_min
- level_max
- monster_role
- ai_type
- base_stats
- movement_speed
- attack_range
- attack_cooldown
- abilities
- spawn_conditions
- drop_table_id
- visual_config

MonsterSpawnConfig:
- spawn_zone_id
- monster_id
- spawn_weight
- max_alive
- respawn_time
- time_conditions
- level_range

EliteConfig:
- monster_id
- stat_multiplier
- visual_effect
- special_abilities
- drop_table_id

MiniBossDefinition:
- boss_id
- region_id
- level
- base_stats
- abilities
- spawn_probability
- respawn_time
- drop_table_id

BossSummonConfig:
- summon_item_id
- region_id
- boss_id
- valid_locations
- consume_condition
- reward_config

DropTable:
- drop_table_id
- item_id
- min_quantity
- max_quantity
- drop_probability

---

## 15. Những thông số cần cân bằng

Các giá trị dưới đây cần được kiểm tra bằng gameplay thực tế:

- HP và Damage từng quái.
- Tốc độ di chuyển và tốc độ tấn công.
- Thời gian cảnh báo trước đòn mạnh.
- Tỷ lệ Elite xuất hiện.
- Tỷ lệ mini-boss xuất hiện.
- Thời gian hồi sinh mini-boss.
- Tỷ lệ rơi vật phẩm triệu hồi.
- Số lượng quái tối đa trong mỗi vùng.
- Phần thưởng khi tiêu diệt boss.
- Số người tối đa tham gia đánh boss.

Không xem các tỷ lệ đề xuất trong tài liệu là dữ liệu chính thức của Treasure Hunter.

## 16. Quy tắc bắt buộc khi triển khai

1. Mỗi vùng có 4 loại quái thường chính.
2. Quái thường không xuất hiện ở nhiều vùng.
3. Độ khó tăng dần từ Meadow đến Ash rồi Snow.
4. Mỗi vùng có mini-boss xuất hiện ngẫu nhiên.
5. Mỗi vùng có vật phẩm triệu hồi boss nhận được khi đào/phá ô đất.
6. Boss triệu hồi phải khác mini-boss ngẫu nhiên.
7. Elite là biến thể mạnh hơn của quái thường.
8. Hollowfolk là phe kẻ địch có tổ chức tại Ash.
9. Blood Ember là sự kiện riêng, có quái đặc biệt.
10. Các đòn đánh mạnh phải có animation báo trước.
11. Drop Table và Spawn Config phải tách khỏi code AI.
12. Không tự bịa mã art.
13. Không sử dụng asset không rõ giấy phép.
14. Không thay đổi ID hiện tại nếu chưa kiểm tra nhiệm vụ và dữ liệu đang tham chiếu.
15. Mọi xác suất và phần thưởng đều phải cấu hình được.