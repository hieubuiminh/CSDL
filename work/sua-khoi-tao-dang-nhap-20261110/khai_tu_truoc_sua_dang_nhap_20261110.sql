-- MySQL dump 10.13  Distrib 8.0.46, for Linux (x86_64)
--
-- Host: localhost    Database: quan_li_khai_tu
-- ------------------------------------------------------
-- Server version	8.0.46

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `quan_li_khai_tu`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `quan_li_khai_tu` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `quan_li_khai_tu`;

--
-- Table structure for table `An_Tang`
--

DROP TABLE IF EXISTS `An_Tang`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `An_Tang` (
  `MaAnTang` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `SoGiayKhaiTu` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `HinhThuc` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `TenNghiaTrang` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `NgayAnTang` date NOT NULL,
  PRIMARY KEY (`MaAnTang`),
  UNIQUE KEY `SoGiayKhaiTu` (`SoGiayKhaiTu`),
  CONSTRAINT `An_Tang_ibfk_1` FOREIGN KEY (`SoGiayKhaiTu`) REFERENCES `Ho_So_Khai_Tu` (`SoGiayKhaiTu`),
  CONSTRAINT `An_Tang_chk_1` CHECK ((`HinhThuc` in (_utf8mb4'Hỏa táng',_utf8mb4'Địa táng')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `An_Tang`
--

LOCK TABLES `An_Tang` WRITE;
/*!40000 ALTER TABLE `An_Tang` DISABLE KEYS */;
/*!40000 ALTER TABLE `An_Tang` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `CSYT`
--

DROP TABLE IF EXISTS `CSYT`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `CSYT` (
  `MaCSYT` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `TenCSYT` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `DiaChi` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `SDT` varchar(15) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`MaCSYT`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `CSYT`
--

LOCK TABLES `CSYT` WRITE;
/*!40000 ALTER TABLE `CSYT` DISABLE KEYS */;
/*!40000 ALTER TABLE `CSYT` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Can_Bo`
--

DROP TABLE IF EXISTS `Can_Bo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Can_Bo` (
  `MaCanBo` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `CCCD` char(12) COLLATE utf8mb4_unicode_ci NOT NULL,
  `HoTen` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ChucVu` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `SDT` varchar(15) COLLATE utf8mb4_unicode_ci NOT NULL,
  `MaUBND` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`MaCanBo`),
  UNIQUE KEY `CCCD` (`CCCD`),
  KEY `MaUBND` (`MaUBND`),
  CONSTRAINT `Can_Bo_ibfk_1` FOREIGN KEY (`MaUBND`) REFERENCES `UBND` (`MaUBND`),
  CONSTRAINT `Can_Bo_chk_1` CHECK (regexp_like(`CCCD`,_utf8mb4'^[0-9]{12}$'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Can_Bo`
--

LOCK TABLES `Can_Bo` WRITE;
/*!40000 ALTER TABLE `Can_Bo` DISABLE KEYS */;
/*!40000 ALTER TABLE `Can_Bo` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Cong_Dan`
--

DROP TABLE IF EXISTS `Cong_Dan`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Cong_Dan` (
  `CCCD` char(12) COLLATE utf8mb4_unicode_ci NOT NULL,
  `HoTen` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `NgaySinh` date NOT NULL,
  `GioiTinh` enum('Nam','Nữ','Khác') COLLATE utf8mb4_unicode_ci NOT NULL,
  `QueQuan` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `DanToc` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT 'Kinh',
  `SDT` varchar(15) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `TrangThai` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Còn sống',
  PRIMARY KEY (`CCCD`),
  CONSTRAINT `Cong_Dan_chk_1` CHECK (regexp_like(`CCCD`,_utf8mb4'^[0-9]{12}$')),
  CONSTRAINT `Cong_Dan_chk_2` CHECK ((`TrangThai` in (_utf8mb4'Còn sống',_utf8mb4'Đã mất')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Cong_Dan`
--

LOCK TABLES `Cong_Dan` WRITE;
/*!40000 ALTER TABLE `Cong_Dan` DISABLE KEYS */;
/*!40000 ALTER TABLE `Cong_Dan` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Giay_Bao_Tu`
--

DROP TABLE IF EXISTS `Giay_Bao_Tu`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Giay_Bao_Tu` (
  `SoGiayBaoTu` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `NgayCap` date NOT NULL,
  `NgayGioMat` datetime NOT NULL,
  `NoiMatChiTiet` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `MoTaNguyenNhan` text COLLATE utf8mb4_unicode_ci,
  `CCCD_NgMat` char(12) COLLATE utf8mb4_unicode_ci NOT NULL,
  `MaCSYT` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `MaNguyenNhan` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `MaXaPhuong` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`SoGiayBaoTu`),
  UNIQUE KEY `CCCD_NgMat` (`CCCD_NgMat`),
  KEY `MaCSYT` (`MaCSYT`),
  KEY `MaNguyenNhan` (`MaNguyenNhan`),
  KEY `MaXaPhuong` (`MaXaPhuong`),
  CONSTRAINT `Giay_Bao_Tu_ibfk_1` FOREIGN KEY (`CCCD_NgMat`) REFERENCES `Cong_Dan` (`CCCD`),
  CONSTRAINT `Giay_Bao_Tu_ibfk_2` FOREIGN KEY (`MaCSYT`) REFERENCES `CSYT` (`MaCSYT`),
  CONSTRAINT `Giay_Bao_Tu_ibfk_3` FOREIGN KEY (`MaNguyenNhan`) REFERENCES `Nguyen_Nhan` (`MaNguyenNhan`),
  CONSTRAINT `Giay_Bao_Tu_ibfk_4` FOREIGN KEY (`MaXaPhuong`) REFERENCES `Noi_Mat` (`MaXaPhuong`),
  CONSTRAINT `Giay_Bao_Tu_chk_1` CHECK ((cast(`NgayGioMat` as date) <= `NgayCap`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Giay_Bao_Tu`
--

LOCK TABLES `Giay_Bao_Tu` WRITE;
/*!40000 ALTER TABLE `Giay_Bao_Tu` DISABLE KEYS */;
/*!40000 ALTER TABLE `Giay_Bao_Tu` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `KT_Moi_GiayBaoTu_BU` BEFORE UPDATE ON `Giay_Bao_Tu` FOR EACH ROW BEGIN
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
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `KT_Moi_GiayBaoTu_AU` AFTER UPDATE ON `Giay_Bao_Tu` FOR EACH ROW BEGIN
  DECLARE v_trang_thai VARCHAR(30) DEFAULT NULL;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_trang_thai = NULL;
  SELECT TrangThaiHoSo INTO v_trang_thai FROM Ho_So_Khai_Tu
  WHERE SoGiayBaoTu = NEW.SoGiayBaoTu FOR SHARE;
  IF v_trang_thai IS NOT NULL AND v_trang_thai <> 'Từ chối' THEN
    UPDATE Cong_Dan SET TrangThai = 'Đã mất' WHERE CCCD = NEW.CCCD_NgMat;
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `Ho_So_Khai_Tu`
--

DROP TABLE IF EXISTS `Ho_So_Khai_Tu`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Ho_So_Khai_Tu` (
  `SoGiayKhaiTu` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `SoGiayBaoTu` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `NgayDangKi` date NOT NULL,
  `CCCD_NgKhaiTu` char(12) COLLATE utf8mb4_unicode_ci NOT NULL,
  `QuanHe` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `TrangThaiHoSo` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Chờ xử lý',
  `MaCanBoTiepNhan` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`SoGiayKhaiTu`),
  UNIQUE KEY `SoGiayBaoTu` (`SoGiayBaoTu`),
  KEY `CCCD_NgKhaiTu` (`CCCD_NgKhaiTu`),
  KEY `MaCanBoTiepNhan` (`MaCanBoTiepNhan`),
  CONSTRAINT `Ho_So_Khai_Tu_ibfk_1` FOREIGN KEY (`SoGiayBaoTu`) REFERENCES `Giay_Bao_Tu` (`SoGiayBaoTu`),
  CONSTRAINT `Ho_So_Khai_Tu_ibfk_2` FOREIGN KEY (`CCCD_NgKhaiTu`) REFERENCES `Cong_Dan` (`CCCD`),
  CONSTRAINT `Ho_So_Khai_Tu_ibfk_3` FOREIGN KEY (`MaCanBoTiepNhan`) REFERENCES `Can_Bo` (`MaCanBo`),
  CONSTRAINT `Ho_So_Khai_Tu_chk_1` CHECK ((`TrangThaiHoSo` in (_utf8mb4'Chờ xử lý',_utf8mb4'Đã duyệt',_utf8mb4'Từ chối')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Ho_So_Khai_Tu`
--

LOCK TABLES `Ho_So_Khai_Tu` WRITE;
/*!40000 ALTER TABLE `Ho_So_Khai_Tu` DISABLE KEYS */;
/*!40000 ALTER TABLE `Ho_So_Khai_Tu` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `KT_Moi_HoSo_BI` BEFORE INSERT ON `Ho_So_Khai_Tu` FOR EACH ROW BEGIN
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
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `KT_Moi_HoSo_AI` AFTER INSERT ON `Ho_So_Khai_Tu` FOR EACH ROW BEGIN
  DECLARE v_nguoi_mat CHAR(12) DEFAULT NULL;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_nguoi_mat = NULL;
  IF NEW.TrangThaiHoSo <> 'Từ chối' THEN
    SELECT CCCD_NgMat INTO v_nguoi_mat FROM Giay_Bao_Tu
    WHERE SoGiayBaoTu = NEW.SoGiayBaoTu FOR SHARE;
    UPDATE Cong_Dan SET TrangThai = 'Đã mất' WHERE CCCD = v_nguoi_mat;
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `KT_Moi_HoSo_BU` BEFORE UPDATE ON `Ho_So_Khai_Tu` FOR EACH ROW BEGIN
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
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `KT_Moi_HoSo_AU` AFTER UPDATE ON `Ho_So_Khai_Tu` FOR EACH ROW BEGIN
  DECLARE v_nguoi_mat CHAR(12) DEFAULT NULL;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_nguoi_mat = NULL;
  IF NEW.TrangThaiHoSo <> 'Từ chối' THEN
    SELECT CCCD_NgMat INTO v_nguoi_mat FROM Giay_Bao_Tu
    WHERE SoGiayBaoTu = NEW.SoGiayBaoTu FOR SHARE;
    UPDATE Cong_Dan SET TrangThai = 'Đã mất' WHERE CCCD = v_nguoi_mat;
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `Nguyen_Nhan`
--

DROP TABLE IF EXISTS `Nguyen_Nhan`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Nguyen_Nhan` (
  `MaNguyenNhan` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `TenNguyenNhan` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`MaNguyenNhan`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Nguyen_Nhan`
--

LOCK TABLES `Nguyen_Nhan` WRITE;
/*!40000 ALTER TABLE `Nguyen_Nhan` DISABLE KEYS */;
/*!40000 ALTER TABLE `Nguyen_Nhan` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Noi_Mat`
--

DROP TABLE IF EXISTS `Noi_Mat`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Noi_Mat` (
  `MaXaPhuong` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `TenXaPhuong` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`MaXaPhuong`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Noi_Mat`
--

LOCK TABLES `Noi_Mat` WRITE;
/*!40000 ALTER TABLE `Noi_Mat` DISABLE KEYS */;
/*!40000 ALTER TABLE `Noi_Mat` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `UBND`
--

DROP TABLE IF EXISTS `UBND`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `UBND` (
  `MaUBND` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `TenUBND` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `CapHanhChinh` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `DiaChi` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `SDT` varchar(15) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`MaUBND`),
  CONSTRAINT `UBND_chk_1` CHECK ((`CapHanhChinh` in (_utf8mb4'Xã',_utf8mb4'Phường')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `UBND`
--

LOCK TABLES `UBND` WRITE;
/*!40000 ALTER TABLE `UBND` DISABLE KEYS */;
/*!40000 ALTER TABLE `UBND` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping events for database 'quan_li_khai_tu'
--

--
-- Dumping routines for database 'quan_li_khai_tu'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-11-10 15:26:35
