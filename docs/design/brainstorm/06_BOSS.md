# Phiếu 6 — Boss

Ảnh danh mục: [img/bosses.png](img/bosses.png) (20 boss có hoạt ảnh)

Các loại boss:
- **Boss thế giới:** xuất hiện ở bàn thờ theo giờ.
- **Boss khu vực:** canh một nơi trên bản đồ.
- **Boss hầm ngục:** đứng cuối dungeon.

Mỗi boss có 2–3 giai đoạn, đòn đánh luôn báo trước (vòng đỏ) để người chơi né được. Phần thưởng
gồm thưởng đánh trúng cuối và thưởng tham gia.

## Hiện tại trong game

| id | Tên | Loại | Vùng | Art | Đòn hiện có |
| --- | --- | --- | --- | --- | --- |
| `slime_king` | Mire King | Thế giới (bàn thờ) | Thường | `B14` GiantSlime | Đập đất, nhảy, gọi slime con |
| `crypt_warden` | Crypt Warden | Hầm ngục Crypt Depths | Thường | `B16` GiantSpirit | Chém, nhảy, nổ vòng |
| `bone_colossus` | Cinder Colossus | Khu vực | Snow (Frostvale) | `B01` DemonCyclop | Đập, nhảy, nổ vòng, gọi quân |
# PHIẾU 6 — BOSS SYSTEM

## 1. Tổng quan hệ thống

Game có 3 vùng chính và một khu vực cuối game Ember Vault.

Mỗi vùng có:
- 1 Boss thế giới xuất hiện theo khung giờ tại bàn thờ.
- 1–2 Boss khu vực canh giữ địa điểm đặc biệt.
- 1 Boss hầm ngục đứng cuối dungeon.

Ngoài ra:
- Có boss đặc biệt được triệu hồi bằng thẻ boss.
- Có boss khủng cuối game tại Ember Vault.
- Boss có 2–3 giai đoạn chiến đấu.
- Mọi đòn tấn công nguy hiểm đều phải có cảnh báo trước bằng vòng đỏ hoặc vùng báo hiệu trực quan.
- Phần thưởng gồm thưởng tham gia và thưởng cho người kết liễu boss.
- Có thể mở rộng hệ thống xếp hạng sát thương khi chơi LAN hoặc multiplayer.

## 2. Phân loại Boss

### 2.1. World Boss — Boss thế giới

- Xuất hiện tại bàn thờ (Boss Altar) theo lịch.
- Mỗi vùng có một World Boss riêng.
- Người chơi có thể tham gia trong thời gian boss còn tồn tại.
- Boss có thanh HP lớn hiển thị trên màn hình.
- Khi boss xuất hiện, toàn bộ người chơi trong vùng nhận thông báo.
- Có giới hạn thời gian cho mỗi trận.
- Phần thưởng được chia theo đóng góp và quy tắc kết liễu.

### 2.2. Area Boss — Boss khu vực

- Canh giữ một địa điểm cụ thể trên bản đồ.
- Có thể xuất hiện cố định hoặc hồi sinh sau khi bị tiêu diệt.
- Không cần thẻ triệu hồi.
- Người chơi phải đi tới khu vực của boss để chiến đấu.
- Có thể có quái nhỏ hoặc cơ chế môi trường bảo vệ boss.
- Phần thưởng chủ yếu là nguyên liệu đặc trưng của vùng.

### 2.3. Dungeon Boss — Boss hầm ngục

- Là boss cuối của mỗi Dungeon.
- Chỉ xuất hiện khi người chơi hoàn thành các phòng hoặc điều kiện trong Dungeon.
- Có không gian chiến đấu riêng.
- Không bị quái ngoài bản đồ làm gián đoạn.
- Phần thưởng gồm nguyên liệu hiếm, Gem và trang bị.
- Có thể có cơ chế đặc biệt yêu cầu người chơi né đòn, phá vật thể hoặc xử lý mục tiêu phụ.

### 2.4. Summoned Boss — Boss triệu hồi bằng thẻ

- Người chơi sử dụng Boss Summon Card để triệu hồi.
- Mỗi thẻ gắn với một boss hoặc một nhóm boss cụ thể.
- Boss có độ khó và phần thưởng cao hơn quái thường, Elite và phần lớn mini-boss.
- Có thể triệu hồi tại khu vực được chỉ định hoặc Boss Arena.
- Một số thẻ cực hiếm có thể triệu hồi boss đặc biệt.
- Thẻ bị tiêu thụ khi triệu hồi thành công.
- Nếu triệu hồi thất bại do lỗi hệ thống, không được mất thẻ.

---

## 3. Danh sách Boss hiện tại

### 3.1. Boss: `slime_king`

- **Tên hiển thị:** Mire King — Vua Bùn Lầy.
- **Art chọn:** B14 GiantSlime.
- **Loại và vùng:** World Boss — Meadow (Thường).
- **Truyền thuyết:** Mire King là sinh vật slime cổ đại sống sâu dưới vùng đầm lầy Meadow. Sau nhiều năm hấp thụ năng lượng từ đất và sinh vật xung quanh, nó trở thành thủ lĩnh của toàn bộ bầy slime.

#### Giai đoạn 1 — Swamp Awakening (100%–70% HP)

- Đập cơ thể xuống đất tạo vòng chấn động.
- Nhảy về phía người chơi, gây sát thương tại điểm tiếp đất.
- Gọi 2–3 Slime nhỏ hỗ trợ.
- Có đòn quét cơ thể theo hình quạt.

#### Giai đoạn 2 — Mire Rage (70%–30% HP)

- Cơ thể chuyển màu đậm hơn.
- Tốc độ nhảy và tần suất tấn công tăng.
- Tạo nhiều vùng bùn độc trên mặt đất.
- Nhảy liên tiếp hai lần, mỗi lần tạo vòng sát thương.
- Gọi thêm slime con nhưng phải giới hạn số lượng.

#### Giai đoạn 3 — King of the Mire (30%–0% HP)

- Toàn thân phát sáng.
- Đòn đập đất tạo 3 vòng sóng chấn động liên tiếp.
- Tạo vùng bùn lớn ở trung tâm đấu trường.
- Có một đòn nhảy cực mạnh với vòng cảnh báo đỏ lớn.
- Sau đòn cuối có khoảng nghỉ để người chơi phản công.

#### Cách đánh bại / mẹo

- Quan sát vòng đỏ trước khi né.
- Không đứng tập trung cùng một vị trí khi boss gọi slime con.
- Tận dụng thời gian boss hồi phục sau đòn nhảy.
- Ưu tiên tiêu diệt slime con nếu số lượng quá nhiều.

#### Phần thưởng đặc biệt

- Mire Core.
- Slime King Essence.
- Rare/Epic Gem.
- Gold.
- Tỷ lệ nhỏ nhận Boss Summon Fragment.
- Nguyên liệu nâng cấp trang bị vùng Meadow.

### 3.2. Boss: `crypt_warden`

- **Tên hiển thị:** Crypt Warden — Kẻ Gác Mộ.
- **Art chọn:** B16 GiantSpirit.
- **Loại và vùng:** Dungeon Boss — Crypt Depths, Meadow.
- **Truyền thuyết:** Crypt Warden là linh hồn của người bảo vệ ngôi mộ cổ. Hắn canh giữ những di vật bị phong ấn và trừng phạt bất kỳ ai xâm nhập vào hầm mộ.

#### Giai đoạn 1 — Grave Guardian (100%–65% HP)

- Chém bằng vũ khí lớn theo hình quạt.
- Nhảy tới vị trí người chơi và tạo vụ nổ vòng tròn.
- Tạo một vòng năng lượng dưới chân người chơi sau một khoảng cảnh báo.
- Di chuyển chậm nhưng có tầm đánh rộng.

#### Giai đoạn 2 — Spirit Unbound (65%–30% HP)

- Cơ thể chuyển sang trạng thái linh hồn.
- Tốc độ di chuyển tăng.
- Tạo 3 vụ nổ vòng tròn liên tiếp.
- Có thể dịch chuyển tới vị trí gần người chơi.
- Gọi linh hồn nhỏ từ hai phía đấu trường.

#### Giai đoạn 3 — Eternal Sentence (30%–0% HP)

- Tạo vùng nguy hiểm ở một số khu vực của đấu trường.
- Chém mạnh theo đường thẳng.
- Tạo vòng nổ lớn ở trung tâm.
- Kết thúc chuỗi tấn công bằng một đòn chém mạnh có thời gian báo trước dài.

#### Cách đánh bại / mẹo

- Không đứng gần boss khi hắn bắt đầu chuẩn bị chém.
- Di chuyển khỏi vòng đỏ ngay khi xuất hiện.
- Tiêu diệt linh hồn nhỏ để tránh bị bao vây.
- Tận dụng khoảng nghỉ sau chuỗi ba vụ nổ.

#### Phần thưởng đặc biệt

- Crypt Core.
- Ancient Spirit Essence.
- Epic Ingredient.
- Rare/Epic Gem.
- Crypt Equipment Material.
- Tỷ lệ nhỏ nhận Crypt Summon Card Fragment.

### 3.3. Boss: `bone_colossus`

- **Tên hiển thị:** Cinder Colossus — Khổng Lồ Tro Tàn.
- **Art chọn:** B01 DemonCyclop.
- **Loại và vùng:** Area Boss — Snow (Frostvale).
- **Truyền thuyết:** Cinder Colossus là sinh vật khổng lồ bị phong ấn dưới lớp băng Frostvale. Lõi nhiệt bên trong cơ thể khiến nó có thể làm tan chảy lớp băng xung quanh, tạo ra những vùng nguy hiểm giữa vùng tuyết.
- **Lưu ý:** Có thể giữ thiết kế lửa/tro để tạo tương phản với Snow hoặc đổi tên và hiệu ứng nếu muốn boss thuần băng.

#### Giai đoạn 1 — Frozen Awakening (100%–70% HP)

- Đập tay xuống đất gây sát thương vùng.
- Nhảy tới người chơi tạo vòng nổ.
- Đấm mạnh về phía trước.
- Gọi Bone Grunt hoặc quái hỗ trợ.

#### Giai đoạn 2 — Burning Core (70%–30% HP)

- Lõi trong ngực phát sáng.
- Đòn đánh gây thêm sát thương nguyên tố.
- Đập đất tạo các vùng nứt nóng.
- Có thể ném đá lớn về phía người chơi.
- Gọi thêm quân hỗ trợ nhưng có giới hạn.

#### Giai đoạn 3 — Colossus Collapse (30%–0% HP)

- Tốc độ tấn công tăng.
- Liên tục đập đất tạo các vòng sóng chấn động.
- Có đòn nhảy lớn với vùng cảnh báo rộng.
- Sau đòn mạnh, boss mất thăng bằng và để lộ điểm yếu.

#### Cách đánh bại / mẹo

- Né khỏi vùng đỏ trước khi boss đập đất.
- Không đứng sát chân boss khi hắn nhảy.
- Tận dụng thời gian boss mất thăng bằng để gây sát thương.
- Trang bị kháng nguyên tố giúp giảm độ nguy hiểm của đòn đặc biệt.

#### Phần thưởng đặc biệt

- Colossus Core.
- Ancient Bone.
- Frost/Fire Ingredient.
- Epic Gem.
- Mount Armor Material.
- Tỷ lệ nhỏ nhận Boss Summon Fragment.

---

## 4. Boss mới theo vùng

Tổng thiết kế mục tiêu:
- Meadow: 1 World Boss, 1 Area Boss, 1 Dungeon Boss.
- Ash: 1 World Boss, 1–2 Area Boss, 1 Dungeon Boss.
- Snow: 1 World Boss, 1 Area Boss, 1 Dungeon Boss.
- Ember Vault: 1 Final Boss.

Các boss hiện có được tính vào số lượng trên, không tạo trùng thêm.

### 4.1. Meadow — World Boss

**Boss: `verdant_treant`**

- **Tên:** Verdant Treant — Cổ Thụ Thức Tỉnh.
- **Art:** Chọn một sprite cây/quái thực vật phù hợp trong `bosses.png`; nếu không có thì cần tạo asset mới.
- **Loại và vùng:** World Boss — Meadow.
- **Truyền thuyết:** Cổ Thụ Thức Tỉnh từng bảo vệ khu rừng Meadow trong hàng trăm năm. Khi nguồn năng lượng dưới lòng đất bị xáo trộn, nó thức tỉnh và xem mọi sinh vật xung quanh là kẻ xâm nhập.

**Giai đoạn 1 — Root Guardian (100%–70%)**
- Đập rễ xuống đất.
- Tạo gai cây tại vị trí người chơi.
- Quét cành cây theo hình quạt.
- Gọi dây leo trói người chơi trong thời gian ngắn nếu không né.

**Giai đoạn 2 — Ancient Forest (70%–30%)**
- Rễ cây lan rộng trên đấu trường.
- Tạo nhiều vùng gai liên tiếp.
- Gọi sinh vật rừng hỗ trợ.
- Tạo vùng hồi máu nhỏ cho bản thân nếu người chơi không phá các rễ phát sáng.

**Giai đoạn 3 — Nature's Wrath (30%–0%)**
- Đấu trường xuất hiện nhiều vùng rễ nguy hiểm.
- Treant đập hai tay xuống đất tạo sóng chấn động lớn.
- Có một đòn tấn công toàn khu vực nhưng phải báo trước đủ lâu.
- Sau đòn cuối, boss đứng yên trong thời gian ngắn.

**Phần thưởng:**
- Verdant Core.
- Ancient Root.
- Rare/Epic Gem.
- Gold.
- Vật liệu chế tạo trang bị rừng.

### 4.2. Meadow — Area Boss

**Boss: `ancient_mossback`**

- **Tên:** Ancient Mossback — Rùa Rêu Cổ Đại.
- **Art:** Cần tìm hoặc tạo sprite quái thú có mai rêu.
- **Loại và vùng:** Area Boss — Meadow Forest.
- **Truyền thuyết:** Ancient Mossback là sinh vật cổ đại sống dưới những gốc cây lâu năm. Chiếc mai phủ đầy rêu của nó hấp thụ năng lượng từ đất và bảo vệ nó khỏi những đòn tấn công thông thường.

**Giai đoạn 1 (100%–50%)**
- Đánh bằng chân trước.
- Thu mình vào mai để giảm sát thương.
- Tạo sóng đất nhỏ khi giẫm chân.

**Giai đoạn 2 (50%–0%)**
- Mai phát sáng và tạo vùng rêu hồi phục.
- Xoay người tạo sát thương xung quanh.
- Tạo gai rễ từ mặt đất.
- Có đòn thu mình rồi lao về phía trước.

**Phần thưởng:**
- Ancient Shell.
- Moss Core.
- Rare Ingredient.
- Gem.
- Nguyên liệu chế tạo giáp phòng thủ.

### 4.3. Meadow — Dungeon Boss

**Boss: `hollow_root_queen`**

- **Tên:** Hollow Root Queen — Nữ Hoàng Rễ Cây.
- **Art:** Cần sprite thực vật lớn hoặc tạo mới.
- **Loại và vùng:** Dungeon Boss — Meadow Root Temple.
- **Truyền thuyết:** Nữ Hoàng Rễ Cây cai quản một ngôi đền bị chôn vùi dưới rừng sâu. Bà điều khiển hệ thống rễ cây bên dưới hầm ngục và bảo vệ trái tim cổ đại.

**Giai đoạn 1**
- Tấn công bằng rễ cây.
- Gọi dây leo từ hai bên đấu trường.
- Tạo vùng gai dưới chân người chơi.

**Giai đoạn 2**
- Triệu hồi rễ cây khổng lồ từ bốn góc.
- Tạo vùng độc thực vật.
- Có thể hồi một phần HP khi đứng gần rễ phát sáng.

**Phần thưởng:**
- Queen Root.
- Ancient Seed.
- Epic Ingredient.
- Gem.
- Dungeon Equipment Material.

### 4.4. Ash — World Boss

**Boss: `infernal_dragon`**

- **Tên:** Infernal Dragon — Hỏa Long Tro Tàn.
- **Art:** Chọn một sprite rồng trong `bosses.png` nếu phù hợp; nếu chưa có thì tạo mới.
- **Loại và vùng:** World Boss — Ash.
- **Truyền thuyết:** Infernal Dragon từng ngủ sâu trong khe nứt dung nham của Ash. Khi các bàn thờ cổ được kích hoạt, nó thức tỉnh và bay lên từ biển lửa để tìm kiếm nguồn năng lượng mới.

**Giai đoạn 1 — Flame Awakening (100%–70%)**
- Phun lửa theo đường thẳng.
- Quét đuôi theo hình quạt.
- Đập cánh tạo luồng gió đẩy lùi.
- Bay lên rồi lao xuống vị trí được cảnh báo.

**Giai đoạn 2 — Infernal Storm (70%–30%)**
- Bay vòng quanh đấu trường.
- Phun ba luồng lửa theo các hướng khác nhau.
- Gọi các vùng dung nham từ mặt đất.
- Có đòn lao xuyên qua đấu trường.

**Giai đoạn 3 — Dragon's Wrath (30%–0%)**
- Cánh phát sáng, tốc độ tấn công tăng.
- Tạo mưa lửa trên đấu trường.
- Phun lửa diện rộng với vùng cảnh báo lớn.
- Sau đòn cuối phải có thời gian boss hạ cánh để người chơi phản công.

**Phần thưởng:**
- Infernal Dragon Core.
- Dragon Scale.
- Epic/Legendary Ingredient.
- Rare/Legendary Gem.
- Dragon Mount Material.
- Boss Card Fragment.

### 4.5. Ash — Area Boss

**Boss: `hollowfolk_warlord`**

- **Tên:** Hollowfolk Warlord — Đại Tướng Hollowfolk.
- **Art:** Dùng sprite chiến binh/quái lớn trong danh mục Bosses nếu có; nếu không cần tạo sprite riêng.
- **Loại và vùng:** Area Boss — Ash Fortress.
- **Truyền thuyết:** Warlord là thủ lĩnh quân đội Hollowfolk tại Ash. Hắn bảo vệ các pháo đài và kho báu cổ, đồng thời săn lùng những người mang Kindled Key.

**Giai đoạn 1**
- Chém vũ khí lớn.
- Lao tới người chơi.
- Gọi Hollowfolk Grunt hỗ trợ.

**Giai đoạn 2**
- Sử dụng kỹ năng đập đất.
- Triệu hồi Archer ở rìa đấu trường.
- Tăng sát thương và tốc độ tấn công.
- Có đòn quét diện rộng.

**Phần thưởng:**
- Warlord Insignia.
- Ash Token.
- Ancient Weapon Material.
- Epic Gem.
- Gold.

### 4.6. Ash — Dungeon Boss

**Boss: `obsidian_titan`**

- **Tên:** Obsidian Titan — Titan Hắc Diện.
- **Art:** Quái khổng lồ bằng đá núi lửa.
- **Loại và vùng:** Dungeon Boss — Ash Depths.
- **Truyền thuyết:** Obsidian Titan được tạo ra từ đá núi lửa và năng lượng bị phong ấn trong lòng đất. Nó là kẻ bảo vệ cánh cổng dẫn đến các vùng sâu hơn của Ash.

**Giai đoạn 1**
- Đập hai tay xuống đất.
- Ném đá dung nham.
- Tạo vùng nứt dưới chân người chơi.

**Giai đoạn 2**
- Lõi Obsidian phát sáng.
- Tạo các cột đá từ mặt đất.
- Có đòn quét ngang toàn đấu trường.
- Khi HP thấp, các vùng dung nham tồn tại lâu hơn.

**Phần thưởng:**
- Obsidian Heart.
- Lava Core.
- Epic/Legendary Ingredient.
- Gem.
- Vật liệu nâng cấp Yên và Giáp Mount.

### 4.7. Snow — World Boss

**Boss: `frost_leviathan`**

- **Tên:** Frost Leviathan — Cự Thú Băng Giá.
- **Art:** Quái thú băng khổng lồ hoặc rồng băng; cần xác minh sprite trong `bosses.png`.
- **Loại và vùng:** World Boss — Snow.
- **Truyền thuyết:** Frost Leviathan ngủ sâu dưới hồ băng lớn nhất Frostvale. Mỗi lần thức tỉnh, nhiệt độ toàn vùng giảm mạnh và những cơn bão tuyết bắt đầu bao phủ bản đồ.

**Giai đoạn 1**
- Phun luồng băng về phía trước.
- Quét đuôi.
- Tạo cột băng tại vị trí người chơi.

**Giai đoạn 2**
- Tạo bão tuyết làm giảm tầm nhìn.
- Đóng băng một số khu vực trên đấu trường.
- Lao nhanh xuyên qua mặt đất.
- Gọi Frost Wisp hỗ trợ.

**Giai đoạn 3**
- Tạo một vùng băng lớn ở trung tâm.
- Tấn công liên tiếp bằng cột băng.
- Có đòn đóng băng diện rộng với cảnh báo rõ ràng.
- Sau chuỗi tấn công, boss để lộ điểm yếu.

**Phần thưởng:**
- Leviathan Heart.
- Frozen Scale.
- Legendary Ingredient.
- Epic/Legendary Gem.
- Frost Mount Material.

### 4.8. Snow — Dungeon Boss

**Boss: `glacier_king`**

- **Tên:** Glacier King — Vua Băng Hà.
- **Art:** Người khổng lồ băng hoặc quái vật có vương miện băng.
- **Loại và vùng:** Dungeon Boss — Glacier Sanctum.
- **Truyền thuyết:** Glacier King là vị vua cổ đại bị phong ấn trong thánh điện băng. Hắn điều khiển những cơn bão lạnh và bảo vệ kho báu nằm sâu trong lòng núi tuyết.

**Giai đoạn 1**
- Đập búa băng.
- Tạo cột băng.
- Ném mảnh băng lớn.

**Giai đoạn 2**
- Tạo vùng sàn đóng băng.
- Triệu hồi các chiến binh băng.
- Tăng tốc độ tấn công.
- Có đòn quét hình vòng cung.

**Phần thưởng:**
- Glacier Crown.
- Ancient Ice Core.
- Legendary Ingredient.
- Gem.
- Trang bị Dungeon cấp cao.

---

## 5. Boss cuối game — Ember Vault

### Boss: `ember_vault_overlord`

- **Tên hiển thị:** Ember Overlord — Chúa Tể Hỏa Ngục.
- **Art:** Sử dụng một trong các boss có hình thái lớn và phù hợp trong `bosses.png`, hoặc tạo sprite mới.
- **Loại và vùng:** Final Boss — Ember Vault.
- **Cấp đề xuất:** 45+.
- **Truyền thuyết:** Ember Overlord là thực thể cổ đại kiểm soát lõi năng lượng nằm sâu dưới Ember Vault. Những bàn thờ và phong ấn ở ba vùng chỉ là các mảnh khóa giữ sức mạnh của nó. Khi toàn bộ phong ấn bị phá vỡ, Ember Overlord thức tỉnh và bắt đầu giải phóng năng lượng hủy diệt.

### Giai đoạn 1 — The Sealed Lord (100%–70%)

- Đánh cận chiến bằng vũ khí hoặc cánh tay năng lượng.
- Tạo vùng lửa dưới chân người chơi.
- Phóng đạn năng lượng theo đường thẳng.
- Gọi hai Ember Minion hỗ trợ.

### Giai đoạn 2 — Core Awakening (70%–35%)

- Lõi Ember phát sáng mạnh.
- Đấu trường xuất hiện các vùng dung nham.
- Phóng nhiều đạn năng lượng theo hình quạt.
- Tạo vòng lửa khép lại từ ngoài vào trong.
- Có đòn lao tới với cảnh báo bằng đường đỏ.

### Giai đoạn 3 — World Ender (35%–0%)

- Boss thay đổi hình thái.
- Các đòn tấn công có phạm vi lớn hơn.
- Tạo nhiều vùng lửa nhưng phải có khoảng trống an toàn.
- Gọi Ember Guardian.
- Thực hiện đòn cuối cùng tạo một vùng cảnh báo cực lớn.
- Sau khi né thành công, boss mất sức mạnh và mở ra thời gian gây sát thương tối đa.

### Cách đánh bại / mẹo

- Không đứng cố định một vị trí.
- Quan sát các vùng cảnh báo.
- Tiêu diệt Ember Minion khi chúng xuất hiện.
- Tận dụng thời gian boss hồi phục sau đòn diện rộng.
- Cần trang bị và Gem phù hợp để chống sát thương nguyên tố.

### Phần thưởng đặc biệt

- Ember Overlord Core.
- Legendary Gem.
- Legendary Ingredient.
- Ember Vault Equipment.
- Nguyên liệu tiến hóa Mount.
- Skin đặc biệt.
- Boss Card cực hiếm.
- Danh hiệu người đánh bại Final Boss.

---

## 6. Hệ thống Boss World theo khung giờ

### 6.1. Lịch xuất hiện

Đề xuất lịch thử nghiệm:

| Thời điểm trong ngày | Vùng | Boss |
|---|---|---|
| 09:00 | Meadow | Mire King |
| 12:00 | Ash | Infernal Dragon |
| 15:00 | Snow | Frost Leviathan |
| 18:00 | Meadow | Mire King |
| 21:00 | Ash | Infernal Dragon |
| 00:00 | Snow | Frost Leviathan |

- Thời gian là giờ của máy chủ/host trong chế độ LAN.
- Mỗi World Boss tồn tại tối đa 15 phút.
- Nếu bị tiêu diệt trước thời hạn, sự kiện kết thúc sớm.
- Nếu hết thời gian mà chưa bị tiêu diệt, boss rời khỏi bàn thờ.
- Có thông báo trước 5 phút và 1 phút.
- Khi boss xuất hiện, thông báo cho tất cả người chơi.
- Mỗi bàn thờ chỉ có một World Boss đang hoạt động.

Các khung giờ trên là lịch đề xuất, có thể thay đổi trong cấu hình.

### 6.2. Quy trình sự kiện

1. Hệ thống kiểm tra lịch.
2. Gửi thông báo sắp xuất hiện.
3. Bàn thờ phát sáng.
4. Boss xuất hiện.
5. Người chơi tham gia chiến đấu.
6. Hệ thống ghi nhận đóng góp.
7. Boss bị tiêu diệt hoặc hết thời gian.
8. Phân phối phần thưởng.
9. Bàn thờ bước vào thời gian hồi phục.

### 6.3. Điều kiện tham gia

- Người chơi cần đến đúng bàn thờ.
- Không yêu cầu vật phẩm triệu hồi.
- Có thể tham gia khi boss vẫn còn sống.
- Có thể rời khỏi khu vực và quay lại nếu sự kiện chưa kết thúc.
- Người chơi phải gây sát thương hoặc đóng góp hợp lệ mới nhận được thưởng tham gia.

---

## 7. Hệ thống Boss Summon Card — Thẻ triệu hồi Boss

Đây là hệ thống để người chơi chủ động gọi boss mạnh, không cần chờ World Boss xuất hiện.

### 7.1. Các loại thẻ

| ID | Tên thẻ | Phẩm chất | Boss |
|---|---|---|---|
| `card_meadow_guardian` | Meadow Guardian Card | Rare | Root Guardian |
| `card_ash_destroyer` | Ash Destroyer Card | Epic | Ash Destroyer |
| `card_snow_titan` | Snow Titan Card | Epic | Snow Titan |
| `card_dragon_lord` | Dragon Lord Card | Legendary | Ancient Dragon |
| `card_ember_overlord` | Ember Overlord Card | Legendary | Ember Overlord |

### 7.2. Cách nhận thẻ

- Đào đất trong từng vùng.
- Đánh bại mini-boss.
- Đánh bại Elite.
- Hoàn thành Dungeon.
- Nhận phần thưởng World Boss.
- Thưởng sự kiện đặc biệt.
- Ghép mảnh thẻ từ Boss Card Fragment.

Không phải tất cả boss đều có thẻ triệu hồi. World Boss vẫn có lịch xuất hiện riêng.

### 7.3. Cách sử dụng

1. Người chơi mở Inventory.
2. Chọn Boss Summon Card.
3. Xem tên boss, cấp đề xuất, phần thưởng và điều kiện triệu hồi.
4. Chọn sử dụng.
5. Hệ thống kiểm tra khu vực và điều kiện.
6. Hiển thị hiệu ứng triệu hồi.
7. Boss xuất hiện trong Boss Arena.
8. Người chơi chiến đấu.
9. Thẻ được tiêu thụ khi boss xuất hiện thành công.

### 7.4. Phân loại thẻ

**Rare Card**
- Triệu hồi boss cấp Meadow.
- Có độ khó vừa phải.
- Phần thưởng Rare Ingredient và Gem.

**Epic Card**
- Triệu hồi boss cấp Ash hoặc Snow.
- Có nhiều giai đoạn.
- Phần thưởng Epic Ingredient và Gem.

**Legendary Card**
- Triệu hồi boss khủng.
- Có 3 giai đoạn.
- Có thể có cơ chế chiến đấu đặc biệt.
- Phần thưởng Legendary Ingredient, Gem và vật liệu tiến hóa Mount.

### 7.5. Boss khủng được triệu hồi

**Ancient Dragon**
- ID: `summoned_ancient_dragon`
- Phẩm chất thẻ: Legendary.
- Địa điểm: Boss Arena.
- Đòn đánh:
  - Phun lửa diện rộng.
  - Lao từ trên cao xuống.
  - Tạo mưa lửa.
  - Gọi rồng con.
- Phần thưởng:
  - Dragon Heart.
  - Legendary Gem.
  - Dragon Scale.
  - Mount Evolution Material.

**Ash Devourer**
- ID: `summoned_ash_devourer`
- Phẩm chất thẻ: Epic.
- Địa điểm: Ash Boss Arena.
- Đòn đánh:
  - Hút người chơi về trung tâm.
  - Tạo vùng tro độc.
  - Phóng gai tro.
- Phần thưởng:
  - Ash Devourer Core.
  - Epic Ingredient.
  - Gem.

**Frost Abyss King**
- ID: `summoned_frost_abyss_king`
- Phẩm chất thẻ: Legendary.
- Địa điểm: Snow Boss Arena.
- Đòn đánh:
  - Tạo bão tuyết.
  - Đóng băng mặt đất.
  - Gọi các cột băng.
  - Tạo lá chắn băng.
- Phần thưởng:
  - Abyss Ice Core.
  - Legendary Ingredient.
  - Gem.
  - Frost Mount Evolution Material.

---

## 8. Quy tắc phần thưởng

### 8.1. Thưởng tham gia

Người chơi tham gia hợp lệ được nhận:
- Gold.
- Boss Token.
- Nguyên liệu theo vùng.
- Một phần thưởng cơ bản theo loại boss.

Điều kiện:
- Phải gây sát thương hoặc đóng góp hỗ trợ hợp lệ.
- Không nhận thưởng chỉ bằng cách đứng gần boss.
- Có thể đặt mức đóng góp tối thiểu.
- Mỗi người chỉ nhận thưởng một lần cho mỗi trận.

### 8.2. Thưởng kết liễu

Người chơi gây đòn kết liễu nhận thêm:
- Gold Bonus.
- Boss Trophy.
- Một phần thưởng đặc biệt hoặc lượt rơi thêm.

Không nên để người kết liễu nhận toàn bộ phần thưởng tốt nhất, vì như vậy người chơi có sát thương thấp sẽ không muốn tham gia.

### 8.3. Thưởng theo đóng góp

Có thể tính đóng góp từ:
- Damage gây ra.
- Healing cho người chơi khác.
- Hỗ trợ tiêu diệt mục tiêu phụ.
- Thực hiện cơ chế đặc biệt của boss.

Đề xuất phân phối:
- Thưởng tham gia: tất cả người chơi đủ điều kiện.
- Thưởng đóng góp: dựa trên tỷ lệ đóng góp.
- Thưởng kết liễu: phần thưởng bổ sung.
- Thưởng ngẫu nhiên: một số vật phẩm hiếm có xác suất riêng.

Không nên chỉ tính Damage vì các nhân vật hỗ trợ hoặc người chơi trang bị phòng thủ cũng cần có cơ hội nhận thưởng.

### 8.4. Chống nhận thưởng nhiều lần

- Mỗi trận boss có một `boss_encounter_id`.
- Mỗi người chơi có trạng thái nhận thưởng riêng.
- Không phát thưởng hai lần khi reconnect.
- Phần thưởng phải được lưu trước khi xác nhận hoàn thành.
- Nếu người chơi mất kết nối ngay sau khi boss chết, vẫn có thể nhận lại phần thưởng chưa được xác nhận.

---

## 9. Quy tắc Boss bị đánh bại người chơi

- Nếu người chơi bị boss hạ, xử lý theo luật tử vong của vùng.
- Không tự động mất toàn bộ trang bị.
- Vật phẩm rơi ra phải tuân thủ quy tắc vùng Meadow, Ash và Snow.
- Người chơi có thể hồi sinh và quay lại nếu boss vẫn đang hoạt động.
- Nếu boss kết thúc trong lúc người chơi hồi sinh, người chơi chỉ nhận thưởng nếu đã đáp ứng điều kiện đóng góp trước đó.

Đề xuất:
- Meadow: không rơi vật phẩm quan trọng.
- Ash: có thể mất một phần tài nguyên theo luật vùng.
- Snow: hình phạt cao hơn Ash nhưng không mất vĩnh viễn các vật phẩm quý hiếm.
- Dungeon: xử lý theo luật riêng của Dungeon.

---

## 10. Thanh máu, giao diện và âm thanh

### Thanh máu Boss

- Boss có thanh HP lớn ở phía trên màn hình.
- Hiển thị tên boss.
- Hiển thị Level.
- Hiển thị giai đoạn hiện tại.
- Hiển thị thời gian còn lại đối với World Boss.
- Hiển thị số người đang tham gia nếu là trận nhiều người.

### Cảnh báo đòn đánh

Mọi đòn nguy hiểm phải có dấu hiệu trước khi gây sát thương:

- Vòng đỏ: vùng sát thương trên mặt đất.
- Đường đỏ: đường lao hoặc đòn đánh theo hướng.
- Vùng quạt đỏ: đòn đánh hình nón.
- Vòng tròn lớn: đòn diện rộng.
- Vùng xanh hoặc hiệu ứng khác: vùng an toàn nếu có cơ chế tương ứng.

Quy tắc:
- Vùng cảnh báo phải xuất hiện trước khi sát thương xảy ra.
- Không được tạo sát thương ngay khi vùng đỏ vừa xuất hiện.
- Thời gian cảnh báo phải tương ứng độ nguy hiểm.
- Đòn mạnh cần thời gian né dài hơn đòn thường.
- Hiệu ứng cảnh báo phải dễ nhìn trên nền bản đồ.

### Âm thanh

- Mỗi World Boss có nhạc nền riêng.
- Boss Dungeon có âm thanh môi trường riêng.
- Khi boss chuyển giai đoạn có hiệu ứng âm thanh.
- Khi boss chuẩn bị đòn mạnh có âm thanh báo hiệu.
- Khi boss chết có hiệu ứng kết thúc trận.

---

## 11. Data Structure đề xuất

BossDefinition:
- boss_id
- display_name
- boss_type
- region_id
- level
- lore
- art_id
- base_stats
- phases
- abilities
- drop_table_id
- spawn_config

BossPhase:
- phase_id
- hp_threshold
- movement_speed_multiplier
- damage_multiplier
- ability_pool
- visual_effect
- music_config

BossAbility:
- ability_id
- damage
- range
- cooldown
- warning_duration
- warning_shape
- warning_radius
- animation
- effect

WorldBossSchedule:
- boss_id
- altar_id
- spawn_times
- duration
- warning_before_spawn
- respawn_config

BossSummonCard:
- card_id
- boss_id
- rarity
- consume_on_success
- valid_regions
- required_level
- drop_sources

BossEncounter:
- encounter_id
- boss_id
- start_time
- end_time
- participant_ids
- damage_contribution
- reward_state
- encounter_status

BossReward:
- reward_id
- participant_id
- participation_reward
- contribution_reward
- final_hit_reward
- claimed_at

---

## 12. Những thông số cần cân bằng

- HP từng boss.
- Damage từng đòn.
- Thời gian cảnh báo.
- Thời gian hồi chiêu.
- Tỷ lệ chuyển giai đoạn.
- Số quái hỗ trợ được triệu hồi.
- Thời gian tồn tại World Boss.
- Lịch xuất hiện World Boss.
- Tỷ lệ rơi Boss Card.
- Tỷ lệ ghép mảnh thẻ.
- Điều kiện nhận thưởng.
- Phần thưởng tham gia.
- Phần thưởng kết liễu.
- Phần thưởng theo đóng góp.

Tất cả thông số cần cấu hình được, không hardcode trực tiếp vào AI.

## 13. Quy tắc bắt buộc khi triển khai

1. Boss có 2–3 giai đoạn.
2. Đòn đánh nguy hiểm luôn có cảnh báo trước.
3. World Boss xuất hiện theo khung giờ.
4. Area Boss canh giữ địa điểm riêng.
5. Dungeon Boss nằm cuối Dungeon.
6. Boss Summon Card là hệ thống riêng.
7. Thẻ chỉ bị tiêu thụ khi triệu hồi thành công.
8. Có thưởng tham gia.
9. Có thưởng kết liễu.
10. Có thể mở rộng thưởng theo đóng góp.
11. Có thanh HP lớn và thông tin boss.
12. Có âm thanh riêng cho boss quan trọng.
13. Ember Vault là nội dung cuối game.
14. Không để Boss Summon Card thay thế World Boss theo lịch.
15. Không sử dụng asset chưa rõ giấy phép.