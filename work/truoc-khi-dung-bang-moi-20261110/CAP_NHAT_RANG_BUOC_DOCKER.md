# Bổ sung ràng buộc cho CSDL Docker đang có

File [cap_nhat_rang_buoc.sql](database/cap_nhat_rang_buoc.sql) là bản nâng cấp CSDL đang có, được hiệu chỉnh theo báo cáo ngày 09/11/2026. Các file SQL nguồn đã sửa; **chưa chạy nâng cấp trên CSDL Docker đang dùng**. Máy chủ không tự chạy file này khi khởi động. Chi tiết thay đổi và các điểm báo cáo chưa thống nhất nằm trong [bản đối chiếu](DOI_CHIEU_BAO_CAO_SQL.md).

File yêu cầu MySQL **từ 8.0.16** và CSDL `quan_ly_dang_ky_khai_tu`. Nó kiểm tra dữ liệu trước, đổi kiểu/độ dài cột theo báo cáo, chuẩn hóa các tên trạng thái cũ đã biết, bổ sung CHECK/UNIQUE/khóa ngoại và cài 5 trigger bảo vệ cả thêm lẫn sửa. Ngày mất được so sánh theo **ngày**, vì ngày cấp và ngày đăng ký không lưu giờ. Công dân chỉ được đánh dấu “Đã mất” khi tạo/sửa hồ sơ **không bị từ chối**. Không tự chuyển ngược về “Còn sống”.

Đã kiểm thử trên MySQL 8.0.46 trong container riêng bằng dữ liệu giả, gồm nâng cấp dữ liệu có sẵn, chạy lại file và từ chối dữ liệu sai trước khi thay đổi. Xem [kết quả kiểm thử](docs/KIEM_THU_SQL_BAO_CAO.md). Chưa chạy trên dữ liệu thật của bạn.

Chạy PowerShell tại `E:\CSDL\he_thong_quan_ly_dang_ky_khai_tu`. Thực hiện từng bước; nếu có lỗi thì dừng. Cần tài khoản quản trị MySQL. DDL tự commit, không thể dùng một lệnh rollback để hoàn tác cả file.

**1. Tạm dừng ứng dụng, giữ dịch vụ CSDL hoạt động và chép file vào container.**

```powershell
docker compose -f docker/compose.yaml stop app
docker compose -f docker/compose.yaml cp database/cap_nhat_rang_buoc.sql db:/tmp/cap_nhat_rang_buoc.sql
docker compose -f docker/compose.yaml exec db sh
```

**2. Trong shell của container, tạo bản sao lưu rồi thoát.** Mật khẩu được lấy từ biến môi trường sẵn có, không gõ mật khẩu trực tiếp vào lệnh.

```sh
export MYSQL_PWD="$MYSQL_ROOT_PASSWORD"
if ! mysqldump -uroot --single-transaction --routines --triggers --events --databases "$MYSQL_DATABASE" > /tmp/khai_tu_truoc_cap_nhat.sql; then
  echo "SAO LUU THAT BAI - dung, khong chay cap nhat." >&2
  exit 1
fi
if [ ! -s /tmp/khai_tu_truoc_cap_nhat.sql ]; then
  echo "FILE SAO LUU RONG - dung, khong chay cap nhat." >&2
  exit 1
fi
echo "Sao luu thanh cong. Chep ban sao luu ra may o buoc tiep theo."
unset MYSQL_PWD
exit
```

Chỉ tiếp tục khi sao lưu thành công. Tại PowerShell, chép bản sao lưu ra máy trước khi cập nhật:

```powershell
New-Item -ItemType Directory -Path work -Force | Out-Null
docker compose -f docker/compose.yaml cp db:/tmp/khai_tu_truoc_cap_nhat.sql "./work/khai_tu_truoc_cap_nhat_$(Get-Date -Format yyyyMMdd_HHmmss).sql"
docker compose -f docker/compose.yaml exec db sh
```

**3. Trong shell của container, áp dụng file vào CSDL cấu hình trong `MYSQL_DATABASE`.** Chạy theo chế độ batch dưới đây; không thêm `--force` và không dùng `SOURCE` trong cửa sổ mysql tương tác.

```sh
export MYSQL_PWD="$MYSQL_ROOT_PASSWORD"
if ! mysql -uroot --default-character-set=utf8mb4 --show-warnings "$MYSQL_DATABASE" < /tmp/cap_nhat_rang_buoc.sql; then
  echo "CAP NHAT THAT BAI - giu ung dung tam dung de kiem tra." >&2
  exit 1
fi
unset MYSQL_PWD
exit
```

Nếu xuất hiện `ERROR`, dừng và giữ ứng dụng tạm dừng để kiểm tra. File từ chối dữ liệu sai ràng buộc, trùng khóa, CCCD/giới tính/trạng thái không hợp lệ hoặc chuỗi dài hơn giới hạn mới. Nó không tự cắt chuỗi, xóa hoặc gộp hồ sơ. Chỉ ánh xạ các trạng thái cũ đã ghi rõ trong bản đối chiếu; giá trị lạ phải kiểm tra riêng. Có thể chạy lại sau khi xử lý nguyên nhân; chỉ các trigger mang tiền tố `KT_Update_` của file được thay thế.

File này dành cho 9 bảng gốc của dự án và bản cập nhật đã cung cấp. Nếu đã thêm khóa ngoại từ bảng khác hoặc CHECK/trigger tùy biến, file sẽ dừng để kiểm tra riêng, giữ nguyên các phần tùy biến đó. Không bỏ các bước kiểm tra hoặc thêm `--force` để vượt lỗi.

**4. Khi cập nhật thành công**, xem kết quả cuối về công dân đã có hồ sơ không bị từ chối nhưng chưa mang trạng thái “Đã mất”. Đây là dữ liệu cũ cần xem xét riêng; file không tự đồng bộ ngược toàn bộ dữ liệu sinh tử. Trigger mới áp dụng cho các lần tạo/sửa hồ sơ sau đó.

Tại PowerShell, dựng và cập nhật ứng dụng để dùng giao diện/kiểm tra đầu vào cùng phiên bản SQL:

```powershell
docker compose -f docker/compose.yaml build app
docker compose -f docker/compose.yaml up -d --no-deps app
```

Không cần chạy lại schema chính hoặc xóa `app_setup.sql`. Giữ bản sao lưu trong `work` để phục hồi khi cần. Không chạy `docker compose down -v`, vì tùy chọn đó xóa dữ liệu trong volume.

MySQL kiểm tra dữ liệu đang có khi thêm CHECK; dòng vi phạm khiến lệnh báo lỗi. Tham khảo [ALTER TABLE](https://dev.mysql.com/doc/refman/8.0/en/alter-table.html), [cú pháp trigger](https://dev.mysql.com/doc/refman/8.0/en/trigger-syntax.html). Docker chỉ khởi tạo từ SQL khi thư mục dữ liệu còn mới: [MySQL Official Image](https://hub.docker.com/_/mysql).

