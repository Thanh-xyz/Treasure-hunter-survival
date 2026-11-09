# Phiếu brainstorm Cinderwild

Bộ phiếu này để **chủ dự án tự viết mô tả** cho nhân vật, thú cưng, thú cưỡi, quái, boss, NPC,
trang bị và thế giới. Claude sẽ đọc các phiếu đã điền để đưa vào dữ liệu game, rồi chọn art và
viết code theo đúng mô tả.

## Cách điền

1. Mở từng phiếu theo thứ tự bên dưới.
2. Điền vào các dòng có dấu **✍️**. Dòng nào chưa nghĩ ra thì cứ để trống, Claude sẽ hỏi lại.
3. Chọn hình bằng **mã art** trong ảnh danh mục (ví dụ `C25`, `A04`, `M53`, `B14`).
   - Có thể ghi nhiều mã (ví dụ `C25 hoặc C24`), hoặc ghi "chưa chọn".
4. Phần **"Hiện tại trong game"** là dữ liệu đang có, chỉ để tham khảo. Muốn đổi thì ghi vào ô ✍️.
5. Lưu file và báo Claude "đã điền phiếu …".

## Ảnh danh mục (art CC0, đã xác minh giấy phép)

| Ảnh | Nội dung | Mã |
| --- | --- | --- |
| [img/characters.png](img/characters.png) | 91 nhân vật: 4 hướng + chân dung (faceset) | `C01`–`C91` |
| [img/animals.png](img/animals.png) | 26 động vật (hợp làm thú cưng, thú cưỡi) | `A01`–`A26` |
| [img/monsters.png](img/monsters.png) | 66 quái thường | `M01`–`M66` |
| [img/bosses.png](img/bosses.png) | 20 boss | `B01`–`B20` |

Bảng tra mã ↔ tên thư mục: [img/catalog_index.json](img/catalog_index.json).
Nguồn art: Ninja Adventure (Pixel-boy & AAA, CC0); tileset và UI thêm từ Kenney (CC0).

## Danh sách phiếu

| # | Phiếu | Nội dung |
| --- | --- | --- |
| 1 | [01_NHAN_VAT.md](01_NHAN_VAT.md) | Nhân vật người chơi (một nhân vật, nhiều skin) và bộ chỉ số |
| 2 | [02_NPC.md](02_NPC.md) | NPC ở Hearthmoor và trên bản đồ |
| 3 | [03_THU_CUNG.md](03_THU_CUNG.md) | Thú cưng |
| 4 | [04_THU_CUOI.md](04_THU_CUOI.md) | Thú cưỡi (mount) |
| 5 | [05_QUAI_VAT.md](05_QUAI_VAT.md) | Quái thường theo 3 vùng |
| 6 | [06_BOSS.md](06_BOSS.md) | Boss |
| 7 | [07_TRANG_BI.md](07_TRANG_BI.md) | Tên và mô tả trang bị, đá ép |
| 8 | [08_THE_GIOI.md](08_THE_GIOI.md) | Thế giới, vùng đất, cốt truyện, chuỗi nhiệm vụ |

## Lưu ý về tính nguyên bản

- Tên, mô tả, câu thoại và cốt truyện phải là **của Cinderwild**. Không dùng tên nhân vật, quái,
  vật phẩm, địa danh hay câu chữ của Treasure Hunter hay game khác.
- Art chỉ lấy từ ảnh danh mục ở trên (CC0). Cần hình chưa có thì ghi mô tả, Claude sẽ tìm thêm
  nguồn miễn phí có giấy phép rõ ràng.
- **ID** (cột `id`) là khóa trong code và save, **không đổi**. Tên hiển thị thì đổi thoải mái.
