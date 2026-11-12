-- =====================================================================
-- HỆ THỐNG QUẢN LÝ ĐĂNG KÝ KHAI TỬ  (MySQL 8+)
-- =====================================================================
DROP DATABASE IF EXISTS quan_li_khai_tu;

CREATE DATABASE quan_li_khai_tu
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE quan_li_khai_tu;
SET NAMES utf8mb4;

-- 1. Bảng nơi mất
CREATE TABLE Noi_Mat (
    MaXaPhuong VARCHAR(20) PRIMARY KEY,
    TenXaPhuong VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

-- 2. Bảng nguyên nhân
CREATE TABLE Nguyen_Nhan (
    MaNguyenNhan VARCHAR(20) PRIMARY KEY,
    TenNguyenNhan VARCHAR(150) NOT NULL
) ENGINE=InnoDB;

-- 3. Bảng cơ sở y tế
CREATE TABLE CSYT (
    MaCSYT VARCHAR(20) PRIMARY KEY,
    TenCSYT VARCHAR(150) NOT NULL,
    DiaChi VARCHAR(255) NOT NULL,
    SDT VARCHAR(15) NOT NULL
) ENGINE=InnoDB;

-- 4. Bảng UBND
CREATE TABLE UBND (
    MaUBND VARCHAR(20) PRIMARY KEY,
    TenUBND VARCHAR(150) NOT NULL,
    CapHanhChinh VARCHAR(50) NOT NULL,
    DiaChi VARCHAR(255) NOT NULL,
    SDT VARCHAR(15) NOT NULL,
    CHECK (CapHanhChinh IN ('Xã', 'Phường'))
) ENGINE=InnoDB;

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
) ENGINE=InnoDB;

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
) ENGINE=InnoDB;

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
) ENGINE=InnoDB;

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
) ENGINE=InnoDB;

-- 9. Bảng an táng
CREATE TABLE An_Tang (
    MaAnTang VARCHAR(30) PRIMARY KEY,
    SoGiayKhaiTu VARCHAR(20) NOT NULL UNIQUE,
    HinhThuc VARCHAR(50) NOT NULL,
    TenNghiaTrang VARCHAR(150) NOT NULL,
    NgayAnTang DATE NOT NULL,

    FOREIGN KEY (SoGiayKhaiTu) REFERENCES Ho_So_Khai_Tu(SoGiayKhaiTu),
    CHECK (HinhThuc IN ('Hỏa táng', 'Địa táng'))
) ENGINE=InnoDB;
