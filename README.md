# Hệ thống quản lý đăng ký khai tử

Website hỗ trợ quản lý hồ sơ khai tử, tra cứu và thống kê, với hai vai trò ADMIN và cán bộ. Hướng dẫn dưới đây dành cho máy Windows, sử dụng Docker để chạy website và cơ sở dữ liệu cùng nhau.

Sau khi khởi động, bạn truy cập website tại http://localhost:3001. Cấu hình đi kèm chỉ cho phép truy cập từ chính máy đang chạy ứng dụng.

## Cấu trúc thư mục

| Thư mục / tệp | Nội dung |
|---|---|
| `backend/` | Phần xử lý của website: kiểm tra đăng nhập, phân quyền, đọc và lưu dữ liệu. Tệp `index.js` khởi động ứng dụng, `app.js` kết nối các chức năng. |
| `backend/modules/` | Các chức năng được chia thành từng thư mục riêng, trình bày ở bảng bên dưới. |
| `backend/config/` | Cấu hình hoạt động và kết nối cơ sở dữ liệu. |
| `backend/middleware/` | Kiểm tra đăng nhập, quyền truy cập và xử lý lỗi. |
| `backend/utils/` | Các hàm hỗ trợ được nhiều chức năng dùng chung. |
| `public/` | Phần giao diện bạn nhìn thấy trên trình duyệt. `index.html` là trang chính; các tệp CSS quy định màu sắc và bố cục. |
| `public/js/` | Xử lý thao tác trên giao diện như bấm nút, nhập biểu mẫu và hiển thị kết quả. |
| `public/assets/` | Tài nguyên của giao diện. |
| `database/` | Các tệp SQL tạo bảng, thêm dữ liệu mẫu và chuẩn bị phần tài khoản. |
| `docker/` | Cấu hình chạy ứng dụng. `compose.yaml` chạy website và MySQL cùng nhau; `Dockerfile` hướng dẫn Docker chuẩn bị ứng dụng. |
| `tests/` | Các chương trình kiểm thử dành cho người kiểm tra mã nguồn. Không cần sử dụng để chạy website. |
| `work/` (nếu có) | Bản sao lưu và kết quả kiểm tra trên máy. Website không dùng thư mục này khi hoạt động. |
| `package.json` | Danh sách thư viện và các lệnh chạy ứng dụng. |
| `README.md` | Tệp hướng dẫn bạn đang đọc. |

Các chức năng trong `backend/modules/`:

| Thư mục | Chức năng |
|---|---|
| `auth/` | Đăng nhập, đăng ký và khôi phục tài khoản. |
| `accounts/` | Quản lý tài khoản và mã mời đăng ký. |
| `catalogs/` | Quản lý dữ liệu dùng chung. |
| `dashboard/` | Số liệu trên trang tổng quan. |
| `registrations/` | Tạo, xem, tra cứu và xử lý hồ sơ khai tử. |
| `reports/` | Thống kê theo giới tính, địa bàn, nguyên nhân theo độ tuổi, cơ sở y tế và năm mất. |

Các tệp trong `database/`:

| Tệp | Dùng để làm gì? |
|---|---|
| `tao_bang.sql` | Tạo các bảng nghiệp vụ và ràng buộc dữ liệu. |
| `du_lieu_mau.sql` | Thêm bộ dữ liệu mẫu để xem và thử các chức năng. |
| `app_setup.sql` | Tạo phần lưu tài khoản và các thành phần bổ sung mà website cần. |
| `cap_nhat_lien_ket_can_bo.sql` | Bổ sung liên kết tài khoản với cán bộ cho cơ sở dữ liệu của phiên bản cũ. Khi cài mới theo hướng dẫn này, không cần chạy riêng tệp đó. |
| `truy_van.sql` | Lưu các câu SQL truy vấn tham khảo. Không cần chạy riêng tệp này để mở website. |

Có thể hiểu đơn giản: `public/` hiển thị màn hình và nhận thao tác của bạn; `backend/` kiểm tra quyền, đọc hoặc lưu dữ liệu rồi trả kết quả về giao diện. Thư mục `database/` chứa các tệp chuẩn bị cơ sở dữ liệu; dữ liệu đang sử dụng được lưu riêng trong Docker trên máy.

## 1. Chuẩn bị

- Cài Docker Desktop. Nếu chưa cài, bạn có thể làm theo [hướng dẫn cài đặt Docker Desktop cho Windows](https://docs.docker.com/desktop/setup/install/windows-install/).
- Mở Docker Desktop và chờ Docker khởi động xong.

Lần chạy đầu cần Internet để Docker tải các thành phần chưa có. Bạn không cần cài riêng Node.js hoặc MySQL.

### Tải dự án từ GitHub

1. Mở trang GitHub của dự án.
2. Bấm nút **Code**, chọn **Download ZIP** để tải dự án về máy.
3. Mở thư mục chứa tệp vừa tải, thường là **Downloads / Tải xuống**.
4. Nhấp chuột phải vào tệp ZIP, chọn **Extract All… / Giải nén tất cả…**, chọn nơi lưu rồi bấm **Extract / Giải nén**.
5. Mở thư mục vừa giải nén. Nếu bên trong còn một thư mục mang tên dự án, mở tiếp thư mục đó.

Bạn đã mở đúng thư mục dự án khi nhìn thấy **backend**, **public**, **database**, **docker** và tệp **package.json** cùng nằm ở đó. Hãy giải nén trước khi thực hiện bước tiếp theo.

### Mở cửa sổ nhập lệnh tại thư mục dự án

1. Trong cửa sổ thư mục đang chứa **package.json**, bấm vào thanh địa chỉ phía trên, nơi hiển thị đường dẫn thư mục.
2. Gõ `powershell` rồi nhấn **Enter**. Cửa sổ PowerShell sẽ mở ra tại đúng thư mục này.
3. Khi hướng dẫn yêu cầu chạy lệnh, sao chép lệnh, dán vào cửa sổ PowerShell rồi nhấn **Enter**.

## 2. Khởi chạy lần đầu

Trong cửa sổ PowerShell vừa mở, chạy:

~~~powershell
docker compose -f docker/compose.yaml up -d --build
~~~

Docker sẽ chuẩn bị ứng dụng, tạo cơ sở dữ liệu và nạp dữ liệu mẫu. Quá trình này có thể mất vài phút ở lần đầu. Docker tự chạy lần lượt `tao_bang.sql`, `du_lieu_mau.sql` và `app_setup.sql` trên cơ sở dữ liệu mới; bạn không cần mở từng tệp SQL để chạy thủ công.

Chờ lệnh chạy xong và cửa sổ hiện lại dòng để nhập lệnh tiếp.

Để xem trạng thái các dịch vụ, chạy:

~~~powershell
docker compose -f docker/compose.yaml ps
~~~

Trong kết quả, **db** là cơ sở dữ liệu, **app** là website. Khi **db** có chữ **healthy** và **app** có chữ **Up**, mở Chrome, Edge hoặc trình duyệt bạn thường dùng, nhập địa chỉ sau vào thanh địa chỉ:

http://localhost:3001

Sau khi chạy thành công, bạn có thể đóng cửa sổ PowerShell. Hãy để Docker Desktop tiếp tục chạy trong lúc sử dụng website.

## 3. Đăng nhập và tạo tài khoản

Ở lần sử dụng đầu tiên, website hiển thị màn hình tạo tài khoản quản trị. Nhập họ tên, tên đăng nhập, mật khẩu có ít nhất 10 ký tự và thông tin khôi phục để tạo ADMIN.

Nếu màn hình đã hiển thị Đăng nhập, hãy dùng tài khoản đã tạo trên máy đó. Bộ dữ liệu mẫu không tạo sẵn tài khoản đăng nhập.

Để tạo tài khoản cán bộ, ADMIN vào mục Tài khoản, chọn vai trò Cán bộ và chọn cán bộ tiếp nhận cần liên kết. Mỗi cán bộ chỉ gắn với một tài khoản. Nếu đăng ký bằng mã mời, ADMIN cần chọn cán bộ trước khi cấp mã.

ADMIN xem được toàn bộ hồ sơ. Cán bộ chỉ xem hồ sơ do mình tiếp nhận và các thống kê tương ứng.

Bạn có thể đăng nhập bằng ADMIN, mở mục Hồ sơ để xem dữ liệu mẫu hoặc thử tra cứu CCCD 001000000001.

## 4. Dừng và mở lại website

Các lệnh dưới đây đều được nhập trong PowerShell mở tại thư mục dự án, theo cách ở mục 1.

Khi muốn dừng website, chạy:

~~~powershell
docker compose -f docker/compose.yaml stop
~~~

Khi cần mở lại, khởi động Docker Desktop rồi chạy:

~~~powershell
docker compose -f docker/compose.yaml up -d
~~~

Sau đó truy cập lại http://localhost:3001. Dữ liệu và tài khoản được giữ trong vùng lưu trữ của Docker. Không cần tạo bảng hay nạp lại dữ liệu mẫu mỗi lần mở web.

Tệp ZIP tải từ GitHub chứa mã nguồn và bộ dữ liệu mẫu. Dữ liệu bạn nhập thêm và tài khoản đã tạo được lưu riêng trong Docker trên máy bạn. Khi cài lần đầu trên máy khác, bạn sẽ tạo tài khoản ADMIN riêng.

## 5. Cập nhật mã nguồn

Nếu bạn đã thay đổi mã nguồn hoặc thay bằng phiên bản mới, mở PowerShell tại thư mục dự án rồi chạy lần lượt hai lệnh:

~~~powershell
docker compose -f docker/compose.yaml build app
docker compose -f docker/compose.yaml up -d --no-deps --no-build --force-recreate app
~~~

Mở lại trình duyệt và nhấn Ctrl + F5 để tải giao diện mới.

Các lệnh trên cập nhật ứng dụng. Nếu phiên bản mới có thay đổi cấu trúc cơ sở dữ liệu, cần sao lưu và làm theo hướng dẫn nâng cấp của phiên bản đó. Chỉ sửa tệp SQL rồi chạy lại ứng dụng sẽ không tự thay đổi cơ sở dữ liệu đã có.

## 6. Nếu chưa mở được website

Kiểm tra Docker Desktop đã chạy, PowerShell đang được mở tại thư mục chứa `package.json` và địa chỉ truy cập là http://localhost:3001.

Để xem trạng thái và thông báo của ứng dụng, chạy lần lượt:

~~~powershell
docker compose -f docker/compose.yaml ps
docker compose -f docker/compose.yaml logs --tail=80 db app
~~~

Nếu MySQL đang khởi động, chờ db chuyển sang healthy rồi mở lại trang. Nếu cổng 3001 đang được chương trình khác sử dụng, cần xử lý việc trùng cổng trước khi chạy tiếp.

Khi giao diện chưa cập nhật, nhấn Ctrl + F5. Không xóa vùng lưu dữ liệu trong Docker hoặc chạy lại tệp dữ liệu mẫu chỉ để thử sửa lỗi, vì có thể làm mất hoặc trùng dữ liệu đang sử dụng.

