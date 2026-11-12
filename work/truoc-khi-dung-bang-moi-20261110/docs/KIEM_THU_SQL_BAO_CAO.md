# Kết quả kiểm thử SQL theo báo cáo

Hoàn tất kiểm tra lại ngày 10/11/2026. Kiểm thử dùng dữ liệu giả trên MySQL **8.0.46** riêng, không truy vấn hoặc áp dụng migration lên CSDL thật của chủ dự án.

| Phần kiểm tra | Kết quả |
|---|---|
| Khởi tạo schema mới, bảng tài khoản, ràng buộc và chạy bảy truy vấn | 34/34 đạt |
| Nâng cấp schema gốc, so sánh cấu trúc, nâng dữ liệu có sẵn, chạy lại file và chặn dữ liệu sai | 54/54 đạt |
| Kiểm thử backend/giao diện bằng Node trong lần chạy 09/11 | 44/44 đạt |
| Kiểm tra cú pháp JavaScript trong lần chạy 09/11 | 51 file đạt |
| Kiểm tra giao diện bằng dữ liệu giả, desktop và mobile ngày 09/11 | Đạt; không lỗi JavaScript/console, biểu mẫu và payload hợp lệ |

## Những hành vi đã kiểm tra

- Chặn người khai trùng người mất; chặn thứ tự ngày sai khi thêm/sửa hồ sơ và khi sửa giấy báo tử đã liên kết.
- Chặn trùng người mất, trùng giấy báo tử gắn hồ sơ, trùng CCCD cán bộ và trùng hồ sơ gắn an táng.
- CCCD đủ 12 chữ số; giới tính/trạng thái hợp lệ; giới hạn độ dài và các trường được phép để trống.
- Hồ sơ không bị từ chối đánh dấu công dân `Đã mất`; hồ sơ bị từ chối không tự đánh dấu mất. Từ chối hồ sơ đã duyệt không tự chuyển công dân về còn sống.
- Cột mô tả nguyên nhân sau nâng cấp nhận được 2.000 ký tự và có đúng kiểu `TEXT`; đã sửa lỗi MySQL chuyển thành `TINYTEXT` trong phiên bản thử trước.
- Kiểu dữ liệu, khả năng NULL và mặc định các cột sau nâng cấp khớp schema khởi tạo mới.
- Nâng cấp dữ liệu giả có sẵn giữ số bản ghi công dân/giấy báo tử/hồ sơ/an táng là **5/4/4/1**; giữ thông tin và ngày an táng; đổi đúng các nhãn trạng thái cũ. Không tự sửa backlog sinh tử.
- File nâng cấp chạy lại thành công cả trên schema trống và dữ liệu đã có.
- CCCD cũ không hợp lệ hoặc mã địa bàn quá dài khiến preflight dừng; độ dài cột cũ và trigger kiểm chứng vẫn giữ nguyên.

Hai file kết quả chi tiết: `work/pdf-review/sql-test-fresh-final.json` và `work/pdf-review/sql-test-upgrade-final.json`. File nâng cấp và truy vấn được ghi nhận SHA-256 trong kết quả kiểm thử nâng cấp để đối chiếu đúng phiên bản.

## Phạm vi kiểm thử

Các truy vấn báo cáo đã được thực thi trên schema thật trong môi trường thử; chưa đối chiếu toàn bộ số liệu thống kê với dữ liệu thật của chủ dự án. Quy tắc nguồn đếm, phạm vi địa bàn và tỷ lệ ước tính tại CSYT được giải thích trong `docs/DOI_CHIEU_BAO_CAO_SQL.md`.

Container thử không có mạng, cổng công bố hoặc volume của ứng dụng; dữ liệu nằm trên tmpfs dùng tạm. Các container này đã được xóa sau khi hoàn tất. Việc sửa SQL nguồn hoặc kiểm thử không tự cập nhật volume MySQL của ứng dụng.

Không dựng lại image ứng dụng, không nạp migration vào CSDL thật và không xuất bản ứng dụng trong lần xử lý này. Chủ dự án cập nhật theo `docs/CAP_NHAT_RANG_BUOC_DOCKER.md` khi sẵn sàng.
