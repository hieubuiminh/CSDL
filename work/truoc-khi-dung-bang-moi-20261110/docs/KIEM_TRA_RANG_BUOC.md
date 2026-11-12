# Kiểm tra các ràng buộc khai tử

> Đây là kết quả kiểm tra **trước** lần hiệu chỉnh SQL theo PDF ngày 09/11/2026. Mô tả “SQL gốc” bên dưới áp dụng cho bản sao trong `work/sql-before-report/`. Tình trạng mã nguồn hiện tại xem `docs/DOI_CHIEU_BAO_CAO_SQL.md`; chưa kiểm tra dữ liệu thật trong Docker.

Đối chiếu file gốc `database/he_thong_quan_ly_dang_ky_khai_tu.sql`, file bổ sung `database/app_setup.sql` và backend hiện tại. Không sửa hai file SQL, cấu trúc bảng hoặc dữ liệu.

| Yêu cầu | SQL gốc | Ứng dụng hiện tại |
|---|---|---|
| Người đi khai tử khác người mất | Có `CHECK (CCCD_NgKhaiTu <> CCCD_NgMat)` trong `Ho_So_Khai_Tu`. | Backend cũng kiểm tra trước khi lưu. |
| Ngày mất ≤ ngày cấp giấy báo tử ≤ ngày đăng ký | Chỉ khai báo kiểu ngày và `NOT NULL`, chưa có ràng buộc kiểm tra thứ tự ngày. | Backend kiểm tra ngày hợp lệ và thứ tự trước khi tạo hồ sơ. So sánh phần ngày của ngày giờ mất để cho phép cấp giấy trong cùng ngày mất. |
| Mỗi công dân chỉ có một hồ sơ khai tử | Chưa có `UNIQUE` trên `CCCD_NgMat`. Khóa chính `SoGiayKhaiTu` chỉ ngăn trùng số hồ sơ. | File bổ sung `app_setup.sql` có `UNIQUE (CCCD_NgMat)`. Backend hiện dựa vào ràng buộc bổ sung này, nên cần ràng buộc đó đã được nạp thành công trong CSDL đang chạy. |
| Tạo hồ sơ thành công thì công dân chuyển thành “Đã mất” | Chưa có trigger hoặc procedure thực hiện tự động. `Cong_Dan.TrangThai` chỉ là cột chuỗi bắt buộc. | Backend cập nhật trạng thái trong cùng giao dịch tạo hồ sơ, rồi mới commit. Nếu lỗi thì rollback. |

**Kết luận:** cấu trúc SQL gốc mới tự bảo đảm yêu cầu người khai khác người mất; các yêu cầu còn lại chưa được bảo đảm đầy đủ tại tầng CSDL gốc. Backend xử lý thứ tự ngày và cập nhật trạng thái; quy định mỗi người một hồ sơ cần ràng buộc bổ sung đã có trong `app_setup.sql`.

File SQL gốc chỉ chứa lệnh tạo bảng, không có dữ liệu mẫu. Vì vậy chỉ từ file này không thể kết luận CSDL đang chạy có bản ghi vi phạm hay không. Chưa thực hiện truy vấn kiểm tra dữ liệu thật trong lượt kiểm tra này.

## Kiểm tra dữ liệu đang có mà không sửa CSDL

Mở `docs/kiem_tra_rang_buoc_chi_doc.sql` trong công cụ MySQL đang dùng và chạy trên CSDL hiện tại. File chỉ đổi CSDL đang chọn và đọc dữ liệu bằng `SELECT`, không thêm/sửa/xóa bản ghi hoặc thay cấu trúc bảng. Kết quả chỉ gồm số lượng và thông tin ràng buộc, không xuất tên hoặc CCCD.

- Các cột số vi phạm bằng 0: chưa phát hiện dữ liệu vi phạm tại thời điểm kiểm tra.
- Cột nào lớn hơn 0: có dữ liệu cần kiểm tra theo quy tắc tương ứng.
- `TongHoSo` bằng 0: chưa có hồ sơ để kiểm tra; số vi phạm bằng 0 không chứng minh các ràng buộc đã được thiết lập đầy đủ.

Phần danh sách ràng buộc giúp kiểm tra `UQ_HoSo_NguoiMat` đã thực sự tồn tại hay chưa. File kiểm tra không tự nạp `app_setup.sql`.
