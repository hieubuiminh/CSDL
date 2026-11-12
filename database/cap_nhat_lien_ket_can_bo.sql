-- Chạy bổ sung cho CSDL web đã có. Không xóa/tạo lại 9 bảng nghiệp vụ.
-- Nên sao lưu trước khi chạy. Có thể chạy lại: các thành phần đã có được giữ nguyên.
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
USE quan_li_khai_tu;

DELIMITER $$
DROP PROCEDURE IF EXISTS kt_migrate_app_user_officer_20261111$$
CREATE PROCEDURE kt_migrate_app_user_officer_20261111()
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.TABLES
    WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='App_User'
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Chua co App_User. Hay chay app_setup.sql truoc.';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='App_User' AND COLUMN_NAME='MaCanBo'
  ) THEN
    IF EXISTS (SELECT 1 FROM App_User WHERE Role='staff') THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Dang co tai khoan can bo chua lien ket. Can gan MaCanBo tung tai khoan truoc.';
    END IF;
    ALTER TABLE App_User ADD COLUMN MaCanBo VARCHAR(20) NULL AFTER Role;
  END IF;

  IF EXISTS (
    SELECT 1 FROM App_User a LEFT JOIN Can_Bo cb ON cb.MaCanBo=a.MaCanBo
    WHERE (a.Role='staff' AND (a.MaCanBo IS NULL OR cb.MaCanBo IS NULL))
      OR (a.Role='admin' AND a.MaCanBo IS NOT NULL)
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Lien ket tai khoan/can bo khong hop le. Khong tu dong gan hoac doi du lieu.';
  END IF;
  IF EXISTS (
    SELECT 1 FROM App_User WHERE MaCanBo IS NOT NULL GROUP BY MaCanBo HAVING COUNT(*)>1
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Mot can bo dang gan nhieu tai khoan. Can kiem tra truoc khi cap nhat.';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME='App_User' AND CONSTRAINT_NAME='uq_app_user_can_bo'
  ) THEN
    ALTER TABLE App_User ADD CONSTRAINT uq_app_user_can_bo UNIQUE (MaCanBo);
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME='App_User' AND CONSTRAINT_NAME='fk_app_user_can_bo'
  ) THEN
    ALTER TABLE App_User ADD CONSTRAINT fk_app_user_can_bo
      FOREIGN KEY (MaCanBo) REFERENCES Can_Bo(MaCanBo) ON DELETE RESTRICT;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME='App_User' AND CONSTRAINT_NAME='ck_app_user_role_can_bo'
  ) THEN
    ALTER TABLE App_User ADD CONSTRAINT ck_app_user_role_can_bo CHECK (
      (Role='admin' AND MaCanBo IS NULL) OR (Role='staff' AND MaCanBo IS NOT NULL)
    );
  END IF;
END$$
CALL kt_migrate_app_user_officer_20261111()$$
DROP PROCEDURE kt_migrate_app_user_officer_20261111$$
DELIMITER ;
