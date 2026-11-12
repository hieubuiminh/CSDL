-- Chạy một lần SAU file he_thong_quan_ly_dang_ky_khai_tu.sql của nhóm.
USE quan_ly_dang_ky_khai_tu;

-- Bảng tài khoản phục vụ đăng nhập vào ứng dụng.
CREATE TABLE IF NOT EXISTS App_User (
  Id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  Username VARCHAR(80) NOT NULL UNIQUE,
  PasswordHash VARCHAR(255) NOT NULL,
  DisplayName VARCHAR(160) NOT NULL,
  Role ENUM('admin','staff') NOT NULL DEFAULT 'staff',
  CreatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Đảm bảo một công dân chỉ có một hồ sơ khai tử.
-- Nếu lệnh báo trùng, cần xử lý các hồ sơ trùng CCCD_NgMat trước rồi chạy lại.
ALTER TABLE Ho_So_Khai_Tu
  ADD CONSTRAINT UQ_HoSo_NguoiMat UNIQUE (CCCD_NgMat);
