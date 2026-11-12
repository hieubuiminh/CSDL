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

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `quan_li_khai_tu` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

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
INSERT INTO `An_Tang` VALUES ('AT001','HS002','Hỏa táng','Đài hóa thân Văn Điển','2024-03-06'),('AT002','HS003','Hỏa táng','Đài hóa thân Văn Điển','2024-04-28'),('AT003','HS004','Hỏa táng','Đài hóa thân Văn Điển','2024-08-11'),('AT004','HS005','Hỏa táng','Đài hóa thân Văn Điển','2024-10-14'),('AT005','HS006','Địa táng','Nghĩa trang Mai Dịch','2024-10-20'),('AT006','HS007','Địa táng','Nghĩa trang Yên Kỳ','2024-11-22'),('AT007','HS008','Hỏa táng','Đài hóa thân Văn Điển','2024-11-19'),('AT008','HS009','Hỏa táng','Đài hóa thân Văn Điển','2025-01-29'),('AT009','HS011','Hỏa táng','Đài hóa thân Văn Điển','2025-02-06'),('AT010','HS013','Địa táng','Nghĩa trang Mai Dịch','2025-03-13'),('AT011','HS015','Địa táng','Nghĩa trang Yên Kỳ','2025-04-28'),('AT012','HS016','Địa táng','Nghĩa trang Yên Kỳ','2025-06-01'),('AT013','HS017','Địa táng','Nghĩa trang Mai Dịch','2025-07-27'),('AT014','HS018','Địa táng','Nghĩa trang Mai Dịch','2025-08-08'),('AT015','HS019','Hỏa táng','Đài hóa thân Văn Điển','2025-10-07'),('AT016','HS020','Hỏa táng','Đài hóa thân Văn Điển','2025-10-14'),('AT017','HS022','Hỏa táng','Đài hóa thân Văn Điển','2025-10-25'),('AT018','HS023','Địa táng','Nghĩa trang Mai Dịch','2025-10-31'),('AT019','HS025','Hỏa táng','Đài hóa thân Văn Điển','2026-07-09'),('AT020','HS026','Hỏa táng','Đài hóa thân Văn Điển','2026-07-12'),('AT021','HS027','Hỏa táng','Đài hóa thân Văn Điển','2026-07-13'),('AT022','HS029','Hỏa táng','Đài hóa thân Văn Điển','2026-07-14'),('AT023','HS030','Hỏa táng','Đài hóa thân Văn Điển','2026-07-16'),('AT024','HS031','Địa táng','Nghĩa trang Yên Kỳ','2026-07-17'),('AT025','HS032','Hỏa táng','Đài hóa thân Văn Điển','2026-07-14'),('AT026','HS033','Địa táng','Nghĩa trang Mai Dịch','2026-07-20'),('AT027','HS035','Hỏa táng','Đài hóa thân Văn Điển','2026-07-26'),('AT028','HS037','Địa táng','Nghĩa trang Mai Dịch','2026-07-27'),('AT029','HS038','Hỏa táng','Đài hóa thân Văn Điển','2026-07-28'),('AT030','HS039','Hỏa táng','Đài hóa thân Văn Điển','2026-07-28'),('AT031','HS040','Địa táng','Nghĩa trang Yên Kỳ','2026-08-08'),('AT032','HS041','Địa táng','Nghĩa trang Mai Dịch','2026-08-06'),('AT033','HS042','Hỏa táng','Đài hóa thân Văn Điển','2026-08-13'),('AT034','HS043','Địa táng','Nghĩa trang Mai Dịch','2026-08-11'),('AT035','HS045','Hỏa táng','Đài hóa thân Văn Điển','2026-08-14'),('AT036','HS046','Hỏa táng','Đài hóa thân Văn Điển','2026-08-15'),('AT037','HS047','Hỏa táng','Đài hóa thân Văn Điển','2026-08-13'),('AT038','HS048','Địa táng','Nghĩa trang Yên Kỳ','2026-08-17'),('AT039','HS049','Hỏa táng','Đài hóa thân Văn Điển','2026-08-17'),('AT040','HS050','Địa táng','Nghĩa trang Yên Kỳ','2026-08-18'),('AT041','HS052','Địa táng','Nghĩa trang Mai Dịch','2026-08-22'),('AT042','HS053','Hỏa táng','Đài hóa thân Văn Điển','2026-08-20'),('AT043','HS054','Hỏa táng','Đài hóa thân Văn Điển','2026-08-23'),('AT044','HS056','Địa táng','Nghĩa trang Mai Dịch','2026-08-28'),('AT045','HS058','Địa táng','Nghĩa trang Yên Kỳ','2026-08-30'),('AT046','HS062','Địa táng','Nghĩa trang Yên Kỳ','2026-09-05'),('AT047','HS063','Hỏa táng','Đài hóa thân Văn Điển','2026-09-05'),('AT048','HS064','Địa táng','Nghĩa trang Mai Dịch','2026-09-09'),('AT049','HS067','Địa táng','Nghĩa trang Mai Dịch','2026-09-14'),('AT050','HS069','Địa táng','Nghĩa trang Yên Kỳ','2026-09-14'),('AT051','HS070','Địa táng','Nghĩa trang Yên Kỳ','2026-09-14'),('AT052','HS071','Hỏa táng','Đài hóa thân Văn Điển','2026-09-15'),('AT053','HS072','Địa táng','Nghĩa trang Yên Kỳ','2026-09-15'),('AT054','HS074','Địa táng','Nghĩa trang Mai Dịch','2026-09-16'),('AT055','HS075','Hỏa táng','Đài hóa thân Văn Điển','2026-09-17'),('AT056','HS076','Địa táng','Nghĩa trang Yên Kỳ','2026-09-19'),('AT057','HS077','Hỏa táng','Đài hóa thân Văn Điển','2026-09-21'),('AT058','HS079','Địa táng','Nghĩa trang Mai Dịch','2026-09-25'),('AT059','HS082','Hỏa táng','Đài hóa thân Văn Điển','2026-10-06'),('AT060','HS086','Địa táng','Nghĩa trang Mai Dịch','2026-10-05'),('AT061','HS087','Hỏa táng','Đài hóa thân Văn Điển','2026-10-06'),('AT062','HS090','Hỏa táng','Đài hóa thân Văn Điển','2026-10-10'),('AT063','HS091','Hỏa táng','Đài hóa thân Văn Điển','2026-10-09'),('AT064','HS098','Hỏa táng','Đài hóa thân Văn Điển','2026-10-14');
/*!40000 ALTER TABLE `An_Tang` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `App_User`
--

DROP TABLE IF EXISTS `App_User`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `App_User` (
  `Id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `Username` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `PasswordHash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `DisplayName` varchar(160) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Role` enum('admin','staff') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'staff',
  `MaCanBo` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `CreatedAt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`Id`),
  UNIQUE KEY `Username` (`Username`),
  UNIQUE KEY `uq_app_user_can_bo` (`MaCanBo`),
  CONSTRAINT `fk_app_user_can_bo` FOREIGN KEY (`MaCanBo`) REFERENCES `Can_Bo` (`MaCanBo`) ON DELETE RESTRICT,
  CONSTRAINT `ck_app_user_role_can_bo` CHECK ((((`Role` = _utf8mb4'admin') and (`MaCanBo` is null)) or ((`Role` = _utf8mb4'staff') and (`MaCanBo` is not null))))
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `App_User`
--

LOCK TABLES `App_User` WRITE;
/*!40000 ALTER TABLE `App_User` DISABLE KEYS */;
INSERT INTO `App_User` VALUES (1,'okoklatoi','recovery-v1|first_teacher|$2a$12$1cAixeLEwKf3vdhCJjwtuuCnUT6kwXx4GZ8HRxch4x9jGPfcKoGya|$2a$12$WjB8VmWHkEwohJuWykxfdulFfbq1/cNrj3Ex4ZP2KG/mtGk9qVk8S','Bùi Minh Hiếu','admin',NULL,'2026-11-10 15:45:16'),(2,'canbo01','$2a$12$bjw/mS9QigaOAlTR5t91leKLZ35HeoX4Enc3aUPNCeMQbn/Rb//KC','Vũ Đức Bình','staff','CB01','2026-11-11 13:20:58');
/*!40000 ALTER TABLE `App_User` ENABLE KEYS */;
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
INSERT INTO `CSYT` VALUES ('CS01','Bệnh viện Đa khoa Trung tâm','12 Phố Huế, Hà Nội','0241000001'),('CS02','Bệnh viện Quận Đống Đa','45 Tây Sơn, Hà Nội','0241000002'),('CS03','Trạm Y tế Phường Láng Hạ','8 Láng Hạ, Hà Nội','0241000003'),('CS04','Phòng khám Đa khoa Cầu Giấy','20 Trần Thái Tông, Hà Nội','0241000004');
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
INSERT INTO `Can_Bo` VALUES ('CB01','003000000001','Vũ Đức Bình','Phó Chủ tịch UBND','0910000001','UB01'),('CB02','003000000002','Nguyễn Thị Loan','Phó Chủ tịch UBND','0910000002','UB02'),('CB03','003000000003','Trần Quang Sơn','Cán bộ tư pháp - hộ tịch','0910000003','UB03'),('CB04','003000000004','Nguyễn Ngọc Lan','Cán bộ tư pháp - hộ tịch','0910000004','UB01'),('CB05','003000000005','Trần Minh Bình','Cán bộ tư pháp - hộ tịch','0910000005','UB02'),('CB06','003000000006','Trần Ngọc Hoa','Cán bộ tư pháp - hộ tịch','0910000006','UB03');
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
INSERT INTO `Cong_Dan` VALUES ('001000000001','Đặng Ngọc Hoa','1957-07-02','Nữ','Hải Dương','Kinh','0900000001','Đã mất'),('001000000002','Bùi Hồng Linh','1932-08-16','Nữ','Nam Định','Kinh','0900000002','Đã mất'),('001000000003','Ngô Hữu Phúc','1938-04-07','Nam','Hưng Yên','Kinh','0900000003','Đã mất'),('001000000004','Trần Thu Hoa','1951-03-14','Nữ','Nghệ An','Kinh','0900000004','Đã mất'),('001000000005','Phạm Hữu Tuấn','1950-04-25','Nam','Bắc Ninh','Kinh','0900000005','Đã mất'),('001000000006','Trần Hồng Loan','1951-02-17','Nữ','Hà Nội','Kinh','0900000006','Đã mất'),('001000000007','Trần Ngọc Cúc','1965-03-15','Nữ','Nam Định','Kinh','0900000007','Đã mất'),('001000000008','Trần Đức Thành','1958-01-25','Nam','Thái Bình','Kinh','0900000008','Đã mất'),('001000000009','Trần Ngọc Lan','1943-07-09','Nữ','Hải Dương','Kinh','0900000009','Đã mất'),('001000000010','Bùi Minh Hải','1937-09-27','Nam','Bắc Ninh','Kinh','0900000010','Đã mất'),('001000000011','Ngô Hồng Lan','1962-03-09','Nữ','Bắc Ninh','Kinh','0900000011','Đã mất'),('001000000012','Ngô Thị Yến','1963-11-08','Nữ','Thái Bình','Kinh','0900000012','Đã mất'),('001000000013','Bùi Hồng Linh','1963-11-08','Nữ','Hà Nội','Kinh','0900000013','Đã mất'),('001000000014','Ngô Hữu Sơn','1948-12-10','Nam','Thái Bình','Kinh','0900000014','Đã mất'),('001000000015','Hoàng Minh Nam','1932-08-09','Nam','Hải Dương','Kinh','0900000015','Đã mất'),('001000000016','Vũ Thu Nga','1957-01-11','Nữ','Nam Định','Kinh','0900000016','Đã mất'),('001000000017','Vũ Đức Trung','1939-09-18','Nam','Nam Định','Kinh','0900000017','Đã mất'),('001000000018','Trần Minh Bình','1933-08-11','Nam','Thái Bình','Kinh','0900000018','Đã mất'),('001000000019','Ngô Thu Hương','1932-04-03','Nữ','Nghệ An','Kinh','0900000019','Đã mất'),('001000000020','Đỗ Quang Long','2007-01-21','Nam','Bắc Ninh','Kinh','0900000020','Đã mất'),('001000000021','Đặng Minh Dũng','2004-11-21','Nam','Bắc Ninh','Kinh','0900000021','Đã mất'),('001000000022','Phạm Hữu Phúc','1948-05-04','Nam','Thái Bình','Kinh','0900000022','Đã mất'),('001000000023','Phạm Hồng Thảo','1931-01-10','Nữ','Hưng Yên','Kinh','0900000023','Đã mất'),('001000000024','Bùi Hồng Lan','1967-11-25','Nữ','Nghệ An','Kinh','0900000024','Đã mất'),('001000000025','Nguyễn Minh Thành','1935-08-25','Nam','Nghệ An','Kinh','0900000025','Đã mất'),('001000000026','Đỗ Thị Hương','1938-02-09','Nữ','Nam Định','Kinh','0900000026','Đã mất'),('001000000027','Lê Đức Hải','1953-07-09','Nam','Hải Dương','Kinh','0900000027','Đã mất'),('001000000028','Bùi Hữu Tuấn','1966-10-23','Nam','Hải Dương','Kinh','0900000028','Đã mất'),('001000000029','Trần Thị Hạnh','1940-03-21','Nữ','Thái Bình','Kinh','0900000029','Đã mất'),('001000000030','Lê Ngọc Mai','1960-06-15','Nữ','Hà Nội','Kinh','0900000030','Đã mất'),('001000000031','Nguyễn Hồng Yến','1955-04-20','Nữ','Hải Dương','Kinh','0900000031','Đã mất'),('001000000032','Ngô Hồng Mai','1941-08-17','Nữ','Hà Nội','Kinh','0900000032','Đã mất'),('001000000033','Trần Đức Hùng','1976-09-13','Nam','Nam Định','Kinh','0900000033','Đã mất'),('001000000034','Vũ Quang Khoa','2006-03-21','Nam','Hưng Yên','Kinh','0900000034','Đã mất'),('001000000035','Vũ Văn Thành','2003-10-24','Nam','Bắc Ninh','Kinh','0900000035','Đã mất'),('001000000036','Ngô Minh Sơn','1959-09-08','Nam','Bắc Ninh','Kinh','0900000036','Đã mất'),('001000000037','Đỗ Minh Nam','1937-09-24','Nam','Thái Bình','Kinh','0900000037','Đã mất'),('001000000038','Hoàng Minh Dũng','2023-07-24','Nam','Thanh Hóa','Kinh','0900000038','Đã mất'),('001000000039','Phạm Ngọc Nga','1998-07-11','Nữ','Thanh Hóa','Kinh','0900000039','Đã mất'),('001000000040','Nguyễn Văn Sơn','1963-12-02','Nam','Hưng Yên','Kinh','0900000040','Đã mất'),('001000000041','Nguyễn Hồng Linh','1992-06-11','Nữ','Hà Nội','Kinh','0900000041','Đã mất'),('001000000042','Bùi Đức Trung','1949-03-10','Nam','Hải Dương','Kinh','0900000042','Đã mất'),('001000000043','Bùi Đức Phúc','1963-06-17','Nam','Hưng Yên','Kinh','0900000043','Đã mất'),('001000000044','Phạm Hồng Mai','1955-02-07','Nữ','Thái Bình','Kinh','0900000044','Đã mất'),('001000000045','Bùi Ngọc Nga','1949-07-01','Nữ','Nghệ An','Kinh','0900000045','Đã mất'),('001000000046','Vũ Quang Hải','1934-02-02','Nam','Hải Dương','Kinh','0900000046','Đã mất'),('001000000047','Hoàng Minh Khoa','1984-02-14','Nam','Hưng Yên','Kinh','0900000047','Đã mất'),('001000000048','Bùi Ngọc Linh','1957-08-12','Nữ','Nghệ An','Kinh','0900000048','Đã mất'),('001000000049','Ngô Văn Khoa','1932-11-19','Nam','Hà Nội','Kinh','0900000049','Đã mất'),('001000000050','Bùi Văn Hải','1960-08-22','Nam','Nam Định','Kinh','0900000050','Đã mất'),('001000000051','Đặng Thị Lan','1954-11-21','Nữ','Hà Nội','Kinh','0900000051','Đã mất'),('001000000052','Hoàng Quang Thành','1987-01-27','Nam','Hưng Yên','Kinh','0900000052','Đã mất'),('001000000053','Trần Thị Loan','1953-08-20','Nữ','Nghệ An','Kinh','0900000053','Đã mất'),('001000000054','Hoàng Thị Huệ','1963-07-19','Nữ','Hà Nội','Kinh','0900000054','Đã mất'),('001000000055','Trần Minh Trung','1964-10-08','Nam','Thái Bình','Kinh','0900000055','Đã mất'),('001000000056','Đặng Văn Tuấn','1955-08-20','Nam','Hưng Yên','Kinh','0900000056','Đã mất'),('001000000057','Ngô Ngọc Huệ','1941-07-20','Nữ','Bắc Ninh','Kinh','0900000057','Đã mất'),('001000000058','Hoàng Văn Bình','1936-05-19','Nam','Thanh Hóa','Kinh','0900000058','Đã mất'),('001000000059','Nguyễn Văn Long','1959-08-26','Nam','Hưng Yên','Kinh','0900000059','Đã mất'),('001000000060','Hoàng Văn Hùng','1953-07-03','Nam','Hà Nội','Kinh','0900000060','Đã mất'),('001000000061','Lê Ngọc Lan','1942-12-08','Nữ','Bắc Ninh','Kinh','0900000061','Đã mất'),('001000000062','Bùi Minh Long','1949-06-16','Nam','Thanh Hóa','Kinh','0900000062','Đã mất'),('001000000063','Trần Hồng Loan','1999-01-06','Nữ','Thái Bình','Kinh','0900000063','Đã mất'),('001000000064','Hoàng Ngọc Hương','1953-07-09','Nữ','Nam Định','Kinh','0900000064','Đã mất'),('001000000065','Lê Văn Dũng','1951-04-20','Nam','Thanh Hóa','Kinh','0900000065','Đã mất'),('001000000066','Trần Ngọc Mai','1982-11-09','Nữ','Hưng Yên','Kinh','0900000066','Đã mất'),('001000000067','Bùi Ngọc Yến','1975-04-03','Nữ','Thái Bình','Kinh','0900000067','Đã mất'),('001000000068','Ngô Ngọc Hương','2001-03-18','Nữ','Thái Bình','Kinh','0900000068','Đã mất'),('001000000069','Đặng Ngọc Nga','1988-11-12','Nữ','Hà Nội','Kinh','0900000069','Đã mất'),('001000000070','Hoàng Văn Thành','1965-01-10','Nam','Hưng Yên','Kinh','0900000070','Đã mất'),('001000000071','Phạm Thu Lan','1946-08-27','Nữ','Hải Dương','Kinh','0900000071','Đã mất'),('001000000072','Ngô Văn Hải','1962-08-12','Nam','Hải Dương','Kinh','0900000072','Đã mất'),('001000000073','Hoàng Thu Linh','1937-05-24','Nữ','Hưng Yên','Kinh','0900000073','Đã mất'),('001000000074','Vũ Thị Linh','1952-01-01','Nữ','Thanh Hóa','Kinh','0900000074','Đã mất'),('001000000075','Bùi Thị Mai','1944-12-27','Nữ','Hưng Yên','Kinh','0900000075','Đã mất'),('001000000076','Đặng Quang Bình','1946-09-01','Nam','Nam Định','Kinh','0900000076','Đã mất'),('001000000077','Nguyễn Quang Khoa','1950-03-02','Nam','Nam Định','Kinh','0900000077','Đã mất'),('001000000078','Bùi Đức Khoa','1949-08-03','Nam','Nghệ An','Kinh','0900000078','Đã mất'),('001000000079','Đỗ Hồng Hạnh','1944-07-11','Nữ','Nam Định','Kinh','0900000079','Đã mất'),('001000000080','Phạm Ngọc Linh','1985-07-13','Nữ','Thanh Hóa','Kinh','0900000080','Đã mất'),('001000000081','Đặng Thị Cúc','1956-07-23','Nữ','Thái Bình','Kinh','0900000081','Đã mất'),('001000000082','Lê Thu Nga','1964-11-23','Nữ','Hà Nội','Kinh','0900000082','Đã mất'),('001000000083','Ngô Hữu Tuấn','1934-05-14','Nam','Hà Nội','Kinh','0900000083','Đã mất'),('001000000084','Vũ Ngọc Huệ','1962-04-14','Nữ','Hải Dương','Kinh','0900000084','Đã mất'),('001000000085','Bùi Thu Cúc','1965-08-05','Nữ','Bắc Ninh','Kinh','0900000085','Đã mất'),('001000000086','Nguyễn Minh Dũng','1991-12-10','Nam','Thái Bình','Kinh','0900000086','Đã mất'),('001000000087','Hoàng Văn Bình','1967-12-01','Nam','Thái Bình','Kinh','0900000087','Đã mất'),('001000000088','Nguyễn Thị Mai','1938-03-10','Nữ','Hải Dương','Kinh','0900000088','Đã mất'),('001000000089','Vũ Ngọc Nga','1965-03-24','Nữ','Bắc Ninh','Kinh','0900000089','Đã mất'),('001000000090','Vũ Thị Hương','1957-06-17','Nữ','Hải Dương','Kinh','0900000090','Đã mất'),('001000000091','Trần Hồng Hương','1949-04-18','Nữ','Nam Định','Kinh','0900000091','Đã mất'),('001000000092','Nguyễn Văn Sơn','1979-03-14','Nam','Hải Dương','Kinh','0900000092','Đã mất'),('001000000093','Ngô Hồng Lan','2006-04-23','Nữ','Thanh Hóa','Kinh','0900000093','Đã mất'),('001000000094','Đỗ Hồng Huệ','2006-10-27','Nữ','Thái Bình','Kinh','0900000094','Đã mất'),('001000000095','Ngô Thị Hạnh','2009-08-20','Nữ','Thái Bình','Kinh','0900000095','Đã mất'),('001000000096','Lê Đức Tuấn','1944-09-28','Nam','Nghệ An','Kinh','0900000096','Đã mất'),('001000000097','Lê Quang Dũng','1949-09-22','Nam','Hải Dương','Kinh','0900000097','Đã mất'),('001000000098','Nguyễn Hữu Khoa','1940-10-10','Nam','Nam Định','Kinh','0900000098','Đã mất'),('001000000099','Ngô Thu Huệ','1962-01-03','Nữ','Nghệ An','Kinh','0900000099','Đã mất'),('001000000100','Đặng Thu Hương','1956-10-19','Nữ','Bắc Ninh','Kinh','0900000100','Đã mất'),('002000000001','Đặng Quang Sơn','1980-01-04','Nam','Hà Nội','Kinh','0980000001','Còn sống'),('002000000002','Bùi Quang Phúc','1959-12-06','Nam','Hà Nội','Kinh','0980000002','Còn sống'),('002000000003','Ngô Minh Thành','1964-04-23','Nam','Hưng Yên','Kinh','0980000003','Còn sống'),('002000000004','Trần Ngọc Mai','1974-03-01','Nữ','Thái Bình','Kinh','0980000004','Còn sống'),('002000000005','Phạm Thị Cúc','1993-06-15','Nữ','Nghệ An','Kinh','0980000005','Còn sống'),('002000000006','Trần Ngọc Cúc','1978-05-15','Nữ','Thanh Hóa','Kinh','0980000006','Còn sống'),('002000000007','Trần Ngọc Mai','1989-12-14','Nữ','Nghệ An','Kinh','0980000007','Còn sống'),('002000000008','Trần Ngọc Loan','1986-09-19','Nữ','Thanh Hóa','Kinh','0980000008','Còn sống'),('002000000009','Trần Văn Long','1968-04-10','Nam','Bắc Ninh','Kinh','0980000009','Còn sống'),('002000000010','Bùi Đức Trung','1963-12-21','Nam','Thái Bình','Kinh','0980000010','Còn sống'),('002000000011','Đỗ Quang Nam','1980-01-10','Nam','Hải Dương','Kinh','0980000011','Còn sống'),('002000000012','Ngô Hồng Mai','1981-05-24','Nữ','Thái Bình','Kinh','0980000012','Còn sống'),('002000000013','Bùi Hữu Dũng','1992-11-17','Nam','Nam Định','Kinh','0980000013','Còn sống'),('002000000014','Ngô Hồng Linh','1969-11-04','Nữ','Hải Dương','Kinh','0980000014','Còn sống'),('002000000015','Hoàng Hữu Thành','1956-06-05','Nam','Bắc Ninh','Kinh','0980000015','Còn sống'),('002000000016','Vũ Quang Tuấn','1982-02-13','Nam','Nghệ An','Kinh','0980000016','Còn sống'),('002000000017','Vũ Ngọc Hạnh','1967-05-16','Nữ','Hà Nội','Kinh','0980000017','Còn sống'),('002000000018','Trần Văn Long','1986-06-18','Nam','Nam Định','Kinh','0980000018','Còn sống'),('002000000019','Ngô Thu Lan','1959-03-02','Nữ','Nghệ An','Kinh','0980000019','Còn sống'),('002000000020','Đỗ Thị Hoa','1957-02-10','Nữ','Hải Dương','Kinh','0980000020','Còn sống'),('002000000021','Đặng Ngọc Huệ','2004-01-23','Nữ','Hưng Yên','Kinh','0980000021','Còn sống'),('002000000022','Phạm Thị Yến','1975-03-13','Nữ','Hà Nội','Kinh','0980000022','Còn sống'),('002000000023','Phạm Văn Dũng','1956-05-03','Nam','Hưng Yên','Kinh','0980000023','Còn sống'),('002000000024','Bùi Thị Linh','1989-04-24','Nữ','Nam Định','Kinh','0980000024','Còn sống'),('002000000025','Nguyễn Đức Hùng','1962-12-10','Nam','Thái Bình','Kinh','0980000025','Còn sống'),('002000000026','Đỗ Ngọc Hương','1965-03-14','Nữ','Thanh Hóa','Kinh','0980000026','Còn sống'),('002000000027','Lê Thị Lan','1973-08-27','Nữ','Hải Dương','Kinh','0980000027','Còn sống'),('002000000028','Bùi Ngọc Lan','1991-04-09','Nữ','Hà Nội','Kinh','0980000028','Còn sống'),('002000000029','Trần Thu Hạnh','1966-05-14','Nữ','Hà Nội','Kinh','0980000029','Còn sống'),('002000000030','Lê Minh Dũng','1990-10-20','Nam','Hưng Yên','Kinh','0980000030','Còn sống'),('002000000031','Nguyễn Đức Hùng','1984-07-17','Nam','Thái Bình','Kinh','0980000031','Còn sống'),('002000000032','Ngô Ngọc Huệ','1968-10-25','Nữ','Thanh Hóa','Kinh','0980000032','Còn sống'),('002000000033','Trần Đức Phúc','1989-05-26','Nam','Thái Bình','Kinh','0980000033','Còn sống'),('002000000034','Vũ Văn Hải','2004-01-21','Nam','Hưng Yên','Kinh','0980000034','Còn sống'),('002000000035','Ngô Thu Cúc','1961-01-24','Nữ','Hà Nội','Kinh','0980000035','Còn sống'),('002000000036','Ngô Quang Sơn','1988-08-06','Nam','Thái Bình','Kinh','0980000036','Còn sống'),('002000000037','Đỗ Hữu Hùng','1957-07-06','Nam','Hải Dương','Kinh','0980000037','Còn sống'),('002000000038','Hoàng Quang Nam','2004-11-02','Nam','Nam Định','Kinh','0980000038','Còn sống'),('002000000039','Phạm Minh Trung','2004-04-19','Nam','Bắc Ninh','Kinh','0980000039','Còn sống'),('002000000040','Nguyễn Văn Nam','1989-04-07','Nam','Nam Định','Kinh','0980000040','Còn sống'),('002000000041','Nguyễn Hữu Dũng','2004-06-16','Nam','Hà Nội','Kinh','0980000041','Còn sống'),('002000000042','Bùi Văn Phúc','1970-12-18','Nam','Nam Định','Kinh','0980000042','Còn sống'),('002000000043','Bùi Thu Yến','1990-04-05','Nữ','Hưng Yên','Kinh','0980000043','Còn sống'),('002000000044','Đặng Quang Nam','1982-02-21','Nam','Nam Định','Kinh','0980000044','Còn sống'),('002000000045','Bùi Đức Khoa','1979-02-15','Nam','Nghệ An','Kinh','0980000045','Còn sống'),('002000000046','Vũ Quang Dũng','1962-10-15','Nam','Hải Dương','Kinh','0980000046','Còn sống'),('002000000047','Hoàng Ngọc Linh','1995-12-13','Nữ','Hải Dương','Kinh','0980000047','Còn sống'),('002000000048','Lê Minh Hùng','1974-12-26','Nam','Bắc Ninh','Kinh','0980000048','Còn sống'),('002000000049','Ngô Quang Thành','1962-10-04','Nam','Thái Bình','Kinh','0980000049','Còn sống'),('002000000050','Phạm Ngọc Huệ','1975-08-18','Nữ','Hà Nội','Kinh','0980000050','Còn sống'),('002000000051','Đỗ Minh Phúc','1995-03-02','Nam','Hải Dương','Kinh','0980000051','Còn sống'),('002000000052','Hoàng Thu Loan','2004-06-07','Nữ','Thanh Hóa','Kinh','0980000052','Còn sống'),('002000000053','Trần Hữu Khoa','1961-02-07','Nam','Hà Nội','Kinh','0980000053','Còn sống'),('002000000054','Hoàng Hồng Huệ','1992-02-01','Nữ','Nghệ An','Kinh','0980000054','Còn sống'),('002000000055','Trần Thị Linh','1986-11-18','Nữ','Thanh Hóa','Kinh','0980000055','Còn sống'),('002000000056','Đặng Ngọc Mai','1971-02-12','Nữ','Thái Bình','Kinh','0980000056','Còn sống'),('002000000057','Ngô Thu Nga','1965-03-19','Nữ','Hà Nội','Kinh','0980000057','Còn sống'),('002000000058','Hoàng Quang Dũng','1967-04-13','Nam','Bắc Ninh','Kinh','0980000058','Còn sống'),('002000000059','Nguyễn Quang Hải','1979-10-01','Nam','Nam Định','Kinh','0980000059','Còn sống'),('002000000060','Hoàng Hồng Huệ','1956-02-28','Nữ','Nghệ An','Kinh','0980000060','Còn sống'),('002000000061','Đỗ Văn Hùng','1998-05-26','Nam','Thanh Hóa','Kinh','0980000061','Còn sống'),('002000000062','Bùi Văn Phúc','1979-12-07','Nam','Hà Nội','Kinh','0980000062','Còn sống'),('002000000063','Trần Minh Bình','2004-04-05','Nam','Hà Nội','Kinh','0980000063','Còn sống'),('002000000064','Hoàng Ngọc Lan','1979-12-10','Nữ','Thái Bình','Kinh','0980000064','Còn sống'),('002000000065','Phạm Ngọc Yến','1990-11-23','Nữ','Hải Dương','Kinh','0980000065','Còn sống'),('002000000066','Trần Hữu Sơn','2004-01-12','Nam','Thanh Hóa','Kinh','0980000066','Còn sống'),('002000000067','Bùi Quang Hải','1999-01-01','Nam','Nam Định','Kinh','0980000067','Còn sống'),('002000000068','Ngô Ngọc Lan','1976-11-13','Nữ','Nghệ An','Kinh','0980000068','Còn sống'),('002000000069','Đỗ Đức Dũng','1995-06-14','Nam','Hải Dương','Kinh','0980000069','Còn sống'),('002000000070','Hoàng Hữu Hải','1985-05-03','Nam','Thanh Hóa','Kinh','0980000070','Còn sống'),('002000000071','Phạm Hữu Hải','1987-07-19','Nam','Nghệ An','Kinh','0980000071','Còn sống'),('002000000072','Ngô Thu Mai','1987-11-07','Nữ','Bắc Ninh','Kinh','0980000072','Còn sống'),('002000000073','Hoàng Thu Lan','1967-12-28','Nữ','Thanh Hóa','Kinh','0980000073','Còn sống'),('002000000074','Hoàng Hữu Sơn','1967-07-17','Nam','Nghệ An','Kinh','0980000074','Còn sống'),('002000000075','Trần Quang Hải','1978-03-04','Nam','Bắc Ninh','Kinh','0980000075','Còn sống'),('002000000076','Đặng Văn Nam','1959-03-16','Nam','Bắc Ninh','Kinh','0980000076','Còn sống'),('002000000077','Nguyễn Đức Phúc','1979-10-13','Nam','Hà Nội','Kinh','0980000077','Còn sống'),('002000000078','Bùi Quang Bình','1975-12-16','Nam','Hà Nội','Kinh','0980000078','Còn sống'),('002000000079','Đỗ Ngọc Nga','1969-04-15','Nữ','Bắc Ninh','Kinh','0980000079','Còn sống'),('002000000080','Phạm Minh Khoa','1987-03-23','Nam','Bắc Ninh','Kinh','0980000080','Còn sống'),('002000000081','Đặng Thị Hoa','1979-09-12','Nữ','Bắc Ninh','Kinh','0980000081','Còn sống'),('002000000082','Lê Quang Khoa','1990-02-06','Nam','Bắc Ninh','Kinh','0980000082','Còn sống'),('002000000083','Ngô Thị Hương','1956-11-04','Nữ','Hà Nội','Kinh','0980000083','Còn sống'),('002000000084','Vũ Ngọc Hạnh','1984-04-18','Nữ','Bắc Ninh','Kinh','0980000084','Còn sống'),('002000000085','Bùi Hữu Nam','1994-06-21','Nam','Nam Định','Kinh','0980000085','Còn sống'),('002000000086','Bùi Thu Linh','1973-03-18','Nữ','Nam Định','Kinh','0980000086','Còn sống'),('002000000087','Lê Ngọc Hoa','1978-12-27','Nữ','Bắc Ninh','Kinh','0980000087','Còn sống'),('002000000088','Nguyễn Minh Dũng','1965-01-28','Nam','Thanh Hóa','Kinh','0980000088','Còn sống'),('002000000089','Vũ Thu Yến','1994-04-16','Nữ','Nam Định','Kinh','0980000089','Còn sống'),('002000000090','Vũ Hữu Tuấn','1979-09-19','Nam','Nghệ An','Kinh','0980000090','Còn sống'),('002000000091','Trần Văn Phúc','1975-03-28','Nam','Nam Định','Kinh','0980000091','Còn sống'),('002000000092','Nguyễn Đức Tuấn','1979-12-27','Nam','Hưng Yên','Kinh','0980000092','Còn sống'),('002000000093','Ngô Văn Dũng','2004-05-06','Nam','Thái Bình','Kinh','0980000093','Còn sống'),('002000000094','Đỗ Thị Thảo','2004-06-17','Nữ','Hải Dương','Kinh','0980000094','Còn sống'),('002000000095','Ngô Thu Hoa','2004-09-09','Nữ','Hưng Yên','Kinh','0980000095','Còn sống'),('002000000096','Vũ Thu Huệ','1998-09-12','Nữ','Hải Dương','Kinh','0980000096','Còn sống'),('002000000097','Lê Đức Thành','1964-10-12','Nam','Thanh Hóa','Kinh','0980000097','Còn sống'),('002000000098','Nguyễn Đức Sơn','1960-01-03','Nam','Nam Định','Kinh','0980000098','Còn sống'),('002000000099','Nguyễn Văn Tuấn','1972-10-21','Nam','Hưng Yên','Kinh','0980000099','Còn sống'),('002000000100','Đặng Quang Khoa','1986-09-23','Nam','Thanh Hóa','Kinh','0980000100','Còn sống'),('012331231212','Nguyễn Văn A','1997-12-10','Nam','Kim Mã','Kinh','091383128','Đã mất'),('012331231233','Nguyễn Văn B','1970-02-05','Nam','Kim Liên','Kinh','091329129','Còn sống');
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
INSERT INTO `Giay_Bao_Tu` VALUES ('BT101','2026-11-10','2026-10-10 19:00:00','Cầu Giấy','Mất máu','012331231212','CS01','NN01','XP02'),('GBT001','2024-02-01','2024-01-31 17:00:00','Tại Bệnh viện Đa khoa Trung tâm','Nhồi máu cơ tim','001000000001','CS01','NN01','XP04'),('GBT002','2024-03-04','2024-03-04 16:30:00','Tại Trạm Y tế Phường Láng Hạ','Nhồi máu cơ tim','001000000002','CS03','NN01','XP01'),('GBT003','2024-04-25','2024-04-24 23:30:00','Địa chỉ số 30, Phường Thạch Thất','Suy hô hấp','001000000003','CS02','NN04','XP08'),('GBT004','2024-08-06','2024-08-05 20:15:00','Tại Bệnh viện Quận Đống Đa','Suy hô hấp','001000000004','CS02','NN04','XP03'),('GBT005','2024-10-09','2024-10-09 17:15:00','Tại Bệnh viện Quận Đống Đa','Nhồi máu cơ tim','001000000005','CS02','NN01','XP01'),('GBT006','2024-10-16','2024-10-16 22:30:00','Địa chỉ số 16, Phường Sơn Tây','Nhồi máu cơ tim','001000000006','CS02','NN01','XP07'),('GBT007','2024-11-18','2024-11-17 13:15:00','Tại Bệnh viện Đa khoa Trung tâm','Tai nạn giao thông','001000000007','CS01','NN03','XP06'),('GBT008','2024-11-18','2024-11-18 02:30:00','Tại Phòng khám Đa khoa Cầu Giấy','Ung thư giai đoạn cuối','001000000008','CS04','NN02','XP02'),('GBT009','2025-01-24','2025-01-24 09:45:00','Địa chỉ số 33, Phường Láng Hạ','Nhồi máu cơ tim','001000000009','CS03','NN01','XP01'),('GBT010','2025-01-26','2025-01-26 11:00:00','Tại Bệnh viện Đa khoa Trung tâm','Suy hô hấp','001000000010','CS01','NN04','XP05'),('GBT011','2025-02-02','2025-02-01 05:00:00','Tại Bệnh viện Đa khoa Trung tâm','Ung thư giai đoạn cuối','001000000011','CS01','NN02','XP08'),('GBT012','2025-03-02','2025-03-02 22:45:00','Địa chỉ số 4, Phường Láng Hạ','Mất do tuổi cao, sức yếu','001000000012','CS02','NN05','XP01'),('GBT013','2025-03-11','2025-03-10 08:00:00','Tại Bệnh viện Quận Đống Đa','Suy hô hấp','001000000013','CS02','NN04','XP04'),('GBT014','2025-03-16','2025-03-15 09:30:00','Tại Phòng khám Đa khoa Cầu Giấy','Suy hô hấp','001000000014','CS04','NN04','XP02'),('GBT015','2025-04-24','2025-04-24 22:30:00','Địa chỉ số 4, Phường Ô Chợ Dừa','Mất do tuổi cao, sức yếu','001000000015','CS04','NN05','XP03'),('GBT016','2025-05-30','2025-05-29 11:45:00','Tại Trạm Y tế Phường Láng Hạ','Mất do tuổi cao, sức yếu','001000000016','CS03','NN05','XP01'),('GBT017','2025-07-24','2025-07-23 05:45:00','Tại Trạm Y tế Phường Láng Hạ','Nhồi máu cơ tim','001000000017','CS03','NN01','XP01'),('GBT018','2025-08-04','2025-08-03 07:30:00','Địa chỉ số 50, Phường Sơn Tây','Ung thư giai đoạn cuối','001000000018','CS01','NN02','XP07'),('GBT019','2025-10-04','2025-10-04 18:45:00','Tại Phòng khám Đa khoa Cầu Giấy','Suy hô hấp','001000000019','CS04','NN04','XP02'),('GBT020','2025-10-13','2025-10-13 08:15:00','Tại Trạm Y tế Phường Láng Hạ','Nguyên nhân khác đã được bác sĩ xác nhận','001000000020','CS03','NN06','XP01'),('GBT021','2025-10-20','2025-10-20 11:45:00','Địa chỉ số 27, Phường Thạch Thất','Nguyên nhân khác đã được bác sĩ xác nhận','001000000021','CS03','NN06','XP08'),('GBT022','2025-10-24','2025-10-23 00:15:00','Tại Bệnh viện Đa khoa Trung tâm','Nhồi máu cơ tim','001000000022','CS01','NN01','XP03'),('GBT023','2025-10-27','2025-10-26 03:15:00','Tại Trạm Y tế Phường Láng Hạ','Suy hô hấp','001000000023','CS03','NN04','XP01'),('GBT024','2025-10-28','2025-10-27 11:30:00','Địa chỉ số 36, Phường Kim Mã','Tai nạn giao thông','001000000024','CS03','NN03','XP05'),('GBT025','2026-07-07','2026-07-06 10:30:00','Tại Bệnh viện Đa khoa Trung tâm','Nhồi máu cơ tim','001000000025','CS01','NN01','XP02'),('GBT026','2026-07-09','2026-07-08 23:00:00','Tại Trạm Y tế Phường Láng Hạ','Nhồi máu cơ tim','001000000026','CS03','NN01','XP01'),('GBT027','2026-07-10','2026-07-09 11:00:00','Địa chỉ số 7, Phường Thanh Xuân','Suy hô hấp','001000000027','CS01','NN04','XP04'),('GBT028','2026-07-11','2026-07-10 00:30:00','Tại Bệnh viện Đa khoa Trung tâm','Ung thư giai đoạn cuối','001000000028','CS01','NN02','XP03'),('GBT029','2026-07-11','2026-07-10 23:30:00','Tại Bệnh viện Đa khoa Trung tâm','Ung thư giai đoạn cuối','001000000029','CS01','NN02','XP01'),('GBT030','2026-07-12','2026-07-11 04:30:00','Địa chỉ số 9, Phường Cầu Giấy','Nhồi máu cơ tim','001000000030','CS01','NN01','XP02'),('GBT031','2026-07-13','2026-07-13 11:00:00','Tại Phòng khám Đa khoa Cầu Giấy','Suy hô hấp','001000000031','CS04','NN04','XP02'),('GBT032','2026-07-14','2026-07-14 15:45:00','Tại Bệnh viện Đa khoa Trung tâm','Nhồi máu cơ tim','001000000032','CS01','NN01','XP03'),('GBT033','2026-07-17','2026-07-16 02:30:00','Địa chỉ số 79, Phường Kim Mã','Ung thư giai đoạn cuối','001000000033','CS01','NN02','XP05'),('GBT034','2026-07-21','2026-07-20 17:00:00','Tại Bệnh viện Đa khoa Trung tâm','Nguyên nhân khác đã được bác sĩ xác nhận','001000000034','CS01','NN06','XP06'),('GBT035','2026-07-23','2026-07-22 04:30:00','Tại Bệnh viện Đa khoa Trung tâm','Ung thư giai đoạn cuối','001000000035','CS01','NN02','XP06'),('GBT036','2026-07-25','2026-07-24 07:15:00','Địa chỉ số 86, Phường Kim Mã','Mất do tuổi cao, sức yếu','001000000036','CS02','NN05','XP05'),('GBT037','2026-07-24','2026-07-24 01:00:00','Tại Bệnh viện Đa khoa Trung tâm','Nhồi máu cơ tim','001000000037','CS01','NN01','XP03'),('GBT038','2026-07-25','2026-07-25 23:30:00','Tại Bệnh viện Đa khoa Trung tâm','Nguyên nhân khác đã được bác sĩ xác nhận','001000000038','CS01','NN06','XP07'),('GBT039','2026-07-27','2026-07-27 12:00:00','Địa chỉ số 4, Phường Cầu Giấy','Ung thư giai đoạn cuối','001000000039','CS01','NN02','XP02'),('GBT040','2026-08-02','2026-08-01 01:00:00','Tại Bệnh viện Đa khoa Trung tâm','Mất do tuổi cao, sức yếu','001000000040','CS01','NN05','XP02'),('GBT041','2026-08-02','2026-08-01 22:00:00','Tại Bệnh viện Đa khoa Trung tâm','Ung thư giai đoạn cuối','001000000041','CS01','NN02','XP07'),('GBT042','2026-08-07','2026-08-06 11:00:00','Địa chỉ số 55, Phường Láng Hạ','Ung thư giai đoạn cuối','001000000042','CS01','NN02','XP01'),('GBT043','2026-08-08','2026-08-08 20:15:00','Tại Bệnh viện Đa khoa Trung tâm','Suy hô hấp','001000000043','CS01','NN04','XP05'),('GBT044','2026-08-09','2026-08-08 06:45:00','Tại Bệnh viện Đa khoa Trung tâm','Ung thư giai đoạn cuối','001000000044','CS01','NN02','XP01'),('GBT045','2026-08-10','2026-08-09 08:00:00','Địa chỉ số 92, Phường Ô Chợ Dừa','Ung thư giai đoạn cuối','001000000045','CS01','NN02','XP03'),('GBT046','2026-08-11','2026-08-10 16:00:00','Tại Bệnh viện Đa khoa Trung tâm','Suy hô hấp','001000000046','CS01','NN04','XP07'),('GBT047','2026-08-10','2026-08-10 14:15:00','Tại Bệnh viện Đa khoa Trung tâm','Nguyên nhân khác đã được bác sĩ xác nhận','001000000047','CS01','NN06','XP02'),('GBT048','2026-08-14','2026-08-13 07:30:00','Địa chỉ số 55, Phường Cầu Giấy','Ung thư giai đoạn cuối','001000000048','CS01','NN02','XP02'),('GBT049','2026-08-14','2026-08-13 05:45:00','Tại Bệnh viện Đa khoa Trung tâm','Nhồi máu cơ tim','001000000049','CS01','NN01','XP04'),('GBT050','2026-08-14','2026-08-13 14:15:00','Tại Bệnh viện Đa khoa Trung tâm','Suy hô hấp','001000000050','CS01','NN04','XP08'),('GBT051','2026-08-15','2026-08-14 20:15:00','Địa chỉ số 44, Phường Thạch Thất','Suy hô hấp','001000000051','CS01','NN04','XP08'),('GBT052','2026-08-17','2026-08-16 10:15:00','Tại Bệnh viện Đa khoa Trung tâm','Nhồi máu cơ tim','001000000052','CS01','NN01','XP03'),('GBT053','2026-08-17','2026-08-17 20:15:00','Tại Bệnh viện Đa khoa Trung tâm','Suy hô hấp','001000000053','CS01','NN04','XP01'),('GBT054','2026-08-23','2026-08-23 15:45:00','Địa chỉ số 28, Phường Ô Chợ Dừa','Nhồi máu cơ tim','001000000054','CS01','NN01','XP03'),('GBT055','2026-08-23','2026-08-23 21:30:00','Tại Bệnh viện Đa khoa Trung tâm','Suy hô hấp','001000000055','CS01','NN04','XP01'),('GBT056','2026-08-25','2026-08-24 15:45:00','Tại Bệnh viện Đa khoa Trung tâm','Suy hô hấp','001000000056','CS01','NN04','XP06'),('GBT057','2026-08-28','2026-08-27 04:15:00','Địa chỉ số 70, Phường Thạch Thất','Ung thư giai đoạn cuối','001000000057','CS03','NN02','XP08'),('GBT058','2026-08-28','2026-08-28 15:15:00','Tại Bệnh viện Đa khoa Trung tâm','Ung thư giai đoạn cuối','001000000058','CS01','NN02','XP04'),('GBT059','2026-08-29','2026-08-29 06:45:00','Tại Bệnh viện Đa khoa Trung tâm','Mất do tuổi cao, sức yếu','001000000059','CS01','NN05','XP05'),('GBT060','2026-09-02','2026-09-01 22:00:00','Địa chỉ số 83, Phường Cầu Giấy','Mất do tuổi cao, sức yếu','001000000060','CS01','NN05','XP02'),('GBT061','2026-09-03','2026-09-02 03:15:00','Tại Bệnh viện Đa khoa Trung tâm','Mất do tuổi cao, sức yếu','001000000061','CS01','NN05','XP04'),('GBT062','2026-09-03','2026-09-02 07:00:00','Tại Bệnh viện Đa khoa Trung tâm','Nhồi máu cơ tim','001000000062','CS01','NN01','XP08'),('GBT063','2026-09-03','2026-09-02 18:30:00','Địa chỉ số 63, Phường Cầu Giấy','Tai nạn giao thông','001000000063','CS01','NN03','XP02'),('GBT064','2026-09-04','2026-09-04 14:30:00','Tại Bệnh viện Đa khoa Trung tâm','Mất do tuổi cao, sức yếu','001000000064','CS01','NN05','XP01'),('GBT065','2026-09-06','2026-09-06 06:00:00','Tại Bệnh viện Đa khoa Trung tâm','Ung thư giai đoạn cuối','001000000065','CS01','NN02','XP01'),('GBT066','2026-09-07','2026-09-07 03:30:00','Địa chỉ số 74, Phường Láng Hạ','Nhồi máu cơ tim','001000000066','CS01','NN01','XP01'),('GBT067','2026-09-10','2026-09-09 08:00:00','Tại Bệnh viện Đa khoa Trung tâm','Ung thư giai đoạn cuối','001000000067','CS01','NN02','XP08'),('GBT068','2026-09-11','2026-09-10 12:00:00','Tại Bệnh viện Đa khoa Trung tâm','Nhồi máu cơ tim','001000000068','CS01','NN01','XP07'),('GBT069','2026-09-11','2026-09-10 07:15:00','Địa chỉ số 82, Phường Láng Hạ','Nhồi máu cơ tim','001000000069','CS01','NN01','XP01'),('GBT070','2026-09-11','2026-09-11 14:00:00','Tại Bệnh viện Đa khoa Trung tâm','Nhồi máu cơ tim','001000000070','CS01','NN01','XP07'),('GBT071','2026-09-12','2026-09-12 11:15:00','Tại Bệnh viện Đa khoa Trung tâm','Mất do tuổi cao, sức yếu','001000000071','CS01','NN05','XP06'),('GBT072','2026-09-13','2026-09-12 23:45:00','Địa chỉ số 14, Phường Láng Hạ','Mất do tuổi cao, sức yếu','001000000072','CS01','NN05','XP01'),('GBT073','2026-09-12','2026-09-12 14:30:00','Tại Bệnh viện Đa khoa Trung tâm','Suy hô hấp','001000000073','CS01','NN04','XP03'),('GBT074','2026-09-13','2026-09-13 14:30:00','Tại Bệnh viện Đa khoa Trung tâm','Suy hô hấp','001000000074','CS01','NN04','XP08'),('GBT075','2026-09-13','2026-09-13 16:45:00','Địa chỉ số 65, Phường Thanh Xuân','Ung thư giai đoạn cuối','001000000075','CS01','NN02','XP04'),('GBT076','2026-09-16','2026-09-15 18:15:00','Tại Bệnh viện Đa khoa Trung tâm','Nhồi máu cơ tim','001000000076','CS01','NN01','XP03'),('GBT077','2026-09-16','2026-09-16 07:45:00','Tại Bệnh viện Đa khoa Trung tâm','Mất do tuổi cao, sức yếu','001000000077','CS01','NN05','XP01'),('GBT078','2026-09-18','2026-09-18 02:15:00','Địa chỉ số 24, Phường Láng Hạ','Nhồi máu cơ tim','001000000078','CS01','NN01','XP01'),('GBT079','2026-09-20','2026-09-20 07:45:00','Tại Bệnh viện Đa khoa Trung tâm','Ung thư giai đoạn cuối','001000000079','CS01','NN02','XP01'),('GBT080','2026-09-24','2026-09-24 18:30:00','Tại Bệnh viện Đa khoa Trung tâm','Nguyên nhân khác đã được bác sĩ xác nhận','001000000080','CS01','NN06','XP04'),('GBT081','2026-10-01','2026-10-01 02:30:00','Địa chỉ số 92, Phường Sơn Tây','Nhồi máu cơ tim','001000000081','CS03','NN01','XP07'),('GBT082','2026-10-01','2026-10-01 08:15:00','Tại Bệnh viện Đa khoa Trung tâm','Mất do tuổi cao, sức yếu','001000000082','CS01','NN05','XP03'),('GBT083','2026-10-02','2026-10-02 06:30:00','Tại Phòng khám Đa khoa Cầu Giấy','Ung thư giai đoạn cuối','001000000083','CS04','NN02','XP02'),('GBT084','2026-10-03','2026-10-02 01:15:00','Địa chỉ số 26, Phường Kim Mã','Nhồi máu cơ tim','001000000084','CS04','NN01','XP05'),('GBT085','2026-10-03','2026-10-02 05:15:00','Tại Bệnh viện Quận Đống Đa','Suy hô hấp','001000000085','CS02','NN04','XP02'),('GBT086','2026-10-03','2026-10-02 00:45:00','Tại Trạm Y tế Phường Láng Hạ','Nhồi máu cơ tim','001000000086','CS03','NN01','XP01'),('GBT087','2026-10-04','2026-10-03 12:15:00','Địa chỉ số 18, Phường Hà Đông','Tai nạn giao thông','001000000087','CS02','NN03','XP06'),('GBT088','2026-10-06','2026-10-05 06:15:00','Tại Bệnh viện Đa khoa Trung tâm','Suy hô hấp','001000000088','CS01','NN04','XP07'),('GBT089','2026-10-06','2026-10-05 16:45:00','Tại Phòng khám Đa khoa Cầu Giấy','Ung thư giai đoạn cuối','001000000089','CS04','NN02','XP02'),('GBT090','2026-10-06','2026-10-05 16:15:00','Địa chỉ số 30, Phường Ô Chợ Dừa','Ung thư giai đoạn cuối','001000000090','CS03','NN02','XP03'),('GBT091','2026-10-06','2026-10-06 14:45:00','Tại Phòng khám Đa khoa Cầu Giấy','Mất do tuổi cao, sức yếu','001000000091','CS04','NN05','XP02'),('GBT092','2026-10-06','2026-10-06 08:00:00','Tại Trạm Y tế Phường Láng Hạ','Nhồi máu cơ tim','001000000092','CS03','NN01','XP01'),('GBT093','2026-10-07','2026-10-07 21:45:00','Địa chỉ số 2, Phường Láng Hạ','Tai nạn giao thông','001000000093','CS03','NN03','XP01'),('GBT094','2026-10-08','2026-10-08 04:00:00','Tại Trạm Y tế Phường Láng Hạ','Tai nạn giao thông','001000000094','CS03','NN03','XP01'),('GBT095','2026-10-08','2026-10-08 18:15:00','Tại Bệnh viện Quận Đống Đa','Suy hô hấp','001000000095','CS02','NN04','XP07'),('GBT096','2026-10-08','2026-10-08 11:15:00','Địa chỉ số 52, Phường Thạch Thất','Nhồi máu cơ tim','001000000096','CS01','NN01','XP08'),('GBT097','2026-10-08','2026-10-08 22:45:00','Tại Trạm Y tế Phường Láng Hạ','Ung thư giai đoạn cuối','001000000097','CS03','NN02','XP01'),('GBT098','2026-10-10','2026-10-10 23:15:00','Tại Trạm Y tế Phường Láng Hạ','Ung thư giai đoạn cuối','001000000098','CS03','NN02','XP01'),('GBT099','2026-10-10','2026-10-10 13:30:00','Địa chỉ số 27, Phường Ô Chợ Dừa','Mất do tuổi cao, sức yếu','001000000099','CS01','NN05','XP03'),('GBT100','2026-10-10','2026-10-10 11:30:00','Tại Bệnh viện Đa khoa Trung tâm','Ung thư giai đoạn cuối','001000000100','CS01','NN02','XP08');
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
INSERT INTO `Ho_So_Khai_Tu` VALUES ('HS001','GBT001','2024-02-01','002000000001','Cháu','Từ chối','CB03'),('HS002','GBT002','2024-03-04','002000000002','Con','Chờ xử lý','CB02'),('HS003','GBT003','2024-04-25','002000000003','Con','Đã duyệt','CB02'),('HS004','GBT004','2024-08-08','002000000004','Cháu','Đã duyệt','CB06'),('HS005','GBT005','2024-10-12','002000000005','Anh/Chị/Em','Đã duyệt','CB05'),('HS006','GBT006','2024-10-19','002000000006','Con','Đã duyệt','CB01'),('HS007','GBT007','2024-11-20','002000000007','Cháu','Đã duyệt','CB04'),('HS008','GBT008','2024-11-19','002000000008','Cháu','Đã duyệt','CB03'),('HS009','GBT009','2025-01-26','002000000009','Con','Từ chối','CB06'),('HS010','GBT010','2025-01-26','002000000010','Con','Đã duyệt','CB06'),('HS011','GBT011','2025-02-05','002000000011','Chồng','Đã duyệt','CB01'),('HS012','GBT012','2025-03-02','002000000012','Anh/Chị/Em','Đã duyệt','CB03'),('HS013','GBT013','2025-03-12','002000000013','Cháu','Đã duyệt','CB04'),('HS014','GBT014','2025-03-19','002000000014','Con','Đã duyệt','CB01'),('HS015','GBT015','2025-04-27','002000000015','Con','Đã duyệt','CB04'),('HS016','GBT016','2025-05-30','002000000016','Con','Đã duyệt','CB02'),('HS017','GBT017','2025-07-26','002000000017','Con','Đã duyệt','CB02'),('HS018','GBT018','2025-08-05','002000000018','Anh/Chị/Em','Đã duyệt','CB02'),('HS019','GBT019','2025-10-04','002000000019','Cháu','Đã duyệt','CB02'),('HS020','GBT020','2025-10-13','002000000020','Anh/Chị/Em','Đã duyệt','CB02'),('HS021','GBT021','2025-10-20','002000000021','Con','Từ chối','CB03'),('HS022','GBT022','2025-10-24','002000000022','Con','Đã duyệt','CB03'),('HS023','GBT023','2025-10-29','002000000023','Cháu','Đã duyệt','CB02'),('HS024','GBT024','2025-10-28','002000000024','Con','Đã duyệt','CB05'),('HS025','GBT025','2026-07-09','002000000025','Cháu','Đã duyệt','CB02'),('HS026','GBT026','2026-07-11','002000000026','Cháu','Đã duyệt','CB02'),('HS027','GBT027','2026-07-11','002000000027','Con','Từ chối','CB05'),('HS028','GBT028','2026-07-13','002000000028','Con','Đã duyệt','CB01'),('HS029','GBT029','2026-07-14','002000000029','Cháu','Đã duyệt','CB04'),('HS030','GBT030','2026-07-13','002000000030','Con','Đã duyệt','CB02'),('HS031','GBT031','2026-07-14','002000000031','Cháu','Đã duyệt','CB03'),('HS032','GBT032','2026-07-14','002000000032','Con','Đã duyệt','CB04'),('HS033','GBT033','2026-07-18','002000000033','Anh/Chị/Em','Đã duyệt','CB04'),('HS034','GBT034','2026-07-24','002000000034','Cháu','Từ chối','CB05'),('HS035','GBT035','2026-07-26','002000000035','Vợ','Đã duyệt','CB05'),('HS036','GBT036','2026-07-25','002000000036','Anh/Chị/Em','Đã duyệt','CB03'),('HS037','GBT037','2026-07-25','002000000037','Con','Đã duyệt','CB06'),('HS038','GBT038','2026-07-27','002000000038','Con','Đã duyệt','CB02'),('HS039','GBT039','2026-07-28','002000000039','Cháu','Đã duyệt','CB02'),('HS040','GBT040','2026-08-05','002000000040','Con','Đã duyệt','CB06'),('HS041','GBT041','2026-08-03','002000000041','Cháu','Đã duyệt','CB01'),('HS042','GBT042','2026-08-10','002000000042','Cháu','Đã duyệt','CB03'),('HS043','GBT043','2026-08-10','002000000043','Con','Đã duyệt','CB02'),('HS044','GBT044','2026-08-09','002000000044','Chồng','Đã duyệt','CB05'),('HS045','GBT045','2026-08-11','002000000045','Con','Đã duyệt','CB04'),('HS046','GBT046','2026-08-13','002000000046','Con','Đã duyệt','CB06'),('HS047','GBT047','2026-08-11','002000000047','Anh/Chị/Em','Đã duyệt','CB05'),('HS048','GBT048','2026-08-17','002000000048','Chồng','Đã duyệt','CB03'),('HS049','GBT049','2026-08-15','002000000049','Con','Đã duyệt','CB06'),('HS050','GBT050','2026-08-15','002000000050','Vợ','Đã duyệt','CB03'),('HS051','GBT051','2026-08-15','002000000051','Chồng','Đã duyệt','CB05'),('HS052','GBT052','2026-08-19','002000000052','Cháu','Đã duyệt','CB01'),('HS053','GBT053','2026-08-18','002000000053','Anh/Chị/Em','Đã duyệt','CB06'),('HS054','GBT054','2026-08-23','002000000054','Con','Đã duyệt','CB04'),('HS055','GBT055','2026-08-23','002000000055','Con','Đã duyệt','CB06'),('HS056','GBT056','2026-08-27','002000000056','Anh/Chị/Em','Đã duyệt','CB06'),('HS057','GBT057','2026-08-31','002000000057','Con','Đã duyệt','CB02'),('HS058','GBT058','2026-08-29','002000000058','Anh/Chị/Em','Đã duyệt','CB03'),('HS059','GBT059','2026-08-31','002000000059','Anh/Chị/Em','Đã duyệt','CB05'),('HS060','GBT060','2026-09-04','002000000060','Anh/Chị/Em','Từ chối','CB06'),('HS061','GBT061','2026-09-03','002000000061','Chồng','Đã duyệt','CB04'),('HS062','GBT062','2026-09-04','002000000062','Con','Đã duyệt','CB06'),('HS063','GBT063','2026-09-04','002000000063','Cháu','Đã duyệt','CB04'),('HS064','GBT064','2026-09-07','002000000064','Cháu','Đã duyệt','CB04'),('HS065','GBT065','2026-09-09','002000000065','Vợ','Đã duyệt','CB06'),('HS066','GBT066','2026-09-09','002000000066','Con','Đã duyệt','CB01'),('HS067','GBT067','2026-09-11','002000000067','Con','Đã duyệt','CB06'),('HS068','GBT068','2026-09-13','002000000068','Anh/Chị/Em','Đã duyệt','CB05'),('HS069','GBT069','2026-09-14','002000000069','Chồng','Đã duyệt','CB01'),('HS070','GBT070','2026-09-13','002000000070','Con','Đã duyệt','CB06'),('HS071','GBT071','2026-09-14','002000000071','Chồng','Đã duyệt','CB02'),('HS072','GBT072','2026-09-14','002000000072','Con','Đã duyệt','CB05'),('HS073','GBT073','2026-09-14','002000000073','Cháu','Đã duyệt','CB01'),('HS074','GBT074','2026-09-15','002000000074','Chồng','Đã duyệt','CB01'),('HS075','GBT075','2026-09-15','002000000075','Chồng','Đã duyệt','CB01'),('HS076','GBT076','2026-09-16','002000000076','Anh/Chị/Em','Đã duyệt','CB01'),('HS077','GBT077','2026-09-19','002000000077','Anh/Chị/Em','Đã duyệt','CB01'),('HS078','GBT078','2026-09-20','002000000078','Anh/Chị/Em','Từ chối','CB03'),('HS079','GBT079','2026-09-22','002000000079','Con','Đã duyệt','CB02'),('HS080','GBT080','2026-09-27','002000000080','Anh/Chị/Em','Chờ xử lý','CB01'),('HS081','GBT081','2026-10-02','002000000081','Con','Chờ xử lý','CB04'),('HS082','GBT082','2026-10-04','002000000082','Cháu','Đã duyệt','CB02'),('HS083','GBT083','2026-10-05','002000000083','Con','Chờ xử lý','CB04'),('HS084','GBT084','2026-10-05','002000000084','Con','Chờ xử lý','CB06'),('HS085','GBT085','2026-10-06','002000000085','Con','Chờ xử lý','CB04'),('HS086','GBT086','2026-10-03','002000000086','Vợ','Đã duyệt','CB04'),('HS087','GBT087','2026-10-06','002000000087','Vợ','Đã duyệt','CB03'),('HS088','GBT088','2026-10-06','002000000088','Con','Chờ xử lý','CB01'),('HS089','GBT089','2026-10-07','002000000089','Con','Chờ xử lý','CB03'),('HS090','GBT090','2026-10-09','002000000090','Cháu','Đã duyệt','CB02'),('HS091','GBT091','2026-10-07','002000000091','Anh/Chị/Em','Đã duyệt','CB01'),('HS092','GBT092','2026-10-08','002000000092','Anh/Chị/Em','Chờ xử lý','CB05'),('HS093','GBT093','2026-10-09','002000000093','Con','Chờ xử lý','CB02'),('HS094','GBT094','2026-10-09','002000000094','Cháu','Chờ xử lý','CB03'),('HS095','GBT095','2026-10-08','002000000095','Con','Chờ xử lý','CB03'),('HS096','GBT096','2026-10-09','002000000096','Vợ','Chờ xử lý','CB03'),('HS097','GBT097','2026-10-11','002000000097','Anh/Chị/Em','Chờ xử lý','CB02'),('HS098','GBT098','2026-10-11','002000000098','Con','Đã duyệt','CB02'),('HS099','GBT099','2026-10-10','002000000099','Chồng','Chờ xử lý','CB01'),('HS100','GBT100','2026-10-12','002000000100','Cháu','Chờ xử lý','CB06'),('HS101','BT101','2026-11-10','012331231233','Con','Chờ xử lý','CB02');
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
INSERT INTO `Nguyen_Nhan` VALUES ('NN01','Bệnh tim mạch'),('NN02','Ung thư'),('NN03','Tai nạn giao thông'),('NN04','Bệnh hô hấp'),('NN05','Tuổi già'),('NN06','Nguyên nhân khác');
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
INSERT INTO `Noi_Mat` VALUES ('XP01','Phường Láng Hạ'),('XP02','Phường Cầu Giấy'),('XP03','Phường Ô Chợ Dừa'),('XP04','Phường Thanh Xuân'),('XP05','Phường Kim Mã'),('XP06','Phường Hà Đông'),('XP07','Phường Sơn Tây'),('XP08','Phường Thạch Thất');
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
INSERT INTO `UBND` VALUES ('UB01','UBND Phường Láng Hạ','Phường','1 Láng Hạ, Hà Nội','0242000001'),('UB02','UBND Phường Cầu Giấy','Phường','2 Cầu Giấy, Hà Nội','0242000002'),('UB03','UBND Phường Kim Mã','Phường','3 Kim Mã, Hà Nội','0242000003');
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

-- Dump completed on 2026-11-12 11:41:47
