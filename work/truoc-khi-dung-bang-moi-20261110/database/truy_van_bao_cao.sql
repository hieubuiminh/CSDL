-- 7 truy vấn đối chiếu mục 3.4 của báo cáo; chỉ đọc, không đổi dữ liệu.
-- MySQL >= 8.0.16. Chạy sau khi khởi tạo hoặc nâng cấp schema.
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
SET time_zone = '+07:00';
USE quan_ly_dang_ky_khai_tu;
SET @cccd = '000000000000'; -- Thay bằng CCCD cần tra cứu.
SET @ngay_bao_cao = CURDATE(); -- Có thể thay bằng ngày chốt báo cáo.
SET @nam_bao_cao = YEAR(@ngay_bao_cao);

-- 1. Tra cứu và trích lục; hiện cả trạng thái để nhận biết hồ sơ bị từ chối.
SELECT h.SoGiayKhaiTu, d.CCCD, d.HoTen AS NguoiDaMat, d.NgaySinh,
       g.NgayGioMat, nn.TenNguyenNhan, g.MoTaNguyenNhan,
       k.HoTen AS NguoiDiKhaiTu, h.QuanHe,
       u.TenUBND AS DonViCapKhaiTu, h.NgayDangKi, h.TrangThaiHoSo
FROM Ho_So_Khai_Tu h
JOIN Cong_Dan d ON d.CCCD = h.CCCD_NgMat
JOIN Cong_Dan k ON k.CCCD = h.CCCD_NgKhaiTu
JOIN Giay_Bao_Tu g ON g.SoGiayBaoTu = h.SoGiayBaoTu
JOIN Nguyen_Nhan nn ON nn.MaNguyenNhan = g.MaNguyenNhan
JOIN Can_Bo cb ON cb.MaCanBo = h.MaCanBoTiepNhan
JOIN UBND u ON u.MaUBND = cb.MaUBND
WHERE d.CCCD = @cccd;

-- 2. Giới tính: theo trạng thái sinh tử của công dân, đúng truy vấn 3.4.2.
SELECT GioiTinh, COUNT(*) AS SoNguoiDaMat
FROM Cong_Dan
WHERE TrangThai = 'Đã mất'
GROUP BY GioiTinh
ORDER BY GioiTinh;

-- 3. Toàn bộ hồ sơ, bao gồm hồ sơ bị từ chối.
SELECT h.SoGiayKhaiTu, d.HoTen AS NguoiDaMat, k.HoTen AS NguoiDangKy,
       h.NgayDangKi, u.TenUBND AS DonViTiepNhan, h.TrangThaiHoSo
FROM Ho_So_Khai_Tu h
JOIN Cong_Dan d ON d.CCCD = h.CCCD_NgMat
JOIN Cong_Dan k ON k.CCCD = h.CCCD_NgKhaiTu
JOIN Can_Bo cb ON cb.MaCanBo = h.MaCanBoTiepNhan
JOIN UBND u ON u.MaUBND = cb.MaUBND
ORDER BY h.NgayDangKi, h.SoGiayKhaiTu;

-- 4. Địa bàn: báo cáo giả định TOÀN BỘ Noi_Mat là Xã/Phường thuộc Hà Nội.
-- Bảng hiện chưa có tỉnh/thành, không thể xác định Hà Nội bằng mã hoặc tên.
-- Nếu danh mục chứa địa phương khác, phải bổ sung dữ liệu phân loại trước.
SELECT n.MaXaPhuong, n.TenXaPhuong, COUNT(h.SoGiayKhaiTu) AS TongSoCaKhaiTu
FROM Noi_Mat n
LEFT JOIN Giay_Bao_Tu g ON g.MaXaPhuong = n.MaXaPhuong
LEFT JOIN Ho_So_Khai_Tu h ON h.SoGiayBaoTu = g.SoGiayBaoTu
  AND h.TrangThaiHoSo <> 'Từ chối'
  AND h.NgayDangKi >= MAKEDATE(@nam_bao_cao, 1)
  AND h.NgayDangKi < MAKEDATE(@nam_bao_cao + 1, 1)
GROUP BY n.MaXaPhuong, n.TenXaPhuong
ORDER BY TongSoCaKhaiTu DESC, n.TenXaPhuong, n.MaXaPhuong;

-- 5. Tuổi tròn tại ngày mất; loại hồ sơ từ chối, giữ đủ ba nhóm và mọi đồng hạng.
WITH NhomTuoi AS (
  SELECT 1 AS ThuTu, 'Dưới 18' AS NhomTuoi
  UNION ALL SELECT 2, '18–60'
  UNION ALL SELECT 3, 'Trên 60'
), Tuoi AS (
  SELECT TIMESTAMPDIFF(YEAR, d.NgaySinh, DATE(g.NgayGioMat)) AS SoTuoi,
         g.MaNguyenNhan
  FROM Ho_So_Khai_Tu h
  JOIN Cong_Dan d ON d.CCCD = h.CCCD_NgMat
  JOIN Giay_Bao_Tu g ON g.SoGiayBaoTu = h.SoGiayBaoTu
  WHERE h.TrangThaiHoSo <> 'Từ chối'
    AND d.NgaySinh <= DATE(g.NgayGioMat)
), PhanNhom AS (
  SELECT CASE WHEN SoTuoi < 18 THEN 1 WHEN SoTuoi <= 60 THEN 2 ELSE 3 END AS ThuTu,
         MaNguyenNhan
  FROM Tuoi
), Tong AS (
  SELECT ThuTu, COUNT(*) AS SoNguoiDaMat FROM PhanNhom GROUP BY ThuTu
), TanSuat AS (
  SELECT ThuTu, MaNguyenNhan, COUNT(*) AS SoCaTheoNguyenNhan
  FROM PhanNhom GROUP BY ThuTu, MaNguyenNhan
), XepHang AS (
  SELECT *, DENSE_RANK() OVER (PARTITION BY ThuTu ORDER BY SoCaTheoNguyenNhan DESC) AS Hang
  FROM TanSuat
)
SELECT n.NhomTuoi, COALESCE(t.SoNguoiDaMat, 0) AS SoNguoiDaMat,
       x.MaNguyenNhan, nn.TenNguyenNhan AS NguyenNhanPhoBienNhat,
       COALESCE(x.SoCaTheoNguyenNhan, 0) AS SoCaTheoNguyenNhan
FROM NhomTuoi n
LEFT JOIN Tong t ON t.ThuTu = n.ThuTu
LEFT JOIN XepHang x ON x.ThuTu = n.ThuTu AND x.Hang = 1
LEFT JOIN Nguyen_Nhan nn ON nn.MaNguyenNhan = x.MaNguyenNhan
ORDER BY n.ThuTu, x.MaNguyenNhan;

-- 6. Quý lịch hoàn chỉnh liền trước; trên 50, không bao gồm đúng 50.
-- Hai cột cuối CHỈ ƯỚC TÍNH từ địa chỉ/tên, không khẳng định nơi mất thực tế.
-- Muốn chính xác cần ghi nhận riêng nơi mất có phải chính CSYT cấp giấy hay không.
SET @dau_quy_nay = MAKEDATE(YEAR(@ngay_bao_cao), 1)
  + INTERVAL (QUARTER(@ngay_bao_cao) - 1) QUARTER;
SET @dau_quy_truoc = @dau_quy_nay - INTERVAL 1 QUARTER;
WITH GiayTrongQuy AS (
  SELECT cs.MaCSYT, cs.TenCSYT,
         CASE WHEN (NULLIF(TRIM(cs.TenCSYT), '') IS NOT NULL
                    AND LOCATE(cs.TenCSYT, g.NoiMatChiTiet) > 0)
                OR (NULLIF(TRIM(cs.DiaChi), '') IS NOT NULL
                    AND LOCATE(cs.DiaChi, g.NoiMatChiTiet) > 0)
              THEN 1 ELSE 0 END AS MatTaiCSYT_UocTinh
  FROM CSYT cs
  JOIN Giay_Bao_Tu g ON g.MaCSYT = cs.MaCSYT
  WHERE g.NgayCap >= @dau_quy_truoc AND g.NgayCap < @dau_quy_nay
)
SELECT MaCSYT, TenCSYT, COUNT(*) AS SoGiayBaoTuDaCap,
       SUM(MatTaiCSYT_UocTinh) AS SoCaMatTaiCSYT_UocTinh,
       ROUND(100.0 * SUM(MatTaiCSYT_UocTinh) / COUNT(*), 2) AS TyLeMatTaiCSYT_UocTinh_PhanTram
FROM GiayTrongQuy
GROUP BY MaCSYT, TenCSYT
HAVING COUNT(*) > 50
ORDER BY SoGiayBaoTuDaCap DESC, MaCSYT;

-- 7. SỐ NGƯỜI có hồ sơ không bị từ chối, theo năm mất.
-- Hiệu chỉnh truy vấn 3.4.7: đếm riêng Giay_Bao_Tu có thể tính cả giấy chưa lập hồ sơ.
SELECT YEAR(g.NgayGioMat) AS Nam, COUNT(DISTINCT h.CCCD_NgMat) AS SoNguoiDaMat
FROM Ho_So_Khai_Tu h
JOIN Giay_Bao_Tu g ON g.SoGiayBaoTu = h.SoGiayBaoTu
WHERE h.TrangThaiHoSo <> 'Từ chối'
GROUP BY YEAR(g.NgayGioMat)
ORDER BY Nam;
