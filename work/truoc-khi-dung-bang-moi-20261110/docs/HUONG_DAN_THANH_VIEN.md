# Hướng dẫn thành viên chạy ứng dụng

Chủ dự án gửi thư mục dự án đã có image dựng sẵn. Thành viên chỉ cần Docker Desktop; không cần cài Node.js, npm, MySQL Server hay build mã nguồn.

**Lưu ý bản SQL theo báo cáo 09/11/2026:** chủ dự án phải dựng và xuất lại image ứng dụng bằng mã nguồn mới trước khi gửi cho thành viên. Việc sửa SQL không cập nhật `docker/app-image.tar` đang có. Không dùng image cũ với schema mới.

## Các file cần có để chạy

Trong thư mục dự án cần có:

- `docker/app-image.tar`: image ứng dụng do chủ dự án tạo sẵn.
- `docker/compose.yaml`: cấu hình chạy ứng dụng và MySQL.
- `database/he_thong_quan_ly_dang_ky_khai_tu.sql`: schema 9 bảng đã hiệu chỉnh theo báo cáo, dành cho CSDL mới.
- `database/app_setup.sql`: bảng tài khoản ứng dụng, vẫn cần giữ.

File `docker/Dockerfile`, `.dockerignore`, `package.json`, thư mục `backend` và `public` là mã nguồn để nhóm/cô xem hoặc chủ dự án dùng khi cập nhật và tạo image mới. `backend` chứa toàn bộ mã máy chủ; `public` chứa giao diện web hiển thị trên trình duyệt (HTML, CSS, JavaScript và hình ảnh). Thành viên không cần dùng chúng để build.

## Cập nhật bản đang dùng

Nếu đã có ứng dụng và CSDL, làm theo [hướng dẫn cập nhật](HUONG_DAN_CAP_NHAT.md): sao lưu, chạy file nâng cấp CSDL rồi cập nhật image. Không nạp lại schema chính hoặc xóa volume để khởi tạo lại. Image cũ cần dựng lại để đồng bộ kiểu dữ liệu và trạng thái mới.

## Cấu trúc mã nguồn backend

- `backend/index.js`: khởi chạy máy chủ; `backend/app.js`: cấu hình Express.
- `backend/modules/auth/index.js`: đăng nhập, đăng ký, khôi phục và đổi mật khẩu.
- `backend/modules/accounts/index.js`: tài khoản, quyền ADMIN/Cán bộ và mã mời.
- `backend/modules/catalogs/index.js`: danh mục và cấu hình địa bàn riêng.
- `backend/modules/registrations/index.js` và `dashboard/index.js`: hồ sơ và tổng quan.
- `backend/modules/reports/`: từng báo cáo có thư mục và `index.js` riêng.
- `backend/config`: kết nối cơ sở dữ liệu và cấu hình ứng dụng.
- `backend/middleware` và `backend/utils`: xác thực, xử lý lỗi và hàm dùng chung.

## 1. Cài Docker Desktop

Tải [Docker Desktop cho Windows](https://docs.docker.com/desktop/setup/install/windows-install/), cài đặt rồi mở Docker Desktop. Chờ Docker báo đang chạy. Nếu Windows yêu cầu bật WSL 2/ảo hóa hoặc khởi động lại máy, làm theo hướng dẫn trên màn hình.

## 2. Nhận và mở thư mục dự án

Tải/copy thư mục dự án do chủ nhóm chia sẻ về máy. Giữ thư mục `database` và `docker` nguyên vị trí trong dự án. SQL được tách riêng khỏi cấu hình Docker. Mở thư mục dự án (thư mục có `backend`, `database`, `docker` và `public`) trong File Explorer, bấm thanh địa chỉ, gõ `powershell`, rồi nhấn Enter. Các lệnh bên dưới chạy từ thư mục này.

## 3. Nạp image ứng dụng có sẵn

Trong PowerShell vừa mở, chạy:

```powershell
docker load --input docker/app-image.tar
```

Đợi lệnh báo nạp xong. Lệnh này đưa image từ file vào Docker; không build lại ứng dụng.

## 4. Chạy ứng dụng

Chạy tiếp:

```powershell
docker compose -f docker/compose.yaml up -d --no-build
```

`--no-build` yêu cầu Docker Compose không build mã nguồn. Lần chạy đầu cần Internet để tải image MySQL `mysql:8.0`. Sau khi chạy xong, mở <http://localhost:3000>.

Lần đầu mở web, tạo tài khoản quản trị theo biểu mẫu. Nếu tài khoản quản trị đã được tạo trước đó, đăng nhập bằng tài khoản đã có. Mỗi máy có database và tài khoản riêng; dữ liệu không tự đồng bộ giữa các thành viên. Docker Desktop phải tiếp tục chạy trong lúc sử dụng.

## 5. Dừng và mở lại

Dừng ứng dụng, vẫn giữ database:

```powershell
docker compose -f docker/compose.yaml down
```

Lần sau mở Docker Desktop, vào lại PowerShell tại thư mục dự án rồi chạy:

```powershell
docker compose -f docker/compose.yaml up -d --no-build
```

**Không chạy `docker compose -f docker/compose.yaml down -v` nếu muốn giữ dữ liệu**; lệnh đó xóa volume database trên máy.

## Nếu gặp lỗi

- Báo không nhận diện `docker`: mở Docker Desktop, chờ khởi động xong rồi mở PowerShell mới.
- `docker load` không tìm thấy file: kiểm tra PowerShell đang mở tại thư mục dự án và file `docker/app-image.tar` còn nguyên.
- Trang không mở: kiểm tra `docker compose -f docker/compose.yaml ps`; xem nhật ký bằng `docker compose -f docker/compose.yaml logs -f`, nhấn `Ctrl+C` để dừng xem log.
- MySQL không tải được: kiểm tra Internet rồi chạy lại lệnh khởi chạy.

Đây là bản demo sinh viên. Chỉ dùng dữ liệu giả; không nhập CCCD hoặc hồ sơ khai tử thật.

## Quên mật khẩu quản trị

Trên máy đang chạy ứng dụng, mở <http://localhost:3000>, chọn **Quên mật khẩu?**, nhập tên đăng nhập, trả lời câu hỏi khôi phục đã thiết lập rồi đặt mật khẩu mới (ít nhất 10 ký tự). Sau đó quay về đăng nhập. Việc này chỉ đổi mật khẩu, không xóa hồ sơ hay dữ liệu.

Tài khoản cũ chưa có câu hỏi khôi phục cần người vận hành cấu hình mã dự phòng `ADMIN_RECOVERY_TOKEN` ngẫu nhiên dài ít nhất 32 ký tự và bật `ALLOW_LOCAL_PASSWORD_RESET=true`. Không dùng tên người quản trị làm câu trả lời mặc định. Sau khi đăng nhập, thiết lập câu hỏi khôi phục trong menu tài khoản.

### Tạo lại image sau khi cập nhật mã nguồn

Chủ dự án chạy các lệnh sau trong PowerShell tại thư mục dự án rồi gửi file `docker/app-image.tar` mới cho thành viên:

```powershell
docker compose -f docker/compose.yaml build app
docker save --output docker/app-image.tar khai-tu-app:1.0
docker compose -f docker/compose.yaml up -d --no-build
```

Thành viên thay file `docker/app-image.tar` cũ bằng file mới, sau đó nạp lại image và khởi động:

```powershell
docker load --input docker/app-image.tar
docker compose -f docker/compose.yaml up -d --no-build
```
