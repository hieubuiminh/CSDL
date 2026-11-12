# Hệ thống quản lý đăng ký khai tử

**Nguyên tắc vận hành: chỉ chạy trên máy cá nhân, không xuất bản hoặc triển khai ra bên ngoài.** Docker chỉ mở ứng dụng ở `127.0.0.1:3000`, không publish cổng MySQL. Tài nguyên giao diện và API dùng trong ứng dụng đều nằm cùng máy; không dùng CDN hoặc dịch vụ phân tích bên ngoài. Xem [ghi chú chạy local](docs/CHAY_CHI_TREN_MAY.md).

## Các chức năng

- Hồ sơ khai tử: toàn bộ hồ sơ với người mất, người đăng ký, ngày đăng ký, đơn vị tiếp nhận, trạng thái; tìm kiếm, lọc và xuất CSV.
- Tra cứu trích lục bằng CCCD 12 số: đầy đủ ngày sinh, ngày giờ mất, nguyên nhân, người khai, quan hệ, UBND cấp và in trích lục.
- Năm trang báo cáo độc lập: giới tính, địa bàn, nguyên nhân theo độ tuổi, cơ sở y tế và năm mất.
- ADMIN: quản lý tài khoản, vai trò, mã mời và danh mục; cán bộ: xử lý hồ sơ, tra cứu và xem báo cáo.

## Cấu trúc thư mục

- `backend/`: máy chủ Express, API và xử lý nghiệp vụ.
- `public/`: giao diện web HTML, CSS và JavaScript.
- `database/`: schema chính, tài khoản ứng dụng, file nâng cấp và bảy truy vấn báo cáo.
- `docker/`: Dockerfile, Compose và image ứng dụng dựng sẵn.
- `docs/`: hướng dẫn chạy dành cho thành viên.
- `package.json`: lệnh chạy ứng dụng và các thư viện Node.js.
- `.dockerignore`: những file không cần gửi vào Docker build context; phải ở thư mục gốc.

## Backend chia theo chức năng

```text
backend/
  index.js                    # Khởi động máy chủ
  app.js                      # Express, giao diện và lỗi
  modules/
    index.js                  # Ghép module và kiểm tra đăng nhập
    auth/index.js             # Đăng nhập, đăng ký, khôi phục
    accounts/index.js         # Tài khoản, vai trò, mã mời
    catalogs/index.js         # Danh mục và phân loại địa bàn
    dashboard/index.js        # Tổng quan
    registrations/index.js    # Danh sách, tra cứu, xử lý hồ sơ
    reports/
      index.js
      gender/index.js
      areas/index.js
      age-causes/index.js
      hospitals/index.js
      years/index.js
```

Các file `backend/routes/*.routes.js` và `backend/server.js` chuyển tiếp đến module mới để tương thích lệnh chạy cũ. Giao diện cũng có module riêng cho từng báo cáo, tra cứu và tài khoản.

## Phân quyền

| Chức năng | ADMIN | Cán bộ |
|---|---|---|
| Xem, tìm, tạo hồ sơ và cập nhật trạng thái | Có | Có |
| Tra cứu, in trích lục, xem báo cáo | Có | Có |
| Xóa hồ sơ | Có | Không |
| Tài khoản, vai trò, mã mời | Có | Không |
| Thêm danh mục và phân loại địa bàn | Có | Không |

Dùng hai giá trị `admin`/`staff` sẵn có trong bảng tài khoản. API đọc quyền hiện tại mỗi lần nhận yêu cầu; đổi quyền có hiệu lực ngay. Không cho tự hạ quyền hoặc hạ quyền ADMIN cuối cùng. Đăng ký bằng mã mời luôn tạo cán bộ.

## Quy tắc báo cáo

- Giới tính, tuổi và năm: mỗi người tính một lần, loại hồ sơ từ chối. CSDL cũ trùng người mất thì dùng hồ sơ không bị từ chối đầu tiên theo ngày và mã.
- Thống kê năm lấy năm mất trên giấy báo tử.
- Địa bàn lấy nơi mất trên giấy báo tử và năm đăng ký hồ sơ; chỉ xã thuộc Hà Nội đã được phân loại, giữ cả xã có 0 ca và xếp giảm dần.
- Tuổi tròn tại thời điểm mất: Dưới 18, 18–60 (gồm 60), Trên 60; hiển thị mọi nguyên nhân đồng hạng phổ biến nhất. Ngày tháng thiếu/lỗi được báo riêng.
- Cơ sở y tế: trên 50 giấy báo tử theo ngày cấp trong quý lịch hoàn chỉnh liền trước, theo giờ Việt Nam. Ví dụ ngày 09/11/2026 báo quý III/2026, từ 01/07 đến hết 30/09.

## SQL và CSDL đang chạy

Các file SQL đã được hiệu chỉnh theo báo cáo ngày 09/11/2026; xem [đối chiếu chi tiết](docs/DOI_CHIEU_BAO_CAO_SQL.md). Bản SQL trước khi sửa lưu ở `work/sql-before-report/`. CSDL Docker đang chạy chưa được thay đổi; máy chủ không tự chạy migration khi khởi động.

Đã hoàn tất kiểm thử schema mới và nâng cấp bằng dữ liệu giả trên MySQL riêng; xem [kết quả kiểm thử](docs/KIEM_THU_SQL_BAO_CAO.md). Kết quả này không thay thế kiểm tra dữ liệu thật trước khi áp dụng.

Schema chính dành cho **CSDL mới**. Với CSDL đang có dữ liệu, dùng `database/cap_nhat_rang_buoc.sql` theo [hướng dẫn nâng cấp](docs/CAP_NHAT_RANG_BUOC_DOCKER.md), sau khi sao lưu. Giữ `app_setup.sql` để tạo bảng tài khoản; UNIQUE nghiệp vụ đã chuyển về schema chính. Bảy truy vấn trong `database/truy_van_bao_cao.sql` có ghi rõ các hiệu chỉnh và khác biệt với cách thống kê hiện tại trên web.

CSDL gốc không có tỉnh/thành và loại đơn vị cho nơi mất. ADMIN vào **Dữ liệu dùng chung → Phân loại địa bàn**, nhập tỉnh/thành và chọn loại đơn vị cho danh mục hiện có. Dữ liệu phân loại chỉ lưu ở `data/ward-metadata.json`, không cập nhật bảng SQL. Chỉ địa bàn được xác nhận là `Hà Nội` và `Xã` được tính trong báo cáo Hà Nội. Báo cáo có thông báo khi còn địa bàn chưa phân loại.

Docker giữ cấu hình này trong volume `app_config`, tách khỏi `mysql_data`. Chạy Node trực tiếp có thể đặt vị trí bằng `WARD_METADATA_FILE`. Khi chuyển máy cần sao lưu cả cấu hình địa bàn.

## Chạy ứng dụng

Hướng dẫn Docker chi tiết nằm trong [hướng dẫn thành viên](docs/HUONG_DAN_THANH_VIEN.md). Chạy các lệnh Compose từ thư mục gốc theo dạng `docker compose -f docker/compose.yaml ...`.

Kết nối từ máy chủ web chỉ được publish trên `127.0.0.1:3000`.

Nếu đang cập nhật ứng dụng đã có, xem [hướng dẫn cập nhật](docs/HUONG_DAN_CAP_NHAT.md). Image cũ cần build lại để có mã mới. Kiểm tra bằng `npm test`; bộ kiểm thử dùng dữ liệu giả, không kết nối CSDL gốc.

Cách chia mục điều hướng tham khảo [USWDS Side navigation](https://designsystem.digital.gov/components/side-navigation/), áp dụng cùng mẫu giao diện đang có của dự án.
