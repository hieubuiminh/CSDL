-- Goi thu cong tren MySQL >= 8.0.16, sau khi chon DUNG CSDL va tam dung ung dung.
-- Khong sua du lieu cu. Khong dung mysql --force; dung ngay neu gap loi.
-- DDL tu commit: toan bo file khong phai mot transaction co the rollback.
SET NAMES utf8mb4;
DELIMITER $$
DROP PROCEDURE IF EXISTS KT_Update_ApDung$$
CREATE PROCEDURE KT_Update_ApDung()
BEGIN
  DECLARE v_major INT;
  DECLARE v_minor INT;
  DECLARE v_patch INT;
  DECLARE v_exists INT DEFAULT 0;
  SET v_major = CAST(SUBSTRING_INDEX(VERSION(), '.', 1) AS UNSIGNED);
  SET v_minor = CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(VERSION(), '.', 2), '.', -1) AS UNSIGNED);
  SET v_patch = CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING_INDEX(VERSION(), '-', 1), '.', 3), '.', -1) AS UNSIGNED);
  IF DATABASE() IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Phải chọn đúng cơ sở dữ liệu trước khi chạy.';
  END IF;
  IF VERSION() LIKE '%MariaDB%' OR v_major < 8 OR (v_major = 8 AND v_minor = 0 AND v_patch < 16) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cần MySQL từ 8.0.16 để CHECK được thực thi.';
  END IF;
  -- Kiem tra truoc moi ALTER/DROP TRIGGER; khong tu sua ban ghi vi pham.
  IF EXISTS (SELECT 1 FROM Ho_So_Khai_Tu WHERE CCCD_NgKhaiTu = CCCD_NgMat) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Có hồ sơ có người khai trùng người mất. Hãy xử lý trước.';
  END IF;
  IF EXISTS (SELECT 1 FROM Giay_Bao_Tu WHERE DATE(NgayGioMat) > NgayCap) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Có giấy báo tử có ngày mất sau ngày cấp. Hãy xử lý trước.';
  END IF;
  IF EXISTS (SELECT 1 FROM Ho_So_Khai_Tu h JOIN Giay_Bao_Tu g ON g.SoGiayBaoTu = h.SoGiayBaoTu
    WHERE g.NgayCap > h.NgayDangKi) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Có hồ sơ đăng ký trước ngày cấp giấy báo tử. Hãy xử lý trước.';
  END IF;
  IF EXISTS (SELECT 1 FROM Ho_So_Khai_Tu GROUP BY CCCD_NgMat HAVING COUNT(*) > 1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Có công dân có nhiều hồ sơ khai tử. Hãy xử lý trước.';
  END IF;
  SELECT COUNT(*) INTO v_exists FROM information_schema.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = 'Ho_So_Khai_Tu'
      AND CONSTRAINT_NAME = 'CHK_NguoiKhaiTu' AND CONSTRAINT_TYPE = 'CHECK';
  IF v_exists = 0 THEN
    ALTER TABLE Ho_So_Khai_Tu ADD CONSTRAINT CHK_NguoiKhaiTu CHECK (CCCD_NgKhaiTu <> CCCD_NgMat);
  ELSE
    ALTER TABLE Ho_So_Khai_Tu ALTER CHECK CHK_NguoiKhaiTu ENFORCED;
  END IF;
  SELECT COUNT(*) INTO v_exists FROM information_schema.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = 'Giay_Bao_Tu'
      AND CONSTRAINT_NAME = 'KT_Update_CHK_NgayMat_NgayCap' AND CONSTRAINT_TYPE = 'CHECK';
  IF v_exists = 0 THEN
    ALTER TABLE Giay_Bao_Tu ADD CONSTRAINT KT_Update_CHK_NgayMat_NgayCap CHECK (DATE(NgayGioMat) <= NgayCap);
  ELSE
    ALTER TABLE Giay_Bao_Tu ALTER CHECK KT_Update_CHK_NgayMat_NgayCap ENFORCED;
  END IF;
  -- Chap nhan UNIQUE tu app_setup.sql hoac index tuong duong mang ten khac.
  SELECT COUNT(*) INTO v_exists FROM (
    SELECT INDEX_NAME FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'Ho_So_Khai_Tu' AND NON_UNIQUE = 0
    GROUP BY INDEX_NAME HAVING COUNT(*) = 1 AND MAX(COLUMN_NAME = 'CCCD_NgMat') = 1
  ) unique_indexes;
  IF v_exists = 0 THEN
    ALTER TABLE Ho_So_Khai_Tu ADD CONSTRAINT KT_Update_UQ_HoSo_NguoiMat UNIQUE (CCCD_NgMat);
  END IF;
END$$
CALL KT_Update_ApDung()$$
DROP PROCEDURE KT_Update_ApDung$$

-- Chi thay the 5 trigger cua file nay; giu cac trigger khac neu co.
DROP TRIGGER IF EXISTS KT_Update_HoSo_BI$$
CREATE TRIGGER KT_Update_HoSo_BI BEFORE INSERT ON Ho_So_Khai_Tu FOR EACH ROW
BEGIN
  DECLARE v_ngay_cap DATE DEFAULT NULL;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_ngay_cap = NULL;
  SELECT NgayCap INTO v_ngay_cap FROM Giay_Bao_Tu
    WHERE SoGiayBaoTu = NEW.SoGiayBaoTu FOR SHARE;
  IF v_ngay_cap > NEW.NgayDangKi THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ngày đăng ký không được trước ngày cấp giấy báo tử.';
  END IF;
  -- Neu giay bao tu khong ton tai, FOREIGN KEY cua schema goc se chan INSERT.
END$$
DROP TRIGGER IF EXISTS KT_Update_HoSo_BU$$
CREATE TRIGGER KT_Update_HoSo_BU BEFORE UPDATE ON Ho_So_Khai_Tu FOR EACH ROW
BEGIN
  DECLARE v_ngay_cap DATE DEFAULT NULL;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_ngay_cap = NULL;
  SELECT NgayCap INTO v_ngay_cap FROM Giay_Bao_Tu
    WHERE SoGiayBaoTu = NEW.SoGiayBaoTu FOR SHARE;
  IF v_ngay_cap > NEW.NgayDangKi THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ngày đăng ký không được trước ngày cấp giấy báo tử.';
  END IF;
END$$
DROP TRIGGER IF EXISTS KT_Update_GiayBaoTu_BU$$
CREATE TRIGGER KT_Update_GiayBaoTu_BU BEFORE UPDATE ON Giay_Bao_Tu FOR EACH ROW
BEGIN
  DECLARE v_ngay_dang_ky_dau DATE DEFAULT NULL;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_ngay_dang_ky_dau = NULL;
  -- Doc co khoa de thay du lieu moi nhat; doi ngay cap khong duoc pha ho so cu.
  SELECT NgayDangKi INTO v_ngay_dang_ky_dau FROM Ho_So_Khai_Tu
    WHERE SoGiayBaoTu = OLD.SoGiayBaoTu ORDER BY NgayDangKi LIMIT 1 FOR UPDATE;
  IF v_ngay_dang_ky_dau IS NOT NULL AND NEW.NgayCap > v_ngay_dang_ky_dau THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ngày cấp mới nằm sau ngày đăng ký của hồ sơ liên quan.';
  END IF;
END$$
DROP TRIGGER IF EXISTS KT_Update_HoSo_AI$$
CREATE TRIGGER KT_Update_HoSo_AI AFTER INSERT ON Ho_So_Khai_Tu FOR EACH ROW
BEGIN
  UPDATE Cong_Dan SET TrangThai = 'Đã mất' WHERE CCCD = NEW.CCCD_NgMat;
END$$
DROP TRIGGER IF EXISTS KT_Update_HoSo_AU$$
CREATE TRIGGER KT_Update_HoSo_AU AFTER UPDATE ON Ho_So_Khai_Tu FOR EACH ROW
BEGIN
  -- Neu doi nguoi mat, danh dau nguoi moi; khong tu suy dien nguoi cu dang song.
  UPDATE Cong_Dan SET TrangThai = 'Đã mất' WHERE CCCD = NEW.CCCD_NgMat;
END$$
DELIMITER ;

SELECT VERSION() AS PhienBanMySQL;
-- Chi thong bao so cong dan cu chua dong bo trang thai; KHONG tu UPDATE backlog.
SELECT COUNT(DISTINCT c.CCCD) AS SoCongDanCoHoSoNhungChuaDanhDauDaMat
FROM Cong_Dan c JOIN Ho_So_Khai_Tu h ON h.CCCD_NgMat = c.CCCD
WHERE c.TrangThai <> 'Đã mất';
SELECT 'Đã cài ràng buộc và 5 trigger; dữ liệu trạng thái cũ không bị tự sửa.' AS KetQua;
