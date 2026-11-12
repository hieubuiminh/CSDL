-- CHI DOC. Khong thay doi cau truc bang hoac du lieu.
SET NAMES utf8mb4;
USE quan_ly_dang_ky_khai_tu;

-- Chi tra so luong, khong xuat ten/CCCD.
SELECT
  (SELECT COUNT(*) FROM Ho_So_Khai_Tu) AS TongHoSo,
  (SELECT COUNT(*) FROM Ho_So_Khai_Tu
   WHERE CCCD_NgKhaiTu = CCCD_NgMat) AS NguoiKhaiTrungNguoiMat,
  (SELECT COUNT(*) FROM Giay_Bao_Tu
   WHERE DATE(NgayGioMat) > NgayCap) AS NgayMatSauNgayCap,
  (SELECT COUNT(*) FROM Ho_So_Khai_Tu h
   JOIN Giay_Bao_Tu g ON g.SoGiayBaoTu = h.SoGiayBaoTu
   WHERE g.NgayCap > h.NgayDangKi) AS NgayCapSauNgayDangKy,
  (SELECT COUNT(*) FROM (
     SELECT CCCD_NgMat FROM Ho_So_Khai_Tu
     GROUP BY CCCD_NgMat HAVING COUNT(*) > 1
   ) nguoi_trung) AS CongDanCoNhieuHoSo,
  (SELECT COUNT(*) FROM (
     SELECT SoGiayBaoTu FROM Ho_So_Khai_Tu
     GROUP BY SoGiayBaoTu HAVING COUNT(*) > 1
   ) giay_trung) AS GiayBaoTuGanNhieuHoSo,
  (SELECT COUNT(*) FROM (
     SELECT SoGiayKhaiTu FROM An_Tang
     GROUP BY SoGiayKhaiTu HAVING COUNT(*) > 1
   ) an_tang_trung) AS HoSoCoNhieuAnTang,
  (SELECT COUNT(*) FROM (
     SELECT CCCD FROM Can_Bo GROUP BY CCCD HAVING COUNT(*) > 1
   ) can_bo_trung) AS CanBoTrungCCCD,
  (SELECT COUNT(*) FROM Cong_Dan
   WHERE NOT REGEXP_LIKE(CCCD, '^[0-9]{12}$', 'c')) AS CCCDCongDanKhongHopLe,
  (SELECT COUNT(*) FROM Can_Bo
   WHERE NOT REGEXP_LIKE(CCCD, '^[0-9]{12}$', 'c')) AS CCCDCanBoKhongHopLe,
  (SELECT COUNT(*) FROM Cong_Dan c
   WHERE (c.TrangThai IS NULL OR BINARY c.TrangThai <> BINARY 'Đã mất')
     AND EXISTS (SELECT 1 FROM Ho_So_Khai_Tu h
                 WHERE h.CCCD_NgMat = c.CCCD AND h.TrangThaiHoSo <> 'Từ chối')
  ) AS CongDanCoHoSoNhungChuaDaMat;

-- Xem cac rang buoc da ton tai, khong tu them rang buoc.
SELECT CONSTRAINT_NAME AS TenRangBuoc, CONSTRAINT_TYPE AS LoaiRangBuoc
FROM information_schema.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME IN ('Ho_So_Khai_Tu','Giay_Bao_Tu','Cong_Dan','Can_Bo','An_Tang')
ORDER BY TABLE_NAME, CONSTRAINT_TYPE, CONSTRAINT_NAME;

-- Xac nhan co UNIQUE chi tren cot CCCD_NgMat hay khong.
SELECT INDEX_NAME AS TenChiMucDuyNhat
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'Ho_So_Khai_Tu'
  AND NON_UNIQUE = 0
GROUP BY INDEX_NAME
HAVING COUNT(*) = 1 AND MAX(COLUMN_NAME) = 'CCCD_NgMat';
