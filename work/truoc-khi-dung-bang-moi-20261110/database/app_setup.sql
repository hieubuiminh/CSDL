-- Chạy SAU schema chính (CSDL mới), hoặc sau khi nâng cấp CSDL đã có.
-- Giữ file này: tài khoản web là phần bổ sung ngoài 9 bảng nghiệp vụ của báo cáo.
SET NAMES utf8mb4;
USE quan_ly_dang_ky_khai_tu;

CREATE TABLE IF NOT EXISTS App_User (
  Id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  Username VARCHAR(80) NOT NULL UNIQUE,
  PasswordHash VARCHAR(255) NOT NULL,
  DisplayName VARCHAR(160) NOT NULL,
  Role ENUM('admin','staff') NOT NULL DEFAULT 'staff',
  CreatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- UNIQUE người mất đã nằm trong schema chính và file nâng cấp.
-- Không ALTER lặp ở đây để Docker không gặp lỗi trùng ràng buộc khi khởi tạo.
