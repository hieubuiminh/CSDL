-- =====================================================================
-- HỆ THỐNG QUẢN LÝ ĐĂNG KÝ KHAI TỬ  (MySQL 8+)
-- =====================================================================
-- Khởi tạo mới, giữ CSDL đang có; không DROP DATABASE.
CREATE DATABASE IF NOT EXISTS quan_li_khai_tu
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE quan_li_khai_tu;
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 1. Bảng nơi mất
CREATE TABLE Noi_Mat (
    MaXaPhuong VARCHAR(20) PRIMARY KEY,
    TenXaPhuong VARCHAR(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Bảng nguyên nhân
CREATE TABLE Nguyen_Nhan (
    MaNguyenNhan VARCHAR(20) PRIMARY KEY,
    TenNguyenNhan VARCHAR(150) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Bảng cơ sở y tế
CREATE TABLE CSYT (
    MaCSYT VARCHAR(20) PRIMARY KEY,
    TenCSYT VARCHAR(150) NOT NULL,
    DiaChi VARCHAR(255) NOT NULL,
    SDT VARCHAR(15) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Bảng UBND
CREATE TABLE UBND (
    MaUBND VARCHAR(20) PRIMARY KEY,
    TenUBND VARCHAR(150) NOT NULL,
    CapHanhChinh VARCHAR(50) NOT NULL,
    DiaChi VARCHAR(255) NOT NULL,
    SDT VARCHAR(15) NOT NULL,
    CHECK (CapHanhChinh IN ('Xã', 'Phường'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Bảng công dân
CREATE TABLE Cong_Dan (
    CCCD CHAR(12) PRIMARY KEY,
    HoTen VARCHAR(100) NOT NULL,
    NgaySinh DATE NOT NULL,
    GioiTinh ENUM('Nam', 'Nữ', 'Khác') NOT NULL,
    QueQuan VARCHAR(255),
    DanToc VARCHAR(50) DEFAULT 'Kinh',
    SDT VARCHAR(15),
    TrangThai VARCHAR(20) NOT NULL DEFAULT 'Còn sống',

    CHECK (CCCD REGEXP '^[0-9]{12}$'),
    CHECK (TrangThai IN ('Còn sống', 'Đã mất'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. Bảng cán bộ
CREATE TABLE Can_Bo (
    MaCanBo VARCHAR(20) PRIMARY KEY,
    CCCD CHAR(12) NOT NULL UNIQUE,
    HoTen VARCHAR(100) NOT NULL,
    ChucVu VARCHAR(100) NOT NULL,
    SDT VARCHAR(15) NOT NULL,
    MaUBND VARCHAR(20) NOT NULL,

    FOREIGN KEY (MaUBND) REFERENCES UBND(MaUBND),
    CHECK (CCCD REGEXP '^[0-9]{12}$')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. Bảng giấy báo tử
CREATE TABLE Giay_Bao_Tu (
    SoGiayBaoTu VARCHAR(20) PRIMARY KEY,
    NgayCap DATE NOT NULL,
    NgayGioMat DATETIME NOT NULL,
    NoiMatChiTiet VARCHAR(255),
    MoTaNguyenNhan TEXT,
    CCCD_NgMat CHAR(12) NOT NULL UNIQUE,
    MaCSYT VARCHAR(20) NOT NULL,
    MaNguyenNhan VARCHAR(20) NOT NULL,
    MaXaPhuong VARCHAR(20) NOT NULL,

    FOREIGN KEY (CCCD_NgMat) REFERENCES Cong_Dan(CCCD),
    FOREIGN KEY (MaCSYT) REFERENCES CSYT(MaCSYT),
    FOREIGN KEY (MaNguyenNhan) REFERENCES Nguyen_Nhan(MaNguyenNhan),
    FOREIGN KEY (MaXaPhuong) REFERENCES Noi_Mat(MaXaPhuong),

    CHECK (DATE(NgayGioMat) <= NgayCap)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8. Bảng hồ sơ khai tử
CREATE TABLE Ho_So_Khai_Tu (
    SoGiayKhaiTu VARCHAR(20) PRIMARY KEY,
    SoGiayBaoTu VARCHAR(20) NOT NULL UNIQUE,
    NgayDangKi DATE NOT NULL,
    CCCD_NgKhaiTu CHAR(12) NOT NULL,
    QuanHe VARCHAR(50) NOT NULL,
    TrangThaiHoSo VARCHAR(30) NOT NULL DEFAULT 'Chờ xử lý',
    MaCanBoTiepNhan VARCHAR(20) NOT NULL,

    FOREIGN KEY (SoGiayBaoTu) REFERENCES Giay_Bao_Tu(SoGiayBaoTu),
    FOREIGN KEY (CCCD_NgKhaiTu) REFERENCES Cong_Dan(CCCD),
    FOREIGN KEY (MaCanBoTiepNhan) REFERENCES Can_Bo(MaCanBo),

    CHECK (TrangThaiHoSo IN ('Chờ xử lý', 'Đã duyệt', 'Từ chối'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 9. Bảng an táng
CREATE TABLE An_Tang (
    MaAnTang VARCHAR(30) PRIMARY KEY,
    SoGiayKhaiTu VARCHAR(20) NOT NULL UNIQUE,
    HinhThuc VARCHAR(50) NOT NULL,
    TenNghiaTrang VARCHAR(150) NOT NULL,
    NgayAnTang DATE NOT NULL,

    FOREIGN KEY (SoGiayKhaiTu) REFERENCES Ho_So_Khai_Tu(SoGiayKhaiTu),
    CHECK (HinhThuc IN ('Hỏa táng', 'Địa táng'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bổ sung quy tắc liên bảng cho MySQL >= 8.0.16, không đổi mô hình bảng mới.
-- Người mất chỉ nằm ở Giay_Bao_Tu.CCCD_NgMat; hồ sơ liên kết qua số giấy báo tử.
DELIMITER $$
CREATE TRIGGER KT_Moi_HoSo_BI BEFORE INSERT ON Ho_So_Khai_Tu
FOR EACH ROW
BEGIN
  DECLARE v_ngay_cap DATE DEFAULT NULL;
  DECLARE v_nguoi_mat CHAR(12) DEFAULT NULL;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_ngay_cap = NULL;
  SELECT NgayCap, CCCD_NgMat INTO v_ngay_cap, v_nguoi_mat
  FROM Giay_Bao_Tu WHERE SoGiayBaoTu = NEW.SoGiayBaoTu FOR SHARE;
  IF v_nguoi_mat = NEW.CCCD_NgKhaiTu THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nguoi di khai tu phai khac nguoi mat';
  END IF;
  IF v_ngay_cap > NEW.NgayDangKi THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ngay cap giay bao tu phai truoc hoac bang ngay dang ky';
  END IF;
END$$

CREATE TRIGGER KT_Moi_HoSo_BU BEFORE UPDATE ON Ho_So_Khai_Tu
FOR EACH ROW
BEGIN
  DECLARE v_ngay_cap DATE DEFAULT NULL;
  DECLARE v_nguoi_mat CHAR(12) DEFAULT NULL;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_ngay_cap = NULL;
  SELECT NgayCap, CCCD_NgMat INTO v_ngay_cap, v_nguoi_mat
  FROM Giay_Bao_Tu WHERE SoGiayBaoTu = NEW.SoGiayBaoTu FOR SHARE;
  IF v_nguoi_mat = NEW.CCCD_NgKhaiTu THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nguoi di khai tu phai khac nguoi mat';
  END IF;
  IF v_ngay_cap > NEW.NgayDangKi THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ngay cap giay bao tu phai truoc hoac bang ngay dang ky';
  END IF;
END$$

CREATE TRIGGER KT_Moi_GiayBaoTu_BU BEFORE UPDATE ON Giay_Bao_Tu
FOR EACH ROW
BEGIN
  DECLARE v_ngay_dang_ky DATE DEFAULT NULL;
  DECLARE v_nguoi_khai CHAR(12) DEFAULT NULL;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_ngay_dang_ky = NULL;
  SELECT NgayDangKi, CCCD_NgKhaiTu INTO v_ngay_dang_ky, v_nguoi_khai
  FROM Ho_So_Khai_Tu WHERE SoGiayBaoTu = OLD.SoGiayBaoTu FOR UPDATE;
  IF v_ngay_dang_ky IS NOT NULL AND NEW.NgayCap > v_ngay_dang_ky THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ngay cap moi vuot ngay dang ky cua ho so da lien ket';
  END IF;
  IF NEW.CCCD_NgMat = v_nguoi_khai THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nguoi di khai tu phai khac nguoi mat';
  END IF;
END$$

CREATE TRIGGER KT_Moi_HoSo_AI AFTER INSERT ON Ho_So_Khai_Tu
FOR EACH ROW
BEGIN
  DECLARE v_nguoi_mat CHAR(12) DEFAULT NULL;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_nguoi_mat = NULL;
  IF NEW.TrangThaiHoSo <> 'Từ chối' THEN
    SELECT CCCD_NgMat INTO v_nguoi_mat FROM Giay_Bao_Tu
    WHERE SoGiayBaoTu = NEW.SoGiayBaoTu FOR SHARE;
    UPDATE Cong_Dan SET TrangThai = 'Đã mất' WHERE CCCD = v_nguoi_mat;
  END IF;
END$$

CREATE TRIGGER KT_Moi_HoSo_AU AFTER UPDATE ON Ho_So_Khai_Tu
FOR EACH ROW
BEGIN
  DECLARE v_nguoi_mat CHAR(12) DEFAULT NULL;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_nguoi_mat = NULL;
  IF NEW.TrangThaiHoSo <> 'Từ chối' THEN
    SELECT CCCD_NgMat INTO v_nguoi_mat FROM Giay_Bao_Tu
    WHERE SoGiayBaoTu = NEW.SoGiayBaoTu FOR SHARE;
    UPDATE Cong_Dan SET TrangThai = 'Đã mất' WHERE CCCD = v_nguoi_mat;
  END IF;
END$$

CREATE TRIGGER KT_Moi_GiayBaoTu_AU AFTER UPDATE ON Giay_Bao_Tu
FOR EACH ROW
BEGIN
  DECLARE v_trang_thai VARCHAR(30) DEFAULT NULL;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_trang_thai = NULL;
  SELECT TrangThaiHoSo INTO v_trang_thai FROM Ho_So_Khai_Tu
  WHERE SoGiayBaoTu = NEW.SoGiayBaoTu FOR SHARE;
  IF v_trang_thai IS NOT NULL AND v_trang_thai <> 'Từ chối' THEN
    UPDATE Cong_Dan SET TrangThai = 'Đã mất' WHERE CCCD = NEW.CCCD_NgMat;
  END IF;
END$$
DELIMITER ;

-- Không tự chuyển người cũ về Còn sống khi đổi hoặc từ chối hồ sơ.
-- Nạp database/du_lieu_mau.sql riêng SAU file tạo bảng này, đúng một lần.

