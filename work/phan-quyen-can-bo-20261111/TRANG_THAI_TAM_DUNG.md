# Đã hoàn tất khôi phục và phân quyền – 12/11/2026

Người dùng đã tiếp tục từ trạng thái tạm dừng, sau đó yêu cầu đưa dữ liệu nghiệp vụ về đúng bộ mẫu; giữ ADMIN, canbo01 và phân quyền. Phần việc này đã hoàn tất.

## Dự án và giới hạn

- Thư mục chính: E:\CSDL\he_thong_quan_ly_dang_ky_khai_tu.
- Bản - Copy là bản sao lưu của người dùng, không sửa hay xóa.
- Chỉ local: http://localhost:3001, Docker project khai-tu-bang-moi-local, CSDL quan_li_khai_tu. App chỉ công bố 127.0.0.1:3001; MySQL không công bố cổng host.
- Không đăng GitHub/publish/tunnel. CSDL và volume của bản cũ được giữ nguyên.

## Đã khôi phục mã nguồn

Đầu lượt 12/11, 83 file còn khớp snapshot. Trong lượt làm, thư mục chính bất ngờ chỉ còn database/work; người dùng xác nhận không chủ động chuyển và yêu cầu khôi phục. Chưa xác định nguyên nhân mất file.

Đã chép bổ sung 171 file từ bản - Copy, không ghi vào bản sao lưu. Bản sao lưu cũ hơn thay đổi phân quyền, nên đã lấy lại backend/public mới nhất từ container app đang chạy. Đối chiếu đủ 62 file bằng SHA256: khớp bản đang chạy trước khi khôi phục.

Đã khôi phục database/cap_nhat_lien_ket_can_bo.sql từ container DB, bổ sung lại MaCanBo + FK/UNIQUE/CHECK trong database/app_setup.sql cho cài mới; cập nhật lại bộ kiểm thử auth và 3 hướng dẫn chính. Không thay đổi logic backend/public so với bản đã chạy ngày 11/11.

## CSDL hiện tại sau khi đưa về mẫu

Nguồn chuẩn: work/truoc-khi-dung-bang-moi-20261110/nguon-nguoi-dung/du_lieu_mau.sql.

- Nguyen_Nhan: 6; CSYT: 4; Noi_Mat: 8; UBND: 3; Can_Bo: 6.
- Cong_Dan: 200; Giay_Bao_Tu: 100; Ho_So_Khai_Tu: 100; An_Tang: 64.
- Tổng 491 bản ghi nghiệp vụ. Đã so toàn bộ giá trị trong 9 bảng với nguồn, không chỉ đếm dòng; đều khớp.
- Đã bỏ dữ liệu thử: trước khôi phục có 202 công dân, 101 giấy báo tử, 101 hồ sơ; HS002 từ Chờ xử lý đã về Đã duyệt theo bộ mẫu.
- Có sao lưu đầy đủ trước khi thay dữ liệu: work/khoi-phuc-du-lieu-mau-20261112/csdl-truoc-khoi-phuc.sql.
- Khôi phục trong một transaction, không đổi cấu trúc bảng, không tắt FK. App tạm dừng trong lúc thực hiện rồi đã mở lại.
- App_User giữ nguyên cả 2 dòng ADMIN/cán bộ, bao gồm mật khẩu, vai trò và liên kết. Đã kiểm tra trước/sau trong cùng transaction và xác nhận thêm digest mật khẩu ADMIN không đổi.

## Tài khoản và phân quyền

- canbo01 liên kết CB01 – Vũ Đức Bình, UBND Phường Láng Hạ.
- Mật khẩu tạm được gửi trong chat, không lưu rõ vào mã nguồn/MD/SQL mẫu. Không tự đổi mật khẩu ADMIN hay tạo lại canbo01 khi tiếp tục.
- Đăng nhập thật thành công sau khôi phục. Cán bộ chỉ thấy 17 hồ sơ CB01: 3 Chờ xử lý, 14 Đã duyệt.
- Backend đọc lại App_User.MaCanBo và Can_Bo trên mỗi yêu cầu; không tin mã cán bộ trong token/query/body.
- Danh sách, CCCD, trạng thái, tạo hồ sơ, dashboard và 5 báo cáo giới hạn theo cán bộ tiếp nhận. Hồ sơ người khác bị 404; quản lý tài khoản bị 403. ADMIN xem toàn bộ.
- Tạo tài khoản/mã mời phải gắn cán bộ hợp lệ, không trùng. UI cán bộ khóa người tiếp nhận là chính mình.
- Giữ bản sửa đổi phiên: xóa dữ liệu cũ, hủy request cũ, kiểm tra generation, no-store, reload login/logout/bfcache và khóa CSV khi tải lỗi.

## Đã kiểm tra lại ngày 12/11

- 72 kiểm thử mã đạt sau khi khôi phục bộ kiểm thử auth.
- 63 kiểm tra SQL/cài mới/HTTP trong Docker tạm đạt; các container thử đã xóa.
- 7 kiểm tra khôi phục mẫu trong Docker tạm đạt: có thử rollback lỗi, bỏ bản ghi thử, khôi phục HS002, giữ tài khoản và chạy lại an toàn.
- 17 kiểm tra API trực tiếp trên app đang dùng đạt sau reset: đăng nhập, đúng phạm vi, đủ báo cáo, chặn truy cập khác quyền, giữ ADMIN và đăng xuất.
- Trình duyệt local đăng nhập canbo01 thật, hiển thị 17 hồ sơ, không có mục quản trị. Đã bấm Đăng xuất và xác nhận trở về trang đăng nhập.
- Ảnh xác nhận: work/khoi-phuc-du-lieu-mau-20261112/canbo01-da-khoi-phuc.png.
- Các JSON kết quả và script thao tác nằm trong work/khoi-phuc-du-lieu-mau-20261112/.

## Tài liệu và sao lưu

Giữ 3 hướng dẫn chính tại gốc: README.md, HUONG_DAN_KHOI_TAO_CSDL_MOI.md, HUONG_DAN_TRUY_VAN_BACKEND.md. Không ghi mật khẩu vào tài liệu.

Sau khi lưu file này sẽ tạo ma-nguon-hoan-tat-20261112.zip và manifest SHA256 trong work/khoi-phuc-du-lieu-mau-20261112/. Có bản mã nguồn thứ hai tại C:\Users\ADMIN\Documents\Codex\khoi-phuc-khai-tu-20261112\ nếu bước sao lưu cuối hoàn tất. Kiểm tra tồn tại trước khi sử dụng.

## Những giới hạn cũ vẫn để xem lại, không thuộc thao tác khôi phục này

- Nhập CCCD đã có: backend giữ thông tin công dân cũ; cần kiểm tra thêm xung đột thông tin/ngày sinh dựa trên dữ liệu đang lưu.
- CSDL chưa bảo vệ đủ sinh≤mất và an táng≥mất trên mọi đường sửa trực tiếp.
- Noi_Mat chưa có cột tỉnh/loại đơn vị để lọc Hà Nội thật; nhãn dựa vào danh mục mẫu.
- Ca mất tại CSYT là ước tính LIKE tên/địa chỉ trong NoiMatChiTiet, đã có trong SQL nguồn.
- SQL nhóm tuổi dùng SQL + JavaScript, có khác biệt dữ liệu biên so với WITH/RANK nguồn. Mỗi báo cáo dùng tập bản ghi khác nhau theo nguồn.

Nếu tiếp tục: đọc file này và kiểm tra thực tế. Không nạp lại mẫu, chạy lại script reset, xóa volume hay tạo lại tài khoản khi chưa có yêu cầu mới. Dữ liệu giả không đồng nghĩa bản GitHub đã an toàn: work/backup, dump App_User, file bí mật và cấu hình khóa/mật khẩu cần được loại hoặc tách khỏi bản công khai.
