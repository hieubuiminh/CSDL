# Đối chiếu báo cáo và bản SQL hiệu chỉnh — 09/11/2026

Nguồn: `C:/Users/ADMIN/Downloads/bao-cao-updated_removed.pdf`, 25 trang PDF; số trang in trong tài liệu lớn hơn thứ tự trang PDF 3 trang. Các quyết định dưới đây dựa trên phạm vi bài tập, không phải khẳng định đã đáp ứng toàn bộ thủ tục hộ tịch thực tế.

## Các file dùng để làm gì?

| File | Mục đích |
|---|---|
| `database/he_thong_quan_ly_dang_ky_khai_tu.sql` | Khởi tạo **CSDL mới** gồm 9 bảng và các trigger. Không chạy lại trên CSDL đã có. |
| `database/app_setup.sql` | Tạo bảng tài khoản ứng dụng `App_User`, vai trò `admin`/`staff`. **Giữ file này**, không còn ALTER UNIQUE trùng với schema chính. |
| `database/cap_nhat_rang_buoc.sql` | Nâng cấp CSDL cũ; kiểm tra dữ liệu trước khi đổi cấu trúc. Chỉ chạy thủ công sau khi sao lưu. |
| `database/truy_van_bao_cao.sql` | Bảy truy vấn chỉ đọc theo mục 3.4, có chú thích các hiệu chỉnh. |
| `work/sql-before-report/` | Bản sao các file SQL trước lần sửa này; đây là bản sao mã nguồn, **không phải bản sao dữ liệu MySQL**. |

Việc sửa các file này không tự cập nhật volume MySQL đang chạy. Khởi động backend không tự chạy migration. Hướng dẫn áp dụng riêng: `docs/CAP_NHAT_RANG_BUOC_DOCKER.md`.

## Những thay đổi đã đưa vào SQL

- Kiểu dữ liệu và độ dài theo bảng 2.1–2.9: CCCD 12 ký tự; mã danh mục 20; số giấy/hồ sơ 30; điện thoại tối đa 15 và có thể trống; mô tả nguyên nhân `TEXT` có thể trống. Tất cả khóa ngoại được đổi kiểu đồng bộ.
- CCCD công dân và cán bộ phải đủ 12 chữ số ASCII; `CHAR(12)` riêng lẻ chưa bảo đảm điều này. Giới tính là `Nam`, `Nữ`, `Khác`.
- Giữ khóa ngoại `Can_Bo.MaUBND` như sơ đồ, sửa lỗi cú pháp của đoạn DDL trong báo cáo.
- UNIQUE trên người mất, giấy báo tử gắn hồ sơ, CCCD cán bộ và hồ sơ gắn an táng. Một hồ sơ có thể chưa có thông tin an táng, nhưng không có hai bản ghi an táng cùng hồ sơ.
- CHECK người khai khác người mất; CHECK ngày mất ≤ ngày cấp giấy báo tử. So sánh phần **ngày**, vì ngày cấp và ngày đăng ký không lưu giờ.
- Trigger kiểm tra ngày cấp ≤ ngày đăng ký khi **thêm/sửa hồ sơ**, và cả khi **sửa giấy báo tử đã liên kết**. Có khóa hàng để tránh đọc ảnh dữ liệu cũ khi ghi đồng thời.
- Trigger đánh dấu công dân `Đã mất` khi thêm/sửa hồ sơ có trạng thái **khác `Từ chối`**, theo mục 1.4.2. Không tự suy ra công dân còn sống khi từ chối, xóa hoặc đổi người mất của hồ sơ.
- Bộ trạng thái hồ sơ thống nhất: `Chờ xử lý`, `Đã duyệt`, `Từ chối`; mặc định `Đã duyệt` theo bảng 2.8. Trạng thái sinh tử: `Còn sống`, `Đã mất`; mặc định `Còn sống`. Thêm NOT NULL cho trạng thái để không lọt qua điều kiện với NULL.
- `UBND.CapHanhChinh` giữ NOT NULL như SQL gốc và biểu mẫu hiện tại, với mặc định `Phường`; đây là điểm chặt hơn đoạn DDL nullable trong báo cáo.

Kết quả kiểm thử hoàn tất ngày 10/11/2026: xem `docs/KIEM_THU_SQL_BAO_CAO.md`. CSDL thật chưa được áp dụng migration.

## Chỗ báo cáo chưa thống nhất và cách xử lý

| Vị trí trong báo cáo | Vấn đề | Bản hiệu chỉnh |
|---|---|---|
| Mục 1.4.1, DDL 3.2 so với lược đồ 2.2 và bảng 2.9 | `An_Tang.MaNguyenNhan` xuất hiện không nhất quán. | Không thêm cột lặp: nguyên nhân lấy qua `An_Tang → Ho_So_Khai_Tu → Giay_Bao_Tu → Nguyen_Nhan`. Tránh hai nơi lưu hai nguyên nhân khác nhau. |
| Bảng 2.9 và ứng dụng hiện tại | Báo cáo dùng `TenNghiaTrang_DaiHoaThan`, không có `NgayAnTang`. | Giữ tên cột `TenNghiaTrang`, mở rộng 150 ký tự và bao gồm đài hóa thân; giữ `NgayAnTang` là phần bổ sung của ứng dụng. |
| Mục 1.3 so với bảng 2.8 | `Chờ duyệt` và `Chờ xử lý` khác nhau. | Dùng `Chờ xử lý`. Migration ánh xạ `Chờ duyệt`, `Đã tiếp nhận`, `Đang xử lý` sang `Chờ xử lý`; `Đã hoàn tất` sang `Đã duyệt`; `Đang sống` sang `Còn sống`. Giá trị lạ phải kiểm tra riêng. |
| Mục 1.4.2 so với phần trigger 3.3 | Yêu cầu cả INSERT/UPDATE nhưng ví dụ chỉ viết INSERT. | Bảo vệ cả INSERT, UPDATE hồ sơ và UPDATE giấy báo tử. |
| DDL `Can_Bo`, PDF trang 17 / trang in 20 | Dấu phẩy dư, thiếu FK `MaUBND`. | DDL chạy được, có FK theo thiết kế. |
| Truy vấn 3.4.5 | Không loại hồ sơ từ chối như thống kê địa bàn. | Loại `Từ chối`; giữ đủ 3 nhóm tuổi, lấy đủ nguyên nhân đồng hạng. Ngày sinh sau ngày mất bị loại khỏi thống kê tuổi, cần kiểm tra dữ liệu riêng. |
| Truy vấn 3.4.7 | Đếm mọi giấy báo tử, có thể gồm giấy chưa gắn hồ sơ. | Đếm công dân có hồ sơ không bị từ chối, phân theo năm mất; không gọi số giấy là số người đã đăng ký. |

Mục 1.1 nói “được duyệt”, còn mục 1.4.2 và trigger ví dụ nói “không bị từ chối”. Bản này ưu tiên quy tắc cụ thể **không bị từ chối**; vì vậy cả hồ sơ `Chờ xử lý` cũng đánh dấu `Đã mất`. Nếu nhóm muốn chỉ đánh dấu sau khi duyệt thì phải đổi đồng bộ mục 1.4.2, trigger và backend.

UNIQUE người mất vẫn áp dụng cho cả hồ sơ từ chối, đúng quy tắc “mỗi công dân một hồ sơ” của báo cáo. Cách xử lý nộp lại trong mô hình này là cập nhật/mở lại hồ sơ hiện có; không tạo hồ sơ thứ hai.

## Phạm vi và giới hạn của bảy truy vấn

- Truy vấn giới tính theo báo cáo lấy công dân có trạng thái `Đã mất`, kể cả công dân chưa có hồ sơ. Báo cáo tuổi/năm lấy hồ sơ không bị từ chối. Hai nguồn này có thể cho tổng khác nhau; không phải tự động coi đó là lỗi dữ liệu.
- Địa bàn trong SQL giả định toàn bộ `Noi_Mat` là Xã/Phường của Hà Nội như phạm vi báo cáo, giữ cả địa bàn 0 ca. Cấu trúc hiện tại **chưa có tỉnh/thành hay loại đơn vị**; không thể tự chứng minh một mã là xã thuộc Hà Nội. Ứng dụng vẫn dùng dữ liệu phân loại riêng và báo cáo chỉ Xã thuộc Hà Nội theo yêu cầu trước đó.
- Cơ sở y tế tính quý lịch hoàn chỉnh liền trước theo múi giờ Việt Nam và lấy **trên 50** giấy, không gồm đúng 50. Số/tỷ lệ mất tại CSYT chỉ là **ước tính từ chuỗi tên/địa chỉ**, đã ghi rõ trong tên cột. CSYT cấp giấy không mặc nhiên là nơi mất.
- File truy vấn SQL không tự thay toàn bộ cách tính của API web. Các khác biệt về nguồn đếm giới tính, phạm vi Xã/Phường và tỷ lệ tại CSYT được ghi rõ tại đây để nhóm chọn khi cập nhật báo cáo/giao diện.

## Những bổ sung nên cân nhắc nếu dùng thực tế

1. **Địa bàn có cấu trúc:** tỉnh/thành, loại Xã/Phường và mã hành chính; cần dữ liệu phân loại đáng tin cậy, không suy từ tên. Đây là điều kiện để truy vấn Hà Nội có thể lọc chính xác trong SQL.
2. **Nơi mất tại CSYT:** lưu trường riêng cho biết có mất tại chính đơn vị cấp giấy không; cho phép chưa xác định. Khi có dữ liệu này mới thay phép dò chuỗi bằng số liệu chính xác.
3. **Lưu UBND tại thời điểm tiếp nhận:** hiện tra qua cán bộ đang làm việc ở đâu; chuyển công tác có thể làm báo cáo hồ sơ cũ đổi đơn vị. Cần lưu trực tiếp đơn vị tiếp nhận trên hồ sơ khi mở rộng mô hình.
4. **Lịch sử xử lý/đính chính:** ai sửa, lúc nào, lý do từ chối/đính chính; quy trình hủy hoặc mở lại hồ sơ. Tránh xóa vĩnh viễn dữ liệu hộ tịch trong hệ thống dùng thật.
5. **Ngày sinh và ngày an táng:** cần bảo đảm ngày sinh ≤ ngày mất và ngày an táng ≥ ngày mất cả khi sửa công dân, giấy báo tử hoặc an táng. Backend hiện kiểm tra lúc tạo; SQL lần này chưa bổ sung hệ trigger liên bảng cho hai quy tắc ngoài mục 1.4.2.

Các mục trên là đề xuất ngoài cấu trúc 9 bảng của báo cáo, chưa tự thêm cột hoặc suy diễn dữ liệu cũ.

## Tham chiếu kỹ thuật

- MySQL chỉ thực thi CHECK từ 8.0.16: [CHECK constraints](https://dev.mysql.com/blog-archive/mysql-8-0-16-introducing-check-constraint/).
- [SELECT và khóa FOR SHARE/FOR UPDATE](https://dev.mysql.com/doc/refman/8.0/en/select.html), [trigger](https://dev.mysql.com/doc/refman/8.0/en/trigger-syntax.html).
- Script khởi tạo của image MySQL chỉ chạy với thư mục dữ liệu mới: [MySQL Official Image](https://hub.docker.com/_/mysql). Không xóa volume đang dùng để ép chạy lại.
