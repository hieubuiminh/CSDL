-- KHỞI TẠO CSDL MỚI, MySQL >= 8.0.16. Không dùng file này để nâng cấp CSDL đã có.
-- CSDL đang có: sao lưu rồi chạy cap_nhat_rang_buoc.sql theo hướng dẫn trong docs.
-- Hiệu chỉnh theo bao-cao-updated_removed.pdf; xem docs/DOI_CHIEU_BAO_CAO_SQL.md.
-- Không DROP DATABASE/TABLE hoặc xóa dữ liệu.
SET NAMES utf8mb4;
CREATE DATABASE IF NOT EXISTS quan_ly_dang_ky_khai_tu
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE quan_ly_dang_ky_khai_tu;

CREATE TABLE Nguyen_Nhan (
  MaNguyenNhan VARCHAR(20) PRIMARY KEY,
  TenNguyenNhan VARCHAR(150) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE CSYT (
  MaCSYT VARCHAR(20) PRIMARY KEY,
  TenCSYT VARCHAR(150) NOT NULL,
  DiaChi VARCHAR(255) NOT NULL,
  SDT VARCHAR(15) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Cong_Dan (
  CCCD CHAR(12) PRIMARY KEY,
  HoTen VARCHAR(100) NOT NULL,
  NgaySinh DATE NOT NULL,
  GioiTinh ENUM('Nam','Nữ','Khác') NOT NULL,
  QueQuan VARCHAR(200) NOT NULL,
  DanToc VARCHAR(50) NULL DEFAULT 'Kinh',
  SDT VARCHAR(15) NULL,
  TrangThai VARCHAR(30) NOT NULL DEFAULT 'Còn sống',
  CONSTRAINT KT_Update_CHK_CongDan_CCCD CHECK (REGEXP_LIKE(CCCD, '^[0-9]{12}$', 'c')),
  CONSTRAINT KT_Update_CHK_CongDan_TrangThai CHECK (TrangThai IN ('Còn sống','Đã mất'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE UBND (
  MaUBND VARCHAR(20) PRIMARY KEY,
  TenUBND VARCHAR(150) NOT NULL,
  CapHanhChinh VARCHAR(50) NOT NULL DEFAULT 'Phường',
  DiaChi VARCHAR(255) NOT NULL,
  SDT VARCHAR(15) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Noi_Mat (
  MaXaPhuong VARCHAR(20) PRIMARY KEY,
  TenXaPhuong VARCHAR(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Can_Bo (
  MaCanBo VARCHAR(20) PRIMARY KEY,
  CCCD CHAR(12) NOT NULL,
  HoTen VARCHAR(100) NOT NULL,
  ChucVu VARCHAR(100) NOT NULL,
  SDT VARCHAR(15) NULL,
  MaUBND VARCHAR(20) NOT NULL,
  CONSTRAINT UQ_CanBo_CCCD UNIQUE (CCCD),
  CONSTRAINT KT_Update_CHK_CanBo_CCCD CHECK (REGEXP_LIKE(CCCD, '^[0-9]{12}$', 'c')),
  CONSTRAINT FK_CanBo_UBND FOREIGN KEY (MaUBND) REFERENCES UBND(MaUBND)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Giay_Bao_Tu (
  SoGiayBaoTu VARCHAR(30) PRIMARY KEY,
  NgayCap DATE NOT NULL,
  NgayGioMat DATETIME NOT NULL,
  NoiMatChiTiet VARCHAR(255) NOT NULL,
  MoTaNguyenNhan TEXT NULL,
  MaNguyenNhan VARCHAR(20) NOT NULL,
  MaXaPhuong VARCHAR(20) NOT NULL,
  MaCSYT VARCHAR(20) NOT NULL,
  CONSTRAINT KT_Update_CHK_NgayMat_NgayCap CHECK (DATE(NgayGioMat) <= NgayCap),
  CONSTRAINT FK_GBT_NguyenNhan FOREIGN KEY (MaNguyenNhan) REFERENCES Nguyen_Nhan(MaNguyenNhan),
  CONSTRAINT FK_GBT_NoiMat FOREIGN KEY (MaXaPhuong) REFERENCES Noi_Mat(MaXaPhuong),
  CONSTRAINT FK_GBT_CSYT FOREIGN KEY (MaCSYT) REFERENCES CSYT(MaCSYT)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Ho_So_Khai_Tu (
  SoGiayKhaiTu VARCHAR(30) PRIMARY KEY,
  NgayDangKi DATE NOT NULL,
  QuanHe VARCHAR(50) NOT NULL,
  TrangThaiHoSo VARCHAR(50) NOT NULL DEFAULT 'Đã duyệt',
  SoGiayBaoTu VARCHAR(30) NOT NULL,
  CCCD_NgMat CHAR(12) NOT NULL,
  CCCD_NgKhaiTu CHAR(12) NOT NULL,
  MaCanBoTiepNhan VARCHAR(20) NOT NULL,
  CONSTRAINT UQ_HoSo_NguoiMat UNIQUE (CCCD_NgMat),
  CONSTRAINT UQ_HoSo_GiayBaoTu UNIQUE (SoGiayBaoTu),
  CONSTRAINT CHK_NguoiKhaiTu CHECK (CCCD_NgKhaiTu <> CCCD_NgMat),
  CONSTRAINT KT_Update_CHK_HoSo_TrangThai CHECK (TrangThaiHoSo IN ('Đã duyệt','Chờ xử lý','Từ chối')),
  CONSTRAINT FK_HoSo_GBT FOREIGN KEY (SoGiayBaoTu) REFERENCES Giay_Bao_Tu(SoGiayBaoTu),
  CONSTRAINT FK_HoSo_NguoiMat FOREIGN KEY (CCCD_NgMat) REFERENCES Cong_Dan(CCCD),
  CONSTRAINT FK_HoSo_NguoiKhai FOREIGN KEY (CCCD_NgKhaiTu) REFERENCES Cong_Dan(CCCD),
  CONSTRAINT FK_HoSo_CanBo FOREIGN KEY (MaCanBoTiepNhan) REFERENCES Can_Bo(MaCanBo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE An_Tang (
  MaAnTang VARCHAR(30) PRIMARY KEY,
  HinhThuc VARCHAR(50) NOT NULL,
  -- Bao gồm tên đài hóa thân; giữ tên cột để tương thích ứng dụng hiện tại.
  TenNghiaTrang VARCHAR(150) NOT NULL,
  -- Phần bổ sung của ứng dụng, không có trong bảng 2.9 của báo cáo.
  NgayAnTang DATE NOT NULL,
  SoGiayKhaiTu VARCHAR(30) NOT NULL,
  CONSTRAINT UQ_AnTang_HoSo UNIQUE (SoGiayKhaiTu),
  CONSTRAINT FK_AnTang_HoSo FOREIGN KEY (SoGiayKhaiTu) REFERENCES Ho_So_Khai_Tu(SoGiayKhaiTu)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- CHECK kiểm tra dữ liệu trong một hàng; thứ tự ngày giữa hai bảng được bảo vệ
-- ở cả phía hồ sơ và giấy báo tử. Khóa hàng tránh đọc phiên bản dữ liệu cũ.
DELIMITER $$
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

-- Không tự chuyển công dân về Còn sống khi từ chối/xóa/sửa hồ sơ.
-- Việc đính chính sinh tử cần được xác minh riêng.
