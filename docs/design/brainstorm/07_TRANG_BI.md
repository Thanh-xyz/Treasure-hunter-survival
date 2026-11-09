# Phiếu 7 — Trang bị và đá ép

Trang bị có 5 ô: mũ, giáp, giày, vũ khí, lưng. Mỗi ô có 3 dòng:
- **mũ, giáp, giày, lưng:** Tank / Damage / Balanced;
- **vũ khí:** Kiếm (cân bằng) / Rìu (sát thương) / Dao găm (tốc độ).

Chỉ số **tự tính theo công thức** từ ô, dòng, độ hiếm và cấp, nên ở đây chỉ cần viết **tên, mô tả
và chọn icon**. Đá ép thêm DEF và các chỉ số phụ.

Icon trang bị sẽ lấy từ thư mục Items của Ninja Adventure (CC0). Ảnh danh mục icon sẽ được bổ sung
khi làm giai đoạn icon; tạm thời có thể mô tả hình mong muốn.

# PHIẾU 7 — TRANG BỊ VÀ ĐÁ ÉP

## 1. Quy tắc chung

### 1.1. Trang bị

Nhân vật có 5 ô trang bị:

1. Mũ (Helmet).
2. Giáp (Armor).
3. Giày (Boots).
4. Vũ khí (Weapon).
5. Lưng (Back).

Mỗi ô có 3 dòng trang bị:

| Ô | Dòng | Định hướng |
|---|---|---|
| Mũ | Tank | Phòng thủ, sinh tồn |
| Mũ | Damage | Tấn công |
| Mũ | Balanced | Cân bằng |
| Giáp | Tank | Phòng thủ, sinh tồn |
| Giáp | Damage | Tấn công |
| Giáp | Balanced | Cân bằng |
| Giày | Tank | Phòng thủ, sinh tồn |
| Giày | Damage | Tấn công |
| Giày | Balanced | Cân bằng |
| Vũ khí | Kiếm | Cân bằng |
| Vũ khí | Rìu | Sát thương cao |
| Vũ khí | Dao găm | Tốc độ tấn công |
| Lưng | Tank | Phòng thủ, sinh tồn |
| Lưng | Damage | Tấn công |
| Lưng | Balanced | Cân bằng |

Chỉ số trang bị được tính tự động dựa trên:
- Ô trang bị.
- Dòng trang bị.
- Độ hiếm.
- Cấp trang bị.

Không nhập chỉ số cố định vào từng món. Tên và mô tả chỉ thể hiện phong cách, chủ đề và công dụng định hướng của trang bị.

### 1.2. Độ hiếm

Có 4 độ hiếm:
- Common — Trắng.
- Uncommon — Xanh dương.
- Epic — Tím.
- Legendary — Vàng.

Mỗi độ hiếm có thể có tên biến thể riêng. Giữ ID nội bộ ổn định để không ảnh hưởng save game và dữ liệu trang bị.

### 1.3. Quy tắc tên theo họ

Giữ ba họ trang bị:

- **Ironbark:** dòng Tank, hình ảnh gỗ cổ thụ, vỏ cây, rễ cây và giáp tự nhiên.
- **Ember:** dòng Damage, hình ảnh lửa, tro nóng, kim loại nung đỏ.
- **Wayfarer:** dòng Balanced, hình ảnh lữ khách, da thuộc, vải và trang bị thám hiểm.

Tên theo độ hiếm đề xuất:

| Độ hiếm | Ironbark | Ember | Wayfarer |
|---|---|---|---|
| Common | Ironbark | Ember | Wayfarer |
| Uncommon | Heartwood | Flameforged | Pathfinder |
| Epic | Ancientroot | Infernal | Stormwalker |
| Legendary | Worldtree | Eternal Flame | Celestial |

Tên họ có thể được sử dụng làm tiền tố hoặc tên bộ. Không bắt buộc đổi toàn bộ tên món đồ khi tăng cấp; có thể giữ tên gốc và bổ sung hậu tố theo độ hiếm.

## 2. Danh sách trang bị cơ bản

Tất cả 16 món dưới đây sử dụng độ hiếm Common, ngoại trừ Emberforged Blade là Rare.

| ID | Tên mới | Ô | Dòng | Mô tả | Icon mong muốn |
|---|---|---|---|---|---|
| `ironbark_helm` | Ironbark Helm | Mũ | Tank | Mũ sắt gia cố bằng vỏ cây cổ thụ, được chế tạo để bảo vệ đầu trước những đòn đánh mạnh. | Mũ sắt nâu, có rễ cây và lá xanh quấn quanh |
| `ember_visor` | Ember Visor | Mũ | Damage | Chiếc mặt nạ nhẹ được nung bằng lửa đỏ, mang phong cách của chiến binh thiên về tấn công. | Mặt nạ kim loại đỏ cam, khe mắt phát sáng |
| `wayfarer_hood` | Wayfarer Hood | Mũ | Balanced | Chiếc mũ trùm đầu của những nhà thám hiểm, nhẹ và phù hợp với mọi hành trình. | Mũ trùm vải nâu, có viền da |
| `ironbark_plate` | Ironbark Plate | Giáp | Tank | Bộ giáp ngực nhiều lớp kết hợp kim loại và gỗ cứng, giúp người mặc chống chịu tốt hơn. | Giáp ngực nâu xanh, có các mảng vỏ cây |
| `ember_harness` | Ember Harness | Giáp | Damage | Giáp chiến đấu nhẹ với các đường kim loại nóng đỏ, dành cho người ưu tiên sức tấn công. | Giáp ngực đỏ đen, lõi cam phát sáng |
| `wayfarer_coat` | Wayfarer Coat | Giáp | Balanced | Áo khoác thám hiểm bền chắc, cân bằng giữa sự linh hoạt và khả năng bảo vệ. | Áo khoác da nâu, dây đai và túi nhỏ |
| `ironbark_greaves` | Ironbark Greaves | Giày | Tank | Đôi giày bọc giáp dày, được gia cố bằng vật liệu từ cây cổ thụ. | Ủng nặng màu nâu, có giáp kim loại và rễ cây |
| `ember_treads` | Ember Treads | Giày | Damage | Đôi giày nhẹ với lõi nhiệt bên trong, phù hợp với chiến binh có lối đánh chủ động. | Giày đỏ cam, có tia lửa phía sau |
| `wayfarer_boots` | Wayfarer Boots | Giày | Balanced | Đôi ủng dành cho những chuyến đi dài, bền bỉ và dễ di chuyển trên nhiều địa hình. | Ủng da nâu, dây buộc và đế dày |
| `ashwood_blade` | Ashwood Blade | Vũ khí | Kiếm | Thanh kiếm làm từ gỗ tro và kim loại, có trọng lượng vừa phải và dễ sử dụng. | Kiếm thẳng, chuôi gỗ nâu, lưỡi bạc |
| `ironbark_cleaver` | Ironbark Cleaver | Vũ khí | Rìu | Chiếc rìu chiến nặng với lưỡi thép dày, được thiết kế để tung ra những nhát chém uy lực. | Rìu lớn, lưỡi xám đậm, cán gỗ |
| `ember_dirk` | Ember Dirk | Vũ khí | Dao găm | Dao găm nhỏ có lưỡi đỏ nóng, thích hợp với phong cách chiến đấu nhanh và liên tục. | Dao găm ngắn, lưỡi đỏ cam |
| `ironbark_pack` | Ironbark Pack | Lưng | Tank | Ba lô bọc giáp với các lớp gỗ cứng, giúp người mang có thêm khả năng bảo vệ. | Ba lô nâu xanh, có tấm giáp gỗ |
| `ember_quiver` | Ember Quiver | Lưng | Damage | Ống đựng tên mang năng lượng lửa, dành cho những chiến binh theo đuổi sức tấn công. | Ống tên đỏ cam, có vài mũi tên phát sáng |
| `wayfarer_cloak` | Wayfarer Cloak | Lưng | Balanced | Áo choàng của nhà thám hiểm, nhẹ và thuận tiện khi di chuyển qua nhiều vùng đất. | Áo choàng xanh rêu hoặc nâu, có khóa cài |
| `emberforged_blade` | Emberforged Blade | Vũ khí | Kiếm — Rare | Thanh kiếm được rèn từ kim loại hấp thụ nhiệt lửa, có sức mạnh vượt trội so với vũ khí thông thường. | Kiếm thép đỏ cam, lưỡi có vệt lửa và lõi phát sáng |

## 3. Bộ trang bị theo vùng

Đề xuất có set trang bị theo vùng. Mục tiêu là tạo động lực khám phá và săn boss ở từng khu vực.

Một set gồm 5 món tương ứng với 5 ô trang bị. Thưởng set được kích hoạt khi mặc đủ số món, không phụ thuộc vào việc người chơi có lắp đá hay không.

| Set | Khu vực | Chủ đề | Thưởng 2 món | Thưởng 4 món |
|---|---|---|---|---|
| Meadow Guardian | Meadow | Rừng xanh, rễ cây cổ thụ | Tăng khả năng sinh tồn | Tăng DEF và hồi phục |
| Ashen Warrior | Ash | Tro nóng, dung nham | Tăng sát thương | Tăng sát thương lửa và chí mạng |
| Frostborn Sentinel | Snow | Băng tuyết, tinh thể băng | Tăng phòng thủ | Tăng DEF và kháng hiệu ứng băng |

Quy tắc:
- 2 món: kích hoạt bonus đầu tiên.
- 4 món: kích hoạt bonus thứ hai.
- 5 món: không tạo thêm bonus thứ ba ở phiên bản đầu.
- Người chơi có thể kết hợp nhiều set khác nhau.
- Bonus set được cộng sau khi tính chỉ số cơ bản của trang bị.
- Giá trị bonus phải được cấu hình riêng, không viết cứng trong mô tả vật phẩm.

Tên set và hiệu ứng cụ thể là đề xuất; có thể bổ sung khi thiết kế loot theo vùng.

## 4. Hệ thống đá ép

### 4.1. Quy tắc đã chốt

- Đá ép có 4 bậc: Trắng, Xanh, Tím, Vàng.
- Mỗi món trang bị có 8 ô đá.
- Pet có 8 ô đá.
- Mount có 8 ô đá.
- Người chơi tự chọn loại đá và vị trí lắp.
- Ghép 6 viên đá cùng loại, cùng bậc để nhận 1 viên đá cùng loại ở bậc tiếp theo.
- Đá Vàng là bậc cao nhất, không thể ghép lên bậc tiếp theo.
- Không có hệ thống sao.
- Đá ép cung cấp DEF và các chỉ số phụ.
- Đá không tự thay đổi tên, dòng hoặc độ hiếm của trang bị.

### 4.2. Tên và hình ảnh các loại đá

| ID đề xuất | Tên đá | Chỉ số | Màu / hình | Nguồn nhận đề xuất |
|---|---|---|---|---|
| `stone_guard` | Guardian Stone | DEF | Tinh thể trắng hình khiên | Phá địa hình, quái thường |
| `stone_critical` | Precision Stone | Chí mạng | Tinh thể xanh dương hình ngôi sao | Quái tinh anh, mini-boss |
| `stone_critical_damage` | Ravager Stone | Sát thương chí mạng | Tinh thể tím hình lưỡi rìu | Boss khu vực, dungeon |
| `stone_lifesteal` | Vampiric Stone | Hút máu | Tinh thể đỏ sẫm hình giọt máu | Boss, rương hiếm |
| `stone_dodge` | Wind Stone | Né tránh | Tinh thể xanh ngọc hình lông vũ | Phá địa hình, quái nhanh |
| `stone_accuracy` | Hunter Stone | Chính xác | Tinh thể vàng nhạt hình mắt | Quái đánh xa, nhiệm vụ |
| `stone_regeneration` | Renewal Stone | Hồi máu | Tinh thể xanh lá hình lá cây | Quái rừng, rương |
| `stone_reflection` | Thorns Stone | Phản sát thương | Tinh thể xám bạc hình gai | Quái tank, boss |
| `stone_fire` | Inferno Stone | Sát thương lửa | Tinh thể cam đỏ hình ngọn lửa | Quái vùng Ash, boss lửa |
| `stone_ice` | Frost Stone | Sát thương băng | Tinh thể xanh băng hình bông tuyết | Quái vùng Snow, boss băng |
| `stone_poison` | Venom Stone | Sát thương độc | Tinh thể tím lục hình giọt độc | Quái độc, dungeon |

### 4.3. Màu sắc và độ hiếm

Mỗi loại đá có đủ 4 bậc:

| Bậc | Độ hiếm | Màu | Hình ảnh |
|---|---|---|---|
| I | Common | Trắng | Tinh thể nhỏ, ánh sáng nhẹ |
| II | Uncommon | Xanh dương | Tinh thể có viền sáng |
| III | Epic | Tím | Tinh thể lớn, có hiệu ứng phát sáng |
| IV | Legendary | Vàng | Tinh thể vàng rực, có hiệu ứng hào quang |

Tên đá không thay đổi theo bậc. Ví dụ:
- Guardian Stone I.
- Guardian Stone II.
- Guardian Stone III.
- Guardian Stone IV.

Mỗi bậc có một icon nền tảng giống nhau, chỉ thay đổi màu sắc, kích thước hoặc hiệu ứng viền để người chơi nhận diện nhanh.

### 4.4. Công thức ghép đá

Công thức:

`6 viên đá cùng loại + cùng bậc = 1 viên đá cùng loại + bậc tiếp theo`

Ví dụ:
- 6 Guardian Stone I → 1 Guardian Stone II.
- 6 Guardian Stone II → 1 Guardian Stone III.
- 6 Guardian Stone III → 1 Guardian Stone IV.
- 6 Guardian Stone IV → Không thể ghép tiếp.

Quy tắc:
- Không ghép lẫn các loại đá khác nhau.
- Không ghép lẫn các bậc khác nhau.
- Không có xác suất thất bại trong công thức cơ bản.
- Chỉ trừ nguyên liệu khi người chơi xác nhận ghép thành công.
- Có thể thực hiện tại khu vực lửa trại hoặc giao diện ghép đá riêng.

Tỉ lệ 6:1 là tỉ lệ cố định, không phụ thuộc cấp nhân vật.

### 4.5. Lắp và tháo đá

- Mỗi trang bị, Pet và Mount có 8 ô đá.
- Người chơi có thể lắp nhiều loại đá khác nhau trên cùng một món.
- Có thể lắp nhiều viên cùng loại nếu còn ô trống.
- Một ô chỉ chứa một viên đá.
- Khi thay đá, viên đá cũ không tự động bị mất.
- Đề xuất cho phép tháo đá miễn phí tại khu vực an toàn hoặc giao diện quản lý trang bị.
- Đá đã tháo được trả về kho đồ.
- Không cho phép tháo đá khi đang trong trạng thái chiến đấu.

Lý do: 8 ô đá đã tạo ra nhiều lựa chọn xây dựng nhân vật; không nên khiến người chơi mất đá chỉ vì muốn thay đổi cách phối hợp chỉ số.

### 4.6. Cách tính chỉ số đá

Mỗi loại đá có một giá trị chỉ số cơ bản theo bậc.

Công thức đề xuất:

`StoneBonus = BaseValue[stone_type] × TierMultiplier[tier]`

Các hệ số và giá trị cụ thể phải nằm trong cấu hình cân bằng, không gắn trực tiếp vào từng vật phẩm.

Tổng chỉ số đá:

`TotalStoneBonus = Sum(StoneBonus của tất cả đá đang lắp)`

Tổng chỉ số nhân vật được tính từ:
- Chỉ số nhân vật.
- Chỉ số trang bị.
- Chỉ số Pet.
- Chỉ số Mount.
- Chỉ số đá.
- Bonus set.
- Các buff tạm thời.

Lưu ý:
- Cần giới hạn các chỉ số dễ gây mất cân bằng như né tránh, hút máu, chí mạng và phản sát thương.
- Sát thương lửa, băng và độc phải có cơ chế áp dụng rõ ràng trong combat.
- DEF cần có công thức giảm sát thương hợp lý, tránh để 8 viên DEF khiến nhân vật gần như bất tử.
- Không nên để chỉ số đá cộng dồn vô hạn.

## 5. Nguồn nhận trang bị và đá

### 5.1. Trang bị

| Nguồn | Phần thưởng |
|---|---|
| Phá địa hình Meadow | Trang bị Common, nguyên liệu cơ bản |
| Quái thường Meadow | Trang bị Common, nguyên liệu |
| Phá địa hình Ash | Trang bị Common, Uncommon |
| Quái thường Ash | Trang bị Common, Uncommon |
| Phá địa hình Snow | Trang bị Uncommon, có cơ hội nhận Rare |
| Quái thường Snow | Trang bị Uncommon, Rare |
| Mini-boss | Trang bị Rare, nguyên liệu hiếm |
| World Boss | Trang bị Epic, nguyên liệu cao cấp |
| Dungeon Boss | Trang bị Rare, Epic |
| Boss triệu hồi | Phần thưởng đặc biệt, có cơ hội nhận trang bị Epic hoặc Legendary |
| Thợ rèn | Chế tạo hoặc nâng cấp trang bị |

### 5.2. Đá ép

| Nguồn | Đá có thể nhận |
|---|---|
| Phá địa hình | Đá Trắng, có cơ hội nhận Xanh |
| Quái thường | Đá Trắng |
| Quái tinh anh | Đá Trắng, Xanh |
| Mini-boss | Đá Xanh, có cơ hội nhận Tím |
| Boss khu vực | Đá Xanh, Tím |
| Dungeon Boss | Đá Tím, có cơ hội nhận Vàng |
| World Boss | Đá Tím, Vàng với tỉ lệ thấp |
| Boss triệu hồi | Đá Tím, Vàng |
| Sự kiện | Đá theo phần thưởng sự kiện |
| NPC thương nhân | Có thể bán đá cơ bản hoặc đá theo chu kỳ |

Các nguồn và tỉ lệ rơi là đề xuất cân bằng, cần cấu hình riêng theo vùng và độ khó. Không nên cho đá Vàng rơi phổ biến từ quái thường.

## 6. Icon và quy chuẩn hình ảnh

Toàn bộ icon trang bị và đá ép sử dụng hình ảnh từ thư mục Items của Ninja Adventure Asset Pack.

Yêu cầu:
- Ưu tiên icon có sẵn trong pack.
- Không tự ý tạo sprite mới nếu đã có icon phù hợp.
- Không sử dụng một icon không liên quan chỉ để lấp chỗ trống.
- Nếu không tìm thấy icon phù hợp, ghi rõ `NEEDS_ASSET` để bổ sung sau.
- Giữ phong cách pixel art nhất quán.
- Icon hiển thị trong inventory phải rõ ở kích thước nhỏ.
- Các bậc đá sử dụng chung hình dạng nhưng khác màu và hiệu ứng.
- Lưu mapping icon trong một file dữ liệu riêng để dễ thay đổi.

Danh mục icon chi tiết sẽ được bổ sung ở giai đoạn kiểm kê và gán icon.

## 7. Vật phẩm khác và công cụ

Phiên bản đầu tiên chưa cần mở rộng quá nhiều vật phẩm tiêu hao. Ưu tiên:
- Health Potion: hồi HP.
- Greater Health Potion: hồi lượng HP lớn hơn.
- Fire Resistance Potion: tăng khả năng chống chịu sát thương lửa trong thời gian ngắn.
- Ice Resistance Potion: tăng khả năng chống chịu sát thương băng.
- Poison Resistance Potion: tăng khả năng chống chịu sát thương độc.

Công cụ:
- Axe: chặt cây và thu thập gỗ.
- Pickaxe: khai thác đá và khoáng sản.
- Shovel: đào đất, tìm nguyên liệu và vật phẩm đặc biệt.
- Fishing Rod: câu cá và thu thập nguyên liệu từ nước.

Công cụ là nhóm vật phẩm riêng, không chiếm 5 ô trang bị chiến đấu và không sử dụng 8 ô đá trong phiên bản đầu.

## 8. Yêu cầu dữ liệu và triển khai

Mỗi trang bị cần có:
- `id`
- `display_name`
- `description`
- `equipment_slot`
- `equipment_line`
- `rarity`
- `icon_id`
- `set_id` (có thể null)

Mỗi loại đá cần có:
- `id`
- `display_name`
- `description`
- `stat_type`
- `tier`
- `icon_id`
- `base_value`

Mỗi món trang bị, Pet và Mount cần lưu:
- Danh sách 8 ô đá.
- Mỗi ô lưu ID viên đá đang được lắp hoặc null.
- Không lưu tổng chỉ số đá như một giá trị cố định; cần tính lại từ dữ liệu đá đang lắp.

Yêu cầu quan trọng:
- ID nội bộ không thay đổi khi đổi tên hiển thị hoặc icon.
- Không hardcode chỉ số trong từng món.
- Có thể thêm trang bị và đá mới bằng dữ liệu mà không phải viết lại hệ thống tính chỉ số.
- Dữ liệu save game phải lưu được đầy đủ trạng thái trang bị và 8 ô đá.
- Khi tháo, ghép hoặc lắp đá, phải cập nhật kho đồ và trang bị trong cùng một giao dịch logic để tránh mất hoặc nhân đôi vật phẩm.

## 9. Các quyết định đã chốt và đề xuất

**Đã chốt:**
- 5 ô trang bị.
- Mỗi ô có 3 dòng theo phân loại đã nêu.
- 4 độ hiếm trang bị.
- Đá có 4 bậc trắng, xanh, tím, vàng.
- Ghép 6 viên cùng loại, cùng bậc thành 1 viên bậc tiếp theo.
- Mỗi trang bị, Pet và Mount có 8 ô đá.
- Chỉ số tính tự động theo công thức.

**Đề xuất trong phiếu này:**
- Giữ 3 họ Ironbark, Ember, Wayfarer.
- Thêm tên họ nâng cấp theo độ hiếm.
- Có set theo vùng, thưởng 2/4 món.
- Tháo đá không mất đá.
- Đá Vàng không thể ghép tiếp.
- Đá Vàng chỉ nhận từ nội dung khó hoặc phần thưởng hiếm.

