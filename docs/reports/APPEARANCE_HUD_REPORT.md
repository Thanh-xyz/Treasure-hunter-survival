# Ngoại hình theo trang bị, HUD ô trang bị, art từ các pack mới

Yêu cầu của owner (2026-11-09): dùng art free mới tải để thay phần còn thiếu, cải thiện hình nhân vật, đổi các ô hai bên viền thành ô trang bị (8 ô), mặc đồ thì đổi ngoại hình, bấm chân dung thì hiện túi đồ / tự động đánh / tự động đào.
Branch `feature/appearance-hud` (tách từ `feature/phase-e-bosses`).

## Giấy phép các pack mới (đã đọc file giấy phép trong từng zip)
| Pack | Kết luận | Dùng |
|---|---|---|
| THE PACK (pixel_ankousse) | Dùng tự do, cả thương mại, được sửa, credit không bắt buộc | Có: quái Tree |
| Gridwright Jam Pack | Dùng cả thương mại, được sửa; cấm bán lại hoặc phân phối lại dưới dạng asset, cấm AI/NFT | Có: Slime King, Sparrow, 12 icon |
| N3XUS Starter | Dùng thương mại, **bắt buộc credit**, **cấm đưa lên repo công khai**, cấm AI/NFT | Chưa dùng trong đợt này (độ phân giải 32×64 lệch với nhân vật 16 px). Repo `origin` của owner đã xác nhận riêng tư (SSH truy cập được, API công khai trả 404); remote `upstream` (HauTranCong/emberfield) là **công khai** → không bao giờ được push file N3XUS lên đó |
| Void-Megapack V1 | **Không có file giấy phép** | Không dùng (owner chọn chờ giấy phép) |

## Đã làm
- **Nhân vật (CC0 Ninja Adventure)**: thay sprite tự vẽ / "soldiers" chưa xác minh.
  - Bộ đồ theo giáp đang mặc (`data/player/appearance.json`, `PlayerAppearance`):
    - không giáp: Boy;
    - Tank: GladiatorBlue → Knight → RedGladiator → KnightGold;
    - Damage: NinjaRed → NinjaFire → NinjaDark → NinjaThunder;
    - Balanced: Hunter → NinjaGreen → NinjaLeaf → NinjaMasked.
  - Vũ khí cầm tay theo vũ khí đang mặc (Sword/BigSword, Axe, Sai), xoay theo hướng và vung khi đánh. Chân dung HUD đổi theo bộ đồ.
  - Scale nguyên 2×.
- **HUD hai bên = 8 ô**:
  - Trái: Mũ, Giáp, Giày, Lưng. Phải: Vũ khí, Pet, Mount, Kỹ năng đặc biệt (khoá, chưa có hệ thống).
  - Mỗi ô hiện icon đồ với viền màu theo độ hiếm.
  - Bấm ô trang bị → panel mặc / tháo / ép đá. Bấm Pet → menu Pet. Bấm Mount → cưỡi / xuống.
  - Nút Đánh chuyển vào giữa joystick và cột phải. Hero / Làng vào menu ☰.
- **Bấm chân dung** → menu: Túi đồ, Tự động đánh (bật/tắt), Tự động đào ô đất (bật/tắt).
  - Tự động đào là chế độ mới: đi tới ô đất chưa đào gần nhất (trong 420 px) và đứng lên để đào.
  - Bật cả hai thì ưu tiên đánh quái. Di chuyển tay thì tắt cả hai.
- **Thay phần còn thiếu**:
  - Ash Crow → Sparrow (Gridwright) nhuộm xám tro.
  - Rootfang → Tree (THE PACK).
  - Slime Monarch → Slime King (Gridwright Pixel Bosses).
- **Icon**:
  - Mũ, giáp, kiếm, rìu, dao găm, ba lô, ống tên → Gridwright.
  - 11 loại đá → 8 icon đá quý (Gridwright + Ninja).
  - 5 thẻ boss → các cuộn giấy (Ninja); mảnh thẻ → cuộn trống.
- `player.tscn` không còn tham chiếu `assets/soldiers` → release gate giảm từ **29 xuống 17** asset chưa xác minh.
- Công cụ provenance có thêm pack `the_pack` và `gridwright` (kèm hạn chế phân phối). Tổng cộng 79 file mới được đăng ký.

## Kiểm chứng
- `tools/run_tests.sh`: **ALL PASSED** (runF3), thêm suite `AppearanceTests`: dữ liệu bộ đồ, ánh xạ giáp/vũ khí, mặc/tháo đổi ngoại hình và chân dung, tự động đào đi tới ô đất, icon từ pack có giấy phép.
- Render (`docs/reports/art/appearance_*.png`): HUD 8 ô, menu chân dung, panel đổi giáp, 13 bộ đồ.

## Chưa làm / rủi ro
- Mũ, giày, lưng chưa có lớp hình riêng trên nhân vật: các pack free không có bộ nhân vật nhiều lớp góc top-down. Hiện chỉ giáp (cả bộ) và vũ khí đổi hình.
- Icon giày và áo choàng vẫn là icon cũ (`NEEDS_ASSET`).
- Thỏ, rùa, hươu, sói, tê giác, đại bàng, gấu, chó săn vẫn dùng sprite tạm: chưa pack nào có.
- Người chơi khác khi chơi LAN chưa thấy ngoại hình mới của nhau (avatar từ xa vẫn dùng hình cũ).
- Vũ khí cầm tay khá to so với thân (sprite 6×17 ở scale 2×).
- Đổi `origin` sang `git@github.com:Thanh-xyz/Treasure-hunter-survival.git` bị chặn quyền trong phiên này; owner tự chạy `git remote set-url origin git@github.com:Thanh-xyz/Treasure-hunter-survival.git`.
