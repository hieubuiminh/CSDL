-- Chạy SAU tao_bang.sql và du_lieu_mau.sql của bộ bảng mới.
-- Giữ file này: tài khoản web là phần bổ sung ngoài 9 bảng nghiệp vụ của báo cáo.
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
USE quan_li_khai_tu;

CREATE TABLE IF NOT EXISTS App_User (
  Id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  Username VARCHAR(80) NOT NULL UNIQUE,
  PasswordHash VARCHAR(255) NOT NULL,
  DisplayName VARCHAR(160) NOT NULL,
  Role ENUM('admin','staff') NOT NULL DEFAULT 'staff',
  CreatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng tài khoản tách riêng khỏi 9 bảng nghiệp vụ người dùng cung cấp.
-- Lần đầu mở web sẽ thiết lập ADMIN; không có mật khẩu mẫu ghi cứng.
