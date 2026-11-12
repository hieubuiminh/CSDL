# Chỉ chạy ứng dụng trên máy cá nhân

Yêu cầu của chủ dự án: ứng dụng và CSDL chỉ phục vụ trên máy này; không xuất bản website, đưa lên hosting/cloud, tạo tunnel hoặc mở truy cập từ Internet/mạng LAN.

## Cấu hình đã kiểm tra ngày 10/11/2026

- Docker Compose mở web bằng `127.0.0.1:3000:3000`. Truy cập tại `http://localhost:3000` hoặc `http://127.0.0.1:3000`.
- Dịch vụ MySQL không có mục `ports`, không mở cổng CSDL ra máy khác. Ứng dụng kết nối đến dịch vụ `db` trong Docker trên cùng máy.
- `BIND_HOST: 0.0.0.0` trong Compose là địa chỉ nghe **bên trong container** để Docker chuyển tiếp được cổng. Cổng trên máy vẫn giới hạn ở `127.0.0.1`; giữ nguyên dòng ánh xạ cổng này.
- Khi chạy Node trực tiếp, `backend/index.js` mặc định nghe `127.0.0.1`; không đặt `BIND_HOST` thành địa chỉ mạng bên ngoài.
- CSS, JavaScript, font và biểu tượng được phục vụ từ thư mục `public` trên máy. API dùng đường dẫn `/api/...` cùng ứng dụng; không có CDN, analytics hoặc mã gửi hồ sơ đến dịch vụ ngoài trong mã nguồn đã kiểm tra.
- MySQL và cấu hình địa bàn lưu trong các volume Docker trên máy. Các bản sao lưu/hướng dẫn cũng là file cục bộ; không có bước upload hoặc xuất bản.

Docker có thể cần Internet để tải image/thư viện khi cài hoặc dựng ứng dụng. Việc này khác với việc công khai website hay gửi hồ sơ; ứng dụng hiện tại không cần dịch vụ bên ngoài để xử lý các chức năng nghiệp vụ.

Các lần kiểm thử SQL dùng container MySQL riêng, `--network none`, không gắn volume dự án hoặc mở cổng. Container thử đã được xóa sau khi kiểm tra; không chạy migration trên CSDL của chủ dự án.

Khi cập nhật sau này, giữ cấu hình truy cập local nêu trên. Không thêm hosting, tunnel hoặc cổng truy cập từ xa nếu chưa có yêu cầu mới của chủ dự án.
