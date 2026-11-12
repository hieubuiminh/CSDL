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
  MaCanBo VARCHAR(20) NULL,
  CreatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uq_app_user_can_bo UNIQUE (MaCanBo),
  CONSTRAINT fk_app_user_can_bo FOREIGN KEY (MaCanBo)
    REFERENCES Can_Bo(MaCanBo) ON DELETE RESTRICT,
  CONSTRAINT ck_app_user_role_can_bo CHECK (
    (Role='admin' AND MaCanBo IS NULL) OR
    (Role='staff' AND MaCanBo IS NOT NULL)
  )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng tài khoản tách riêng khỏi 9 bảng nghiệp vụ người dùng cung cấp.
-- Lần đầu mở web sẽ thiết lập ADMIN; không có mật khẩu mẫu ghi cứng.
-- Mỗi tài khoản cán bộ gắn duy nhất một Can_Bo; ADMIN không gắn cán bộ tiếp nhận.
-- CSDL đã chạy: dùng cap_nhat_lien_ket_can_bo.sql, không tạo lại các bảng nghiệp vụ.
