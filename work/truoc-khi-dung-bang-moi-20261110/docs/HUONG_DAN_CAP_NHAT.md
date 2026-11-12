# Hướng dẫn dùng bản cập nhật

## Bảo toàn CSDL

Bản ngày 09/11/2026 sửa SQL theo báo cáo, đồng thời đồng bộ backend và giao diện. File nguồn đã thay đổi nhưng CSDL Docker đang có không tự thay đổi. Máy chủ không tự chạy migration khi khởi động.

**Nếu đang có dữ liệu:** làm theo [hướng dẫn sao lưu và nâng cấp CSDL](CAP_NHAT_RANG_BUOC_DOCKER.md) trước khi dựng lại ứng dụng. Không nạp lại schema chính trên CSDL đã có, không xóa volume. Các tên trạng thái và giới hạn độ dài mới được ghi trong [bản đối chiếu](DOI_CHIEU_BAO_CAO_SQL.md).

## Cập nhật ứng dụng Docker đang có

Mở Docker Desktop, mở PowerShell tại thư mục dự án:

```powershell
docker compose -f docker/compose.yaml build app
docker compose -f docker/compose.yaml up -d --no-deps app
```

Hai lệnh dựng và khởi động lại ứng dụng, dùng tiếp CSDL đã nâng cấp ở bước trên. Nếu DB đang dừng, mở nó bằng `docker compose -f docker/compose.yaml start db` trước. Sau đó vào http://localhost:3000 và làm mới trang. Hai lệnh này tự chúng không nâng cấp MySQL.

Image `docker/app-image.tar` cũ không tự có mã mới. Sau khi build, nếu muốn gửi image mới cho thành viên, chạy `docker save --output docker/app-image.tar khai-tu-app:1.0`. Không nạp lại image cũ sau khi đã build bản mới.

## Sử dụng

1. ADMIN đăng nhập tài khoản đang có; vào **Quản lý tài khoản** để tạo ADMIN/Cán bộ, đổi quyền các tài khoản khác hoặc cấp mã mời cán bộ.
2. **Hồ sơ khai tử** liệt kê toàn bộ hồ sơ và các trường yêu cầu, có tìm kiếm và lọc trạng thái.
3. **Tra cứu trích lục** nhận CCCD 12 số; kết quả có đầy đủ thông tin người mất, ngày giờ mất, nguyên nhân, người khai, quan hệ, UBND và nút in.
4. Mỗi báo cáo có mục riêng ở menu. Địa bàn chọn năm đăng ký; thống kê năm dùng năm mất; cơ sở y tế dùng quý lịch hoàn chỉnh liền trước.
5. ADMIN vào **Dữ liệu dùng chung → Phân loại địa bàn** để xác nhận tỉnh/thành và loại đơn vị cho danh mục cũ. Chỉ cấu hình riêng được lưu; CSDL giữ nguyên. Báo cáo Hà Nội chỉ lấy địa bàn có tỉnh/thành `Hà Nội`, loại `Xã`, gồm cả xã 0 ca.

Cán bộ được tạo/xử lý hồ sơ, tra cứu và xem báo cáo. Tài khoản, danh mục và xóa hồ sơ chỉ dành cho ADMIN. API vẫn chặn khi cán bộ tự gọi đường dẫn quản trị.

## Kiểm tra mã nguồn

Với Node.js 20 trở lên và các thư viện đã cài, chạy `npm test`. Bộ kiểm thử dùng dữ liệu giả và không kết nối CSDL thật.
