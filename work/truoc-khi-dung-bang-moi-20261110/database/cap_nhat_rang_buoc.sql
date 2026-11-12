-- NANG CAP 9 BANG THEO BAO CAO; chon dung CSDL, sao luu va dung app truoc khi chay.
-- MySQL >= 8.0.16; mysql batch KHONG --force. File khong tu duoc thuc thi.
-- DDL tu COMMIT: loi giua chung khong the rollback toan file; giu app dung de xu ly.
-- Khong cat/xoa du lieu; chi chuyen nhan trang thai cu da biet, khong backfill sinh tu.
-- Khong sua App_User/bang ung dung; khong vo hieu hoa kiem tra khoa ngoai.
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
DELIMITER $$
DROP PROCEDURE IF EXISTS KT_Update_EnsureUnique$$
CREATE PROCEDURE KT_Update_EnsureUnique(IN p_table VARCHAR(64), IN p_column VARCHAR(64), IN p_name VARCHAR(64))
BEGIN
  DECLARE v_exists INT DEFAULT 0;
  IF NOT ((p_table='Ho_So_Khai_Tu' AND p_column IN ('CCCD_NgMat','SoGiayBaoTu'))
    OR (p_table='Can_Bo' AND p_column='CCCD') OR (p_table='An_Tang' AND p_column='SoGiayKhaiTu')) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Index nằm ngoài phạm vi nâng cấp.';
  END IF;
  SELECT COUNT(*) INTO v_exists FROM (
    SELECT INDEX_NAME FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=p_table AND NON_UNIQUE=0
    GROUP BY INDEX_NAME HAVING COUNT(*)=1 AND MAX(COLUMN_NAME=p_column)=1
  ) equivalent_unique;
  IF v_exists=0 THEN
    SET @kt_update_sql=CONCAT('ALTER TABLE `',p_table,'` ADD CONSTRAINT `',REPLACE(p_name,'`','``'),'` UNIQUE (`',p_column,'`)');
    PREPARE kt_update_statement FROM @kt_update_sql;
    EXECUTE kt_update_statement;
    DEALLOCATE PREPARE kt_update_statement;
  END IF;
END$$
DROP PROCEDURE IF EXISTS KT_Update_Preflight$$
CREATE PROCEDURE KT_Update_Preflight()
BEGIN
  DECLARE v_major INT;
  DECLARE v_minor INT;
  DECLARE v_patch INT;
  DECLARE v_count INT DEFAULT 0;
  IF DATABASE() IS NULL OR DATABASE()<>'quan_ly_dang_ky_khai_tu' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Chỉ được nâng cấp CSDL quan_ly_dang_ky_khai_tu; hãy chọn lại.';
  END IF;
  SET v_major=CAST(SUBSTRING_INDEX(VERSION(),'.',1) AS UNSIGNED);
  SET v_minor=CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(VERSION(),'.',2),'.',-1) AS UNSIGNED);
  SET v_patch=CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING_INDEX(VERSION(),'-',1),'.',3),'.',-1) AS UNSIGNED);
  IF VERSION() LIKE '%MariaDB%' OR v_major<8 OR (v_major=8 AND v_minor=0 AND v_patch<16) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cần MySQL từ 8.0.16 để thực thi CHECK.';
  END IF;
  SELECT COUNT(*) INTO v_count FROM information_schema.TABLES
    WHERE TABLE_SCHEMA=DATABASE() AND TABLE_TYPE='BASE TABLE' AND ENGINE='InnoDB' AND TABLE_NAME IN ('Nguyen_Nhan','CSYT','Cong_Dan','UBND','Noi_Mat','Can_Bo','Giay_Bao_Tu','Ho_So_Khai_Tu','An_Tang');
  IF v_count<>9 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Thiếu bảng gốc hoặc bảng không dùng InnoDB. Cần kiểm tra trước.';
  END IF;
  -- TAT CA PREFLIGHT truoc ALTER, DROP TRIGGER va chuyen nhan du lieu.
  IF EXISTS (SELECT 1 FROM Nguyen_Nhan WHERE MaNguyenNhan IS NULL
      OR CHAR_LENGTH(MaNguyenNhan)>20
      OR TenNguyenNhan IS NULL
      OR CHAR_LENGTH(TenNguyenNhan)>150) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nguyen_Nhan: có NULL bắt buộc hoặc dữ liệu vượt độ dài đích; không tự cắt.';
  END IF;
  IF EXISTS (SELECT 1 FROM CSYT WHERE MaCSYT IS NULL
      OR CHAR_LENGTH(MaCSYT)>20
      OR TenCSYT IS NULL
      OR CHAR_LENGTH(TenCSYT)>150
      OR DiaChi IS NULL
      OR CHAR_LENGTH(DiaChi)>255
      OR CHAR_LENGTH(SDT)>15) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CSYT: có NULL bắt buộc hoặc dữ liệu vượt độ dài đích; không tự cắt.';
  END IF;
  IF EXISTS (SELECT 1 FROM Cong_Dan WHERE CCCD IS NULL
      OR CHAR_LENGTH(CCCD)>12
      OR HoTen IS NULL
      OR CHAR_LENGTH(HoTen)>100
      OR NgaySinh IS NULL
      OR GioiTinh IS NULL
      OR QueQuan IS NULL
      OR CHAR_LENGTH(QueQuan)>200
      OR CHAR_LENGTH(DanToc)>50
      OR CHAR_LENGTH(SDT)>15
      OR TrangThai IS NULL
      OR CHAR_LENGTH(TrangThai)>30) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cong_Dan: có NULL bắt buộc hoặc dữ liệu vượt độ dài đích; không tự cắt.';
  END IF;
  IF EXISTS (SELECT 1 FROM UBND WHERE MaUBND IS NULL
      OR CHAR_LENGTH(MaUBND)>20
      OR TenUBND IS NULL
      OR CHAR_LENGTH(TenUBND)>150
      OR CapHanhChinh IS NULL
      OR CHAR_LENGTH(CapHanhChinh)>50
      OR DiaChi IS NULL
      OR CHAR_LENGTH(DiaChi)>255
      OR CHAR_LENGTH(SDT)>15) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'UBND: có NULL bắt buộc hoặc dữ liệu vượt độ dài đích; không tự cắt.';
  END IF;
  IF EXISTS (SELECT 1 FROM Noi_Mat WHERE MaXaPhuong IS NULL
      OR CHAR_LENGTH(MaXaPhuong)>20
      OR TenXaPhuong IS NULL
      OR CHAR_LENGTH(TenXaPhuong)>100) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Noi_Mat: có NULL bắt buộc hoặc dữ liệu vượt độ dài đích; không tự cắt.';
  END IF;
  IF EXISTS (SELECT 1 FROM Can_Bo WHERE MaCanBo IS NULL
      OR CHAR_LENGTH(MaCanBo)>20
      OR CCCD IS NULL
      OR CHAR_LENGTH(CCCD)>12
      OR HoTen IS NULL
      OR CHAR_LENGTH(HoTen)>100
      OR ChucVu IS NULL
      OR CHAR_LENGTH(ChucVu)>100
      OR CHAR_LENGTH(SDT)>15
      OR MaUBND IS NULL
      OR CHAR_LENGTH(MaUBND)>20) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Can_Bo: có NULL bắt buộc hoặc dữ liệu vượt độ dài đích; không tự cắt.';
  END IF;
  IF EXISTS (SELECT 1 FROM Giay_Bao_Tu WHERE SoGiayBaoTu IS NULL
      OR CHAR_LENGTH(SoGiayBaoTu)>30
      OR NgayCap IS NULL
      OR NgayGioMat IS NULL
      OR NoiMatChiTiet IS NULL
      OR CHAR_LENGTH(NoiMatChiTiet)>255
      OR OCTET_LENGTH(CONVERT(MoTaNguyenNhan USING utf8mb4))>65535
      OR MaNguyenNhan IS NULL
      OR CHAR_LENGTH(MaNguyenNhan)>20
      OR MaXaPhuong IS NULL
      OR CHAR_LENGTH(MaXaPhuong)>20
      OR MaCSYT IS NULL
      OR CHAR_LENGTH(MaCSYT)>20) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Giay_Bao_Tu: có NULL bắt buộc hoặc dữ liệu vượt độ dài đích; không tự cắt.';
  END IF;
  IF EXISTS (SELECT 1 FROM Ho_So_Khai_Tu WHERE SoGiayKhaiTu IS NULL
      OR CHAR_LENGTH(SoGiayKhaiTu)>30
      OR NgayDangKi IS NULL
      OR QuanHe IS NULL
      OR CHAR_LENGTH(QuanHe)>50
      OR TrangThaiHoSo IS NULL
      OR CHAR_LENGTH(TrangThaiHoSo)>50
      OR SoGiayBaoTu IS NULL
      OR CHAR_LENGTH(SoGiayBaoTu)>30
      OR CCCD_NgMat IS NULL
      OR CHAR_LENGTH(CCCD_NgMat)>12
      OR CCCD_NgKhaiTu IS NULL
      OR CHAR_LENGTH(CCCD_NgKhaiTu)>12
      OR MaCanBoTiepNhan IS NULL
      OR CHAR_LENGTH(MaCanBoTiepNhan)>20) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ho_So_Khai_Tu: có NULL bắt buộc hoặc dữ liệu vượt độ dài đích; không tự cắt.';
  END IF;
  IF EXISTS (SELECT 1 FROM An_Tang WHERE MaAnTang IS NULL
      OR CHAR_LENGTH(MaAnTang)>30
      OR HinhThuc IS NULL
      OR CHAR_LENGTH(HinhThuc)>50
      OR TenNghiaTrang IS NULL
      OR CHAR_LENGTH(TenNghiaTrang)>150
      OR NgayAnTang IS NULL
      OR SoGiayKhaiTu IS NULL
      OR CHAR_LENGTH(SoGiayKhaiTu)>30) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'An_Tang: có NULL bắt buộc hoặc dữ liệu vượt độ dài đích; không tự cắt.';
  END IF;
  IF EXISTS (SELECT 1 FROM Cong_Dan WHERE CHAR_LENGTH(CCCD)<>12 OR NOT REGEXP_LIKE(CCCD,'^[0-9]{12}$','c')) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cong_Dan.CCCD: phải đủ 12 chữ số ASCII.';
  END IF;
  IF EXISTS (SELECT 1 FROM Can_Bo WHERE CHAR_LENGTH(CCCD)<>12 OR NOT REGEXP_LIKE(CCCD,'^[0-9]{12}$','c')) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Can_Bo.CCCD: phải đủ 12 chữ số ASCII.';
  END IF;
  IF EXISTS (SELECT 1 FROM Ho_So_Khai_Tu WHERE CHAR_LENGTH(CCCD_NgMat)<>12 OR NOT REGEXP_LIKE(CCCD_NgMat,'^[0-9]{12}$','c')) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ho_So_Khai_Tu.CCCD_NgMat: phải đủ 12 chữ số ASCII.';
  END IF;
  IF EXISTS (SELECT 1 FROM Ho_So_Khai_Tu WHERE CHAR_LENGTH(CCCD_NgKhaiTu)<>12 OR NOT REGEXP_LIKE(CCCD_NgKhaiTu,'^[0-9]{12}$','c')) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ho_So_Khai_Tu.CCCD_NgKhaiTu: phải đủ 12 chữ số ASCII.';
  END IF;
  IF EXISTS (SELECT 1 FROM Cong_Dan WHERE BINARY GioiTinh NOT IN (BINARY 'Nam',BINARY 'Nữ',BINARY 'Khác')) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Giới tính không thuộc Nam/Nữ/Khác; không tự suy diễn.';
  END IF;
  IF EXISTS (SELECT 1 FROM Cong_Dan WHERE BINARY TrangThai NOT IN (BINARY 'Còn sống',BINARY 'Đang sống',BINARY 'Đã mất')) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Trạng thái công dân lạ; chỉ hỗ trợ Còn sống/Đang sống/Đã mất.';
  END IF;
  IF EXISTS (SELECT 1 FROM Ho_So_Khai_Tu WHERE BINARY TrangThaiHoSo NOT IN (BINARY 'Đã duyệt',BINARY 'Chờ xử lý',BINARY 'Từ chối',BINARY 'Đã tiếp nhận',BINARY 'Đang xử lý',BINARY 'Chờ duyệt',BINARY 'Đã hoàn tất')) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Trạng thái hồ sơ lạ; cần xem xét thủ công trước khi nâng cấp.';
  END IF;
  IF EXISTS (SELECT 1 FROM Cong_Dan WHERE YEAR(NgaySinh)<1000 OR LAST_DAY(NgaySinh) IS NULL OR DAYOFMONTH(NgaySinh)<1 OR DAYOFMONTH(NgaySinh)>DAYOFMONTH(LAST_DAY(NgaySinh))) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cong_Dan.NgaySinh: có ngày không hợp lệ.';
  END IF;
  IF EXISTS (SELECT 1 FROM Giay_Bao_Tu WHERE YEAR(NgayCap)<1000 OR LAST_DAY(NgayCap) IS NULL OR DAYOFMONTH(NgayCap)<1 OR DAYOFMONTH(NgayCap)>DAYOFMONTH(LAST_DAY(NgayCap))) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Giay_Bao_Tu.NgayCap: có ngày không hợp lệ.';
  END IF;
  IF EXISTS (SELECT 1 FROM Giay_Bao_Tu WHERE YEAR(NgayGioMat)<1000 OR LAST_DAY(NgayGioMat) IS NULL OR DAYOFMONTH(NgayGioMat)<1 OR DAYOFMONTH(NgayGioMat)>DAYOFMONTH(LAST_DAY(NgayGioMat))) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Giay_Bao_Tu.NgayGioMat: có ngày không hợp lệ.';
  END IF;
  IF EXISTS (SELECT 1 FROM Ho_So_Khai_Tu WHERE YEAR(NgayDangKi)<1000 OR LAST_DAY(NgayDangKi) IS NULL OR DAYOFMONTH(NgayDangKi)<1 OR DAYOFMONTH(NgayDangKi)>DAYOFMONTH(LAST_DAY(NgayDangKi))) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ho_So_Khai_Tu.NgayDangKi: có ngày không hợp lệ.';
  END IF;
  IF EXISTS (SELECT 1 FROM An_Tang WHERE YEAR(NgayAnTang)<1000 OR LAST_DAY(NgayAnTang) IS NULL OR DAYOFMONTH(NgayAnTang)<1 OR DAYOFMONTH(NgayAnTang)>DAYOFMONTH(LAST_DAY(NgayAnTang))) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'An_Tang.NgayAnTang: có ngày không hợp lệ.';
  END IF;
  IF EXISTS (SELECT 1 FROM Giay_Bao_Tu WHERE DATE(NgayGioMat)>NgayCap) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Có ngày mất sau ngày cấp giấy báo tử.';
  END IF;
  IF EXISTS (SELECT 1 FROM Ho_So_Khai_Tu WHERE CCCD_NgKhaiTu=CCCD_NgMat) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Có hồ sơ có người khai trùng người mất.';
  END IF;
  IF EXISTS (SELECT 1 FROM Ho_So_Khai_Tu h JOIN Giay_Bao_Tu g ON CONVERT(h.SoGiayBaoTu USING utf8mb4) COLLATE utf8mb4_unicode_ci=CONVERT(g.SoGiayBaoTu USING utf8mb4) COLLATE utf8mb4_unicode_ci WHERE g.NgayCap>h.NgayDangKi) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Có hồ sơ đăng ký trước ngày cấp giấy báo tử.';
  END IF;
  -- Duplicate va orphan duoc kiem tra theo collation DICH truoc khi doi kieu.
  IF EXISTS (SELECT 1 FROM Nguyen_Nhan GROUP BY CONVERT(MaNguyenNhan USING utf8mb4) COLLATE utf8mb4_unicode_ci HAVING COUNT(*)>1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nguyen_Nhan: khóa chính bị trùng ở utf8mb4_unicode_ci.';
  END IF;
  IF EXISTS (SELECT 1 FROM CSYT GROUP BY CONVERT(MaCSYT USING utf8mb4) COLLATE utf8mb4_unicode_ci HAVING COUNT(*)>1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CSYT: khóa chính bị trùng ở utf8mb4_unicode_ci.';
  END IF;
  IF EXISTS (SELECT 1 FROM Cong_Dan GROUP BY CONVERT(CCCD USING utf8mb4) COLLATE utf8mb4_unicode_ci HAVING COUNT(*)>1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cong_Dan: khóa chính bị trùng ở utf8mb4_unicode_ci.';
  END IF;
  IF EXISTS (SELECT 1 FROM UBND GROUP BY CONVERT(MaUBND USING utf8mb4) COLLATE utf8mb4_unicode_ci HAVING COUNT(*)>1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'UBND: khóa chính bị trùng ở utf8mb4_unicode_ci.';
  END IF;
  IF EXISTS (SELECT 1 FROM Noi_Mat GROUP BY CONVERT(MaXaPhuong USING utf8mb4) COLLATE utf8mb4_unicode_ci HAVING COUNT(*)>1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Noi_Mat: khóa chính bị trùng ở utf8mb4_unicode_ci.';
  END IF;
  IF EXISTS (SELECT 1 FROM Can_Bo GROUP BY CONVERT(MaCanBo USING utf8mb4) COLLATE utf8mb4_unicode_ci HAVING COUNT(*)>1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Can_Bo: khóa chính bị trùng ở utf8mb4_unicode_ci.';
  END IF;
  IF EXISTS (SELECT 1 FROM Giay_Bao_Tu GROUP BY CONVERT(SoGiayBaoTu USING utf8mb4) COLLATE utf8mb4_unicode_ci HAVING COUNT(*)>1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Giay_Bao_Tu: khóa chính bị trùng ở utf8mb4_unicode_ci.';
  END IF;
  IF EXISTS (SELECT 1 FROM Ho_So_Khai_Tu GROUP BY CONVERT(SoGiayKhaiTu USING utf8mb4) COLLATE utf8mb4_unicode_ci HAVING COUNT(*)>1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ho_So_Khai_Tu: khóa chính bị trùng ở utf8mb4_unicode_ci.';
  END IF;
  IF EXISTS (SELECT 1 FROM An_Tang GROUP BY CONVERT(MaAnTang USING utf8mb4) COLLATE utf8mb4_unicode_ci HAVING COUNT(*)>1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'An_Tang: khóa chính bị trùng ở utf8mb4_unicode_ci.';
  END IF;
  IF EXISTS (SELECT 1 FROM Can_Bo GROUP BY CONVERT(CCCD USING utf8mb4) COLLATE utf8mb4_unicode_ci HAVING COUNT(*)>1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Can_Bo.CCCD: có giá trị trùng, chưa thể tạo UNIQUE.';
  END IF;
  IF EXISTS (SELECT 1 FROM Ho_So_Khai_Tu GROUP BY CONVERT(CCCD_NgMat USING utf8mb4) COLLATE utf8mb4_unicode_ci HAVING COUNT(*)>1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ho_So_Khai_Tu.CCCD_NgMat: có giá trị trùng, chưa thể tạo UNIQUE.';
  END IF;
  IF EXISTS (SELECT 1 FROM Ho_So_Khai_Tu GROUP BY CONVERT(SoGiayBaoTu USING utf8mb4) COLLATE utf8mb4_unicode_ci HAVING COUNT(*)>1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ho_So_Khai_Tu.SoGiayBaoTu: có giá trị trùng, chưa thể tạo UNIQUE.';
  END IF;
  IF EXISTS (SELECT 1 FROM An_Tang GROUP BY CONVERT(SoGiayKhaiTu USING utf8mb4) COLLATE utf8mb4_unicode_ci HAVING COUNT(*)>1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'An_Tang.SoGiayKhaiTu: có giá trị trùng, chưa thể tạo UNIQUE.';
  END IF;
  IF EXISTS (SELECT 1 FROM Can_Bo c LEFT JOIN UBND p ON CONVERT(c.MaUBND USING utf8mb4) COLLATE utf8mb4_unicode_ci=CONVERT(p.MaUBND USING utf8mb4) COLLATE utf8mb4_unicode_ci WHERE p.MaUBND IS NULL) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Can_Bo.MaUBND: có khóa ngoại không tìm thấy bản ghi cha.';
  END IF;
  IF EXISTS (SELECT 1 FROM Giay_Bao_Tu c LEFT JOIN Nguyen_Nhan p ON CONVERT(c.MaNguyenNhan USING utf8mb4) COLLATE utf8mb4_unicode_ci=CONVERT(p.MaNguyenNhan USING utf8mb4) COLLATE utf8mb4_unicode_ci WHERE p.MaNguyenNhan IS NULL) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Giay_Bao_Tu.MaNguyenNhan: có khóa ngoại không tìm thấy bản ghi cha.';
  END IF;
  IF EXISTS (SELECT 1 FROM Giay_Bao_Tu c LEFT JOIN Noi_Mat p ON CONVERT(c.MaXaPhuong USING utf8mb4) COLLATE utf8mb4_unicode_ci=CONVERT(p.MaXaPhuong USING utf8mb4) COLLATE utf8mb4_unicode_ci WHERE p.MaXaPhuong IS NULL) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Giay_Bao_Tu.MaXaPhuong: có khóa ngoại không tìm thấy bản ghi cha.';
  END IF;
  IF EXISTS (SELECT 1 FROM Giay_Bao_Tu c LEFT JOIN CSYT p ON CONVERT(c.MaCSYT USING utf8mb4) COLLATE utf8mb4_unicode_ci=CONVERT(p.MaCSYT USING utf8mb4) COLLATE utf8mb4_unicode_ci WHERE p.MaCSYT IS NULL) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Giay_Bao_Tu.MaCSYT: có khóa ngoại không tìm thấy bản ghi cha.';
  END IF;
  IF EXISTS (SELECT 1 FROM Ho_So_Khai_Tu c LEFT JOIN Giay_Bao_Tu p ON CONVERT(c.SoGiayBaoTu USING utf8mb4) COLLATE utf8mb4_unicode_ci=CONVERT(p.SoGiayBaoTu USING utf8mb4) COLLATE utf8mb4_unicode_ci WHERE p.SoGiayBaoTu IS NULL) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ho_So_Khai_Tu.SoGiayBaoTu: có khóa ngoại không tìm thấy bản ghi cha.';
  END IF;
  IF EXISTS (SELECT 1 FROM Ho_So_Khai_Tu c LEFT JOIN Cong_Dan p ON CONVERT(c.CCCD_NgMat USING utf8mb4) COLLATE utf8mb4_unicode_ci=CONVERT(p.CCCD USING utf8mb4) COLLATE utf8mb4_unicode_ci WHERE p.CCCD IS NULL) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ho_So_Khai_Tu.CCCD_NgMat: có khóa ngoại không tìm thấy bản ghi cha.';
  END IF;
  IF EXISTS (SELECT 1 FROM Ho_So_Khai_Tu c LEFT JOIN Cong_Dan p ON CONVERT(c.CCCD_NgKhaiTu USING utf8mb4) COLLATE utf8mb4_unicode_ci=CONVERT(p.CCCD USING utf8mb4) COLLATE utf8mb4_unicode_ci WHERE p.CCCD IS NULL) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ho_So_Khai_Tu.CCCD_NgKhaiTu: có khóa ngoại không tìm thấy bản ghi cha.';
  END IF;
  IF EXISTS (SELECT 1 FROM Ho_So_Khai_Tu c LEFT JOIN Can_Bo p ON CONVERT(c.MaCanBoTiepNhan USING utf8mb4) COLLATE utf8mb4_unicode_ci=CONVERT(p.MaCanBo USING utf8mb4) COLLATE utf8mb4_unicode_ci WHERE p.MaCanBo IS NULL) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ho_So_Khai_Tu.MaCanBoTiepNhan: có khóa ngoại không tìm thấy bản ghi cha.';
  END IF;
  IF EXISTS (SELECT 1 FROM An_Tang c LEFT JOIN Ho_So_Khai_Tu p ON CONVERT(c.SoGiayKhaiTu USING utf8mb4) COLLATE utf8mb4_unicode_ci=CONVERT(p.SoGiayKhaiTu USING utf8mb4) COLLATE utf8mb4_unicode_ci WHERE p.SoGiayKhaiTu IS NULL) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'An_Tang.SoGiayKhaiTu: có khóa ngoại không tìm thấy bản ghi cha.';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.KEY_COLUMN_USAGE k WHERE k.REFERENCED_TABLE_NAME IS NOT NULL
      AND ((k.TABLE_SCHEMA=DATABASE() AND k.TABLE_NAME IN ('Nguyen_Nhan','CSYT','Cong_Dan','UBND','Noi_Mat','Can_Bo','Giay_Bao_Tu','Ho_So_Khai_Tu','An_Tang'))
        OR (k.REFERENCED_TABLE_SCHEMA=DATABASE() AND k.REFERENCED_TABLE_NAME IN ('Nguyen_Nhan','CSYT','Cong_Dan','UBND','Noi_Mat','Can_Bo','Giay_Bao_Tu','Ho_So_Khai_Tu','An_Tang')))
      AND NOT (k.TABLE_SCHEMA=DATABASE() AND k.REFERENCED_TABLE_SCHEMA=DATABASE() AND (
        (k.TABLE_NAME='Can_Bo' AND k.COLUMN_NAME='MaUBND' AND k.REFERENCED_TABLE_NAME='UBND' AND k.REFERENCED_COLUMN_NAME='MaUBND')
        OR (k.TABLE_NAME='Giay_Bao_Tu' AND k.COLUMN_NAME='MaNguyenNhan' AND k.REFERENCED_TABLE_NAME='Nguyen_Nhan' AND k.REFERENCED_COLUMN_NAME='MaNguyenNhan')
        OR (k.TABLE_NAME='Giay_Bao_Tu' AND k.COLUMN_NAME='MaXaPhuong' AND k.REFERENCED_TABLE_NAME='Noi_Mat' AND k.REFERENCED_COLUMN_NAME='MaXaPhuong')
        OR (k.TABLE_NAME='Giay_Bao_Tu' AND k.COLUMN_NAME='MaCSYT' AND k.REFERENCED_TABLE_NAME='CSYT' AND k.REFERENCED_COLUMN_NAME='MaCSYT')
        OR (k.TABLE_NAME='Ho_So_Khai_Tu' AND k.COLUMN_NAME='SoGiayBaoTu' AND k.REFERENCED_TABLE_NAME='Giay_Bao_Tu' AND k.REFERENCED_COLUMN_NAME='SoGiayBaoTu')
        OR (k.TABLE_NAME='Ho_So_Khai_Tu' AND k.COLUMN_NAME='CCCD_NgMat' AND k.REFERENCED_TABLE_NAME='Cong_Dan' AND k.REFERENCED_COLUMN_NAME='CCCD')
        OR (k.TABLE_NAME='Ho_So_Khai_Tu' AND k.COLUMN_NAME='CCCD_NgKhaiTu' AND k.REFERENCED_TABLE_NAME='Cong_Dan' AND k.REFERENCED_COLUMN_NAME='CCCD')
        OR (k.TABLE_NAME='Ho_So_Khai_Tu' AND k.COLUMN_NAME='MaCanBoTiepNhan' AND k.REFERENCED_TABLE_NAME='Can_Bo' AND k.REFERENCED_COLUMN_NAME='MaCanBo')
        OR (k.TABLE_NAME='An_Tang' AND k.COLUMN_NAME='SoGiayKhaiTu' AND k.REFERENCED_TABLE_NAME='Ho_So_Khai_Tu' AND k.REFERENCED_COLUMN_NAME='SoGiayKhaiTu')))) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Có FK tùy biến/ngoài 9 bảng gốc; cần migration riêng, không tự xóa.';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.KEY_COLUMN_USAGE WHERE CONSTRAINT_SCHEMA=DATABASE()
      AND REFERENCED_TABLE_NAME IS NOT NULL AND TABLE_NAME IN ('Nguyen_Nhan','CSYT','Cong_Dan','UBND','Noi_Mat','Can_Bo','Giay_Bao_Tu','Ho_So_Khai_Tu','An_Tang')
      GROUP BY TABLE_NAME,CONSTRAINT_NAME HAVING COUNT(*)<>1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Có FK nhiều cột ngoài đặc tả; cần migration riêng.';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA=DATABASE() AND EVENT_OBJECT_TABLE IN ('Nguyen_Nhan','CSYT','Cong_Dan','UBND','Noi_Mat','Can_Bo','Giay_Bao_Tu','Ho_So_Khai_Tu','An_Tang') AND NOT ((TRIGGER_NAME='KT_Update_HoSo_BI' AND EVENT_OBJECT_TABLE='Ho_So_Khai_Tu' AND ACTION_TIMING='BEFORE' AND EVENT_MANIPULATION='INSERT') OR (TRIGGER_NAME='KT_Update_HoSo_BU' AND EVENT_OBJECT_TABLE='Ho_So_Khai_Tu' AND ACTION_TIMING='BEFORE' AND EVENT_MANIPULATION='UPDATE') OR (TRIGGER_NAME='KT_Update_GiayBaoTu_BU' AND EVENT_OBJECT_TABLE='Giay_Bao_Tu' AND ACTION_TIMING='BEFORE' AND EVENT_MANIPULATION='UPDATE') OR (TRIGGER_NAME='KT_Update_HoSo_AI' AND EVENT_OBJECT_TABLE='Ho_So_Khai_Tu' AND ACTION_TIMING='AFTER' AND EVENT_MANIPULATION='INSERT') OR (TRIGGER_NAME='KT_Update_HoSo_AU' AND EVENT_OBJECT_TABLE='Ho_So_Khai_Tu' AND ACTION_TIMING='AFTER' AND EVENT_MANIPULATION='UPDATE'))) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Có trigger tùy biến trên bảng gốc; cần xem xét, không tự thay thế.';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME IN ('Nguyen_Nhan','CSYT','Cong_Dan','UBND','Noi_Mat','Can_Bo','Giay_Bao_Tu','Ho_So_Khai_Tu','An_Tang') AND CONSTRAINT_TYPE='CHECK' AND NOT ((TABLE_NAME='Cong_Dan' AND CONSTRAINT_NAME='KT_Update_CHK_CongDan_CCCD') OR (TABLE_NAME='Cong_Dan' AND CONSTRAINT_NAME='KT_Update_CHK_CongDan_TrangThai') OR (TABLE_NAME='Can_Bo' AND CONSTRAINT_NAME='KT_Update_CHK_CanBo_CCCD') OR (TABLE_NAME='Giay_Bao_Tu' AND CONSTRAINT_NAME='KT_Update_CHK_NgayMat_NgayCap') OR (TABLE_NAME='Ho_So_Khai_Tu' AND CONSTRAINT_NAME='CHK_NguoiKhaiTu') OR (TABLE_NAME='Ho_So_Khai_Tu' AND CONSTRAINT_NAME='KT_Update_CHK_HoSo_TrangThai'))) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Có CHECK tùy biến trên bảng gốc; cần xem xét trước khi đổi kiểu.';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND CONSTRAINT_TYPE='FOREIGN KEY' AND CONSTRAINT_NAME='FK_CanBo_UBND' AND TABLE_NAME<>'Can_Bo') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tên FK đích đang được bảng khác sử dụng; cần xử lý riêng.';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND CONSTRAINT_TYPE='FOREIGN KEY' AND CONSTRAINT_NAME='FK_GBT_NguyenNhan' AND TABLE_NAME<>'Giay_Bao_Tu') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tên FK đích đang được bảng khác sử dụng; cần xử lý riêng.';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND CONSTRAINT_TYPE='FOREIGN KEY' AND CONSTRAINT_NAME='FK_GBT_NoiMat' AND TABLE_NAME<>'Giay_Bao_Tu') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tên FK đích đang được bảng khác sử dụng; cần xử lý riêng.';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND CONSTRAINT_TYPE='FOREIGN KEY' AND CONSTRAINT_NAME='FK_GBT_CSYT' AND TABLE_NAME<>'Giay_Bao_Tu') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tên FK đích đang được bảng khác sử dụng; cần xử lý riêng.';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND CONSTRAINT_TYPE='FOREIGN KEY' AND CONSTRAINT_NAME='FK_HoSo_GBT' AND TABLE_NAME<>'Ho_So_Khai_Tu') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tên FK đích đang được bảng khác sử dụng; cần xử lý riêng.';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND CONSTRAINT_TYPE='FOREIGN KEY' AND CONSTRAINT_NAME='FK_HoSo_NguoiMat' AND TABLE_NAME<>'Ho_So_Khai_Tu') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tên FK đích đang được bảng khác sử dụng; cần xử lý riêng.';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND CONSTRAINT_TYPE='FOREIGN KEY' AND CONSTRAINT_NAME='FK_HoSo_NguoiKhai' AND TABLE_NAME<>'Ho_So_Khai_Tu') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tên FK đích đang được bảng khác sử dụng; cần xử lý riêng.';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND CONSTRAINT_TYPE='FOREIGN KEY' AND CONSTRAINT_NAME='FK_HoSo_CanBo' AND TABLE_NAME<>'Ho_So_Khai_Tu') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tên FK đích đang được bảng khác sử dụng; cần xử lý riêng.';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND CONSTRAINT_TYPE='FOREIGN KEY' AND CONSTRAINT_NAME='FK_AnTang_HoSo' AND TABLE_NAME<>'An_Tang') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tên FK đích đang được bảng khác sử dụng; cần xử lý riêng.';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.STATISTICS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='Can_Bo' AND INDEX_NAME='UQ_CanBo_CCCD' GROUP BY INDEX_NAME HAVING COUNT(*)<>1 OR MAX(NON_UNIQUE)<>0 OR MAX(COLUMN_NAME='CCCD')<>1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Index UQ_CanBo_CCCD đã có nhưng khác định nghĩa đích.';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.STATISTICS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='Ho_So_Khai_Tu' AND INDEX_NAME='UQ_HoSo_NguoiMat' GROUP BY INDEX_NAME HAVING COUNT(*)<>1 OR MAX(NON_UNIQUE)<>0 OR MAX(COLUMN_NAME='CCCD_NgMat')<>1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Index UQ_HoSo_NguoiMat đã có nhưng khác định nghĩa đích.';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.STATISTICS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='Ho_So_Khai_Tu' AND INDEX_NAME='UQ_HoSo_GiayBaoTu' GROUP BY INDEX_NAME HAVING COUNT(*)<>1 OR MAX(NON_UNIQUE)<>0 OR MAX(COLUMN_NAME='SoGiayBaoTu')<>1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Index UQ_HoSo_GiayBaoTu đã có nhưng khác định nghĩa đích.';
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.STATISTICS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='An_Tang' AND INDEX_NAME='UQ_AnTang_HoSo' GROUP BY INDEX_NAME HAVING COUNT(*)<>1 OR MAX(NON_UNIQUE)<>0 OR MAX(COLUMN_NAME='SoGiayKhaiTu')<>1) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Index UQ_AnTang_HoSo đã có nhưng khác định nghĩa đích.';
  END IF;
  SELECT COUNT(*) INTO v_count FROM (
    SELECT TABLE_NAME FROM information_schema.STATISTICS WHERE TABLE_SCHEMA=DATABASE()
      AND INDEX_NAME='PRIMARY' AND TABLE_NAME IN ('Nguyen_Nhan','CSYT','Cong_Dan','UBND','Noi_Mat','Can_Bo','Giay_Bao_Tu','Ho_So_Khai_Tu','An_Tang')
    GROUP BY TABLE_NAME HAVING COUNT(*)=1 AND ((TABLE_NAME='Nguyen_Nhan' AND MAX(COLUMN_NAME='MaNguyenNhan')=1)
      OR (TABLE_NAME='CSYT' AND MAX(COLUMN_NAME='MaCSYT')=1)
      OR (TABLE_NAME='Cong_Dan' AND MAX(COLUMN_NAME='CCCD')=1)
      OR (TABLE_NAME='UBND' AND MAX(COLUMN_NAME='MaUBND')=1)
      OR (TABLE_NAME='Noi_Mat' AND MAX(COLUMN_NAME='MaXaPhuong')=1)
      OR (TABLE_NAME='Can_Bo' AND MAX(COLUMN_NAME='MaCanBo')=1)
      OR (TABLE_NAME='Giay_Bao_Tu' AND MAX(COLUMN_NAME='SoGiayBaoTu')=1)
      OR (TABLE_NAME='Ho_So_Khai_Tu' AND MAX(COLUMN_NAME='SoGiayKhaiTu')=1)
      OR (TABLE_NAME='An_Tang' AND MAX(COLUMN_NAME='MaAnTang')=1))
  ) valid_primary;
  IF v_count<>9 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Khóa chính khác schema gốc; không tự thay cấu trúc tùy biến.';
  END IF;

END$$
DROP PROCEDURE IF EXISTS KT_Update_ApDung$$
CREATE PROCEDURE KT_Update_ApDung()
BEGIN
  DECLARE v_major INT;
  DECLARE v_minor INT;
  DECLARE v_patch INT;
  DECLARE v_count INT DEFAULT 0;
  DECLARE v_done BOOLEAN DEFAULT FALSE;
  DECLARE v_table VARCHAR(64);
  DECLARE v_constraint VARCHAR(64);
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done=TRUE;

  fk_loop: LOOP
    SET v_done=FALSE;
    SELECT TABLE_NAME,CONSTRAINT_NAME INTO v_table,v_constraint FROM information_schema.KEY_COLUMN_USAGE
    WHERE CONSTRAINT_SCHEMA=DATABASE() AND REFERENCED_TABLE_NAME IS NOT NULL AND TABLE_NAME IN ('Nguyen_Nhan','CSYT','Cong_Dan','UBND','Noi_Mat','Can_Bo','Giay_Bao_Tu','Ho_So_Khai_Tu','An_Tang')
    ORDER BY TABLE_NAME,CONSTRAINT_NAME LIMIT 1;
    IF v_done THEN LEAVE fk_loop; END IF;
    SET @kt_update_sql=CONCAT('ALTER TABLE `',REPLACE(v_table,'`','``'),'` DROP FOREIGN KEY `',REPLACE(v_constraint,'`','``'),'`');
    PREPARE kt_update_statement FROM @kt_update_sql;
    EXECUTE kt_update_statement;
    DEALLOCATE PREPARE kt_update_statement;
  END LOOP;
  check_loop: LOOP
    SET v_done=FALSE;
    SELECT TABLE_NAME,CONSTRAINT_NAME INTO v_table,v_constraint FROM information_schema.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_SCHEMA=DATABASE() AND CONSTRAINT_TYPE='CHECK' AND (
      (TABLE_NAME='Cong_Dan' AND CONSTRAINT_NAME='KT_Update_CHK_CongDan_CCCD')
      OR (TABLE_NAME='Cong_Dan' AND CONSTRAINT_NAME='KT_Update_CHK_CongDan_TrangThai')
      OR (TABLE_NAME='Can_Bo' AND CONSTRAINT_NAME='KT_Update_CHK_CanBo_CCCD')
      OR (TABLE_NAME='Giay_Bao_Tu' AND CONSTRAINT_NAME='KT_Update_CHK_NgayMat_NgayCap')
      OR (TABLE_NAME='Ho_So_Khai_Tu' AND CONSTRAINT_NAME='CHK_NguoiKhaiTu')
      OR (TABLE_NAME='Ho_So_Khai_Tu' AND CONSTRAINT_NAME='KT_Update_CHK_HoSo_TrangThai'))
    ORDER BY TABLE_NAME,CONSTRAINT_NAME LIMIT 1;
    IF v_done THEN LEAVE check_loop; END IF;
    SET @kt_update_sql=CONCAT('ALTER TABLE `',REPLACE(v_table,'`','``'),'` DROP CHECK `',REPLACE(v_constraint,'`','``'),'`');
    PREPARE kt_update_statement FROM @kt_update_sql;
    EXECUTE kt_update_statement;
    DEALLOCATE PREPARE kt_update_statement;
  END LOOP;

  -- Chi doi nhan da biet. Khong sua backlog Da mat tu ho so cu.
  UPDATE Cong_Dan SET TrangThai='Còn sống' WHERE BINARY TrangThai=BINARY 'Đang sống';
  UPDATE Ho_So_Khai_Tu SET TrangThaiHoSo='Chờ xử lý'
    WHERE BINARY TrangThaiHoSo IN (BINARY 'Đã tiếp nhận',BINARY 'Đang xử lý',BINARY 'Chờ duyệt');
  UPDATE Ho_So_Khai_Tu SET TrangThaiHoSo='Đã duyệt' WHERE BINARY TrangThaiHoSo=BINARY 'Đã hoàn tất';

  ALTER TABLE Nguyen_Nhan CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    MODIFY MaNguyenNhan VARCHAR(20) NOT NULL,
    MODIFY TenNguyenNhan VARCHAR(150) NOT NULL;
  ALTER TABLE CSYT CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    MODIFY MaCSYT VARCHAR(20) NOT NULL,
    MODIFY TenCSYT VARCHAR(150) NOT NULL,
    MODIFY DiaChi VARCHAR(255) NOT NULL,
    MODIFY SDT VARCHAR(15) NULL;
  ALTER TABLE Cong_Dan CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    MODIFY CCCD CHAR(12) NOT NULL,
    MODIFY HoTen VARCHAR(100) NOT NULL,
    MODIFY NgaySinh DATE NOT NULL,
    MODIFY GioiTinh ENUM('Nam','Nữ','Khác') NOT NULL,
    MODIFY QueQuan VARCHAR(200) NOT NULL,
    MODIFY DanToc VARCHAR(50) NULL DEFAULT 'Kinh',
    MODIFY SDT VARCHAR(15) NULL,
    MODIFY TrangThai VARCHAR(30) NOT NULL DEFAULT 'Còn sống';
  ALTER TABLE UBND CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    MODIFY MaUBND VARCHAR(20) NOT NULL,
    MODIFY TenUBND VARCHAR(150) NOT NULL,
    MODIFY CapHanhChinh VARCHAR(50) NOT NULL DEFAULT 'Phường',
    MODIFY DiaChi VARCHAR(255) NOT NULL,
    MODIFY SDT VARCHAR(15) NULL;
  ALTER TABLE Noi_Mat CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    MODIFY MaXaPhuong VARCHAR(20) NOT NULL,
    MODIFY TenXaPhuong VARCHAR(100) NOT NULL;
  ALTER TABLE Can_Bo CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    MODIFY MaCanBo VARCHAR(20) NOT NULL,
    MODIFY CCCD CHAR(12) NOT NULL,
    MODIFY HoTen VARCHAR(100) NOT NULL,
    MODIFY ChucVu VARCHAR(100) NOT NULL,
    MODIFY SDT VARCHAR(15) NULL,
    MODIFY MaUBND VARCHAR(20) NOT NULL;
  ALTER TABLE Giay_Bao_Tu CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    MODIFY SoGiayBaoTu VARCHAR(30) NOT NULL,
    MODIFY NgayCap DATE NOT NULL,
    MODIFY NgayGioMat DATETIME NOT NULL,
    MODIFY NoiMatChiTiet VARCHAR(255) NOT NULL,
    MODIFY MaNguyenNhan VARCHAR(20) NOT NULL,
    MODIFY MaXaPhuong VARCHAR(20) NOT NULL,
    MODIFY MaCSYT VARCHAR(20) NOT NULL;
  -- Tach khoi CONVERT: MySQL co the rut TEXT thanh TINYTEXT neu doi cung lenh.
  ALTER TABLE Giay_Bao_Tu MODIFY MoTaNguyenNhan TEXT NULL;
  ALTER TABLE Ho_So_Khai_Tu CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    MODIFY SoGiayKhaiTu VARCHAR(30) NOT NULL,
    MODIFY NgayDangKi DATE NOT NULL,
    MODIFY QuanHe VARCHAR(50) NOT NULL,
    MODIFY TrangThaiHoSo VARCHAR(50) NOT NULL DEFAULT 'Đã duyệt',
    MODIFY SoGiayBaoTu VARCHAR(30) NOT NULL,
    MODIFY CCCD_NgMat CHAR(12) NOT NULL,
    MODIFY CCCD_NgKhaiTu CHAR(12) NOT NULL,
    MODIFY MaCanBoTiepNhan VARCHAR(20) NOT NULL;
  ALTER TABLE An_Tang CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    MODIFY MaAnTang VARCHAR(30) NOT NULL,
    MODIFY HinhThuc VARCHAR(50) NOT NULL,
    MODIFY TenNghiaTrang VARCHAR(150) NOT NULL,
    MODIFY NgayAnTang DATE NOT NULL,
    MODIFY SoGiayKhaiTu VARCHAR(30) NOT NULL;
  CALL KT_Update_EnsureUnique('Can_Bo','CCCD','UQ_CanBo_CCCD');
  CALL KT_Update_EnsureUnique('Ho_So_Khai_Tu','CCCD_NgMat','UQ_HoSo_NguoiMat');
  CALL KT_Update_EnsureUnique('Ho_So_Khai_Tu','SoGiayBaoTu','UQ_HoSo_GiayBaoTu');
  CALL KT_Update_EnsureUnique('An_Tang','SoGiayKhaiTu','UQ_AnTang_HoSo');
  ALTER TABLE Cong_Dan ADD CONSTRAINT KT_Update_CHK_CongDan_CCCD CHECK (REGEXP_LIKE(CCCD, '^[0-9]{12}$', 'c'));
  ALTER TABLE Cong_Dan ADD CONSTRAINT KT_Update_CHK_CongDan_TrangThai CHECK (TrangThai IN ('Còn sống','Đã mất'));
  ALTER TABLE Can_Bo ADD CONSTRAINT KT_Update_CHK_CanBo_CCCD CHECK (REGEXP_LIKE(CCCD, '^[0-9]{12}$', 'c'));
  ALTER TABLE Giay_Bao_Tu ADD CONSTRAINT KT_Update_CHK_NgayMat_NgayCap CHECK (DATE(NgayGioMat) <= NgayCap);
  ALTER TABLE Ho_So_Khai_Tu ADD CONSTRAINT CHK_NguoiKhaiTu CHECK (CCCD_NgKhaiTu <> CCCD_NgMat);
  ALTER TABLE Ho_So_Khai_Tu ADD CONSTRAINT KT_Update_CHK_HoSo_TrangThai CHECK (TrangThaiHoSo IN ('Đã duyệt','Chờ xử lý','Từ chối'));
  -- Bo qua ON UPDATE/DELETE giu RESTRICT/NO ACTION mac dinh, khong CASCADE.
  ALTER TABLE Can_Bo ADD CONSTRAINT FK_CanBo_UBND FOREIGN KEY (MaUBND) REFERENCES UBND(MaUBND);
  ALTER TABLE Giay_Bao_Tu ADD CONSTRAINT FK_GBT_NguyenNhan FOREIGN KEY (MaNguyenNhan) REFERENCES Nguyen_Nhan(MaNguyenNhan);
  ALTER TABLE Giay_Bao_Tu ADD CONSTRAINT FK_GBT_NoiMat FOREIGN KEY (MaXaPhuong) REFERENCES Noi_Mat(MaXaPhuong);
  ALTER TABLE Giay_Bao_Tu ADD CONSTRAINT FK_GBT_CSYT FOREIGN KEY (MaCSYT) REFERENCES CSYT(MaCSYT);
  ALTER TABLE Ho_So_Khai_Tu ADD CONSTRAINT FK_HoSo_GBT FOREIGN KEY (SoGiayBaoTu) REFERENCES Giay_Bao_Tu(SoGiayBaoTu);
  ALTER TABLE Ho_So_Khai_Tu ADD CONSTRAINT FK_HoSo_NguoiMat FOREIGN KEY (CCCD_NgMat) REFERENCES Cong_Dan(CCCD);
  ALTER TABLE Ho_So_Khai_Tu ADD CONSTRAINT FK_HoSo_NguoiKhai FOREIGN KEY (CCCD_NgKhaiTu) REFERENCES Cong_Dan(CCCD);
  ALTER TABLE Ho_So_Khai_Tu ADD CONSTRAINT FK_HoSo_CanBo FOREIGN KEY (MaCanBoTiepNhan) REFERENCES Can_Bo(MaCanBo);
  ALTER TABLE An_Tang ADD CONSTRAINT FK_AnTang_HoSo FOREIGN KEY (SoGiayKhaiTu) REFERENCES Ho_So_Khai_Tu(SoGiayKhaiTu);
END$$
CALL KT_Update_Preflight()$$
-- PREFLIGHT DAT. Cac lenh DROP/CREATE TRIGGER tinh nam ngoai procedure.
DROP TRIGGER IF EXISTS KT_Update_HoSo_BI$$
DROP TRIGGER IF EXISTS KT_Update_HoSo_BU$$
DROP TRIGGER IF EXISTS KT_Update_GiayBaoTu_BU$$
DROP TRIGGER IF EXISTS KT_Update_HoSo_AI$$
DROP TRIGGER IF EXISTS KT_Update_HoSo_AU$$
CALL KT_Update_ApDung()$$
DROP PROCEDURE KT_Update_Preflight$$

DROP PROCEDURE KT_Update_ApDung$$
DROP PROCEDURE KT_Update_EnsureUnique$$

CREATE TRIGGER KT_Update_HoSo_BI BEFORE INSERT ON Ho_So_Khai_Tu
FOR EACH ROW
BEGIN
  DECLARE v_ngay_cap DATE DEFAULT NULL;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_ngay_cap = NULL;
  SELECT NgayCap INTO v_ngay_cap FROM Giay_Bao_Tu
    WHERE SoGiayBaoTu = NEW.SoGiayBaoTu FOR SHARE;
  IF v_ngay_cap > NEW.NgayDangKi THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ngay cap giay bao tu phai truoc hoac bang ngay dang ky';
  END IF;
END$$

CREATE TRIGGER KT_Update_HoSo_BU BEFORE UPDATE ON Ho_So_Khai_Tu
FOR EACH ROW
BEGIN
  DECLARE v_ngay_cap DATE DEFAULT NULL;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_ngay_cap = NULL;
  SELECT NgayCap INTO v_ngay_cap FROM Giay_Bao_Tu
    WHERE SoGiayBaoTu = NEW.SoGiayBaoTu FOR SHARE;
  IF v_ngay_cap > NEW.NgayDangKi THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ngay cap giay bao tu phai truoc hoac bang ngay dang ky';
  END IF;
END$$

CREATE TRIGGER KT_Update_GiayBaoTu_BU BEFORE UPDATE ON Giay_Bao_Tu
FOR EACH ROW
BEGIN
  DECLARE v_ngay_dang_ky DATE DEFAULT NULL;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_ngay_dang_ky = NULL;
  SELECT NgayDangKi INTO v_ngay_dang_ky FROM Ho_So_Khai_Tu
    WHERE SoGiayBaoTu = OLD.SoGiayBaoTu
    ORDER BY NgayDangKi LIMIT 1 FOR UPDATE;
  IF v_ngay_dang_ky IS NOT NULL AND NEW.NgayCap > v_ngay_dang_ky THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ngay cap moi vuot ngay dang ky cua ho so da lien ket';
  END IF;
END$$

CREATE TRIGGER KT_Update_HoSo_AI AFTER INSERT ON Ho_So_Khai_Tu
FOR EACH ROW
BEGIN
  IF NEW.TrangThaiHoSo <> 'Từ chối' THEN
    UPDATE Cong_Dan SET TrangThai = 'Đã mất' WHERE CCCD = NEW.CCCD_NgMat;
  END IF;
END$$

CREATE TRIGGER KT_Update_HoSo_AU AFTER UPDATE ON Ho_So_Khai_Tu
FOR EACH ROW
BEGIN
  IF NEW.TrangThaiHoSo <> 'Từ chối' THEN
    UPDATE Cong_Dan SET TrangThai = 'Đã mất' WHERE CCCD = NEW.CCCD_NgMat;
  END IF;
END$$
DELIMITER ;
SELECT VERSION() AS PhienBanMySQL;
-- Chi thong bao backlog; chi ho so KHONG tu choi moi duoc tinh o day.
SELECT COUNT(DISTINCT c.CCCD) AS SoCongDanCoHoSoHopLeNhungChuaDanhDauDaMat
FROM Cong_Dan c JOIN Ho_So_Khai_Tu h ON h.CCCD_NgMat=c.CCCD
WHERE h.TrangThaiHoSo<>'Từ chối' AND c.TrangThai<>'Đã mất';
SELECT 'Đã nâng cấp 9 bảng, chuẩn hóa nhãn đã biết và cài 5 trigger; không tự sửa backlog sinh tử.' AS KetQua;
