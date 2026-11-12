
USE quan_li_khai_tu;

-- =====================================================================
-- 1. TRA CỨU VÀ TRÍCH LỤC HỒ SƠ THEO CCCD NGƯỜI MẤT
-- (đổi giá trị @cccd để tra cứu người khác)
-- =====================================================================
SET @cccd = '001000000001';

SELECT
    nm.HoTen                      AS HoTenNguoiMat,
    nm.NgaySinh,
    gbt.NgayGioMat,
    nn.TenNguyenNhan              AS NguyenNhanMat,
    gbt.MoTaNguyenNhan,
    kt.HoTen                      AS HoTenNguoiKhaiTu,
    hs.QuanHe,
    ub.TenUBND                    AS UBNDCapKhaiTu
FROM Ho_So_Khai_Tu hs
JOIN Giay_Bao_Tu gbt
    ON gbt.SoGiayBaoTu = hs.SoGiayBaoTu
JOIN Cong_Dan nm
    ON nm.CCCD = gbt.CCCD_NgMat
JOIN Cong_Dan kt
    ON kt.CCCD = hs.CCCD_NgKhaiTu
JOIN Nguyen_Nhan nn
    ON nn.MaNguyenNhan = gbt.MaNguyenNhan
JOIN Can_Bo cb
    ON cb.MaCanBo = hs.MaCanBoTiepNhan
JOIN UBND ub
    ON ub.MaUBND = cb.MaUBND
WHERE gbt.CCCD_NgMat = @cccd;


-- =====================================================================
-- 2. THỐNG KÊ SỐ NGƯỜI ĐÃ MẤT THEO GIỚI TÍNH
-- =====================================================================
SELECT
    GioiTinh,
    COUNT(*) AS SoNguoiDaMat
FROM Cong_Dan
WHERE TrangThai = 'Đã mất'
GROUP BY GioiTinh;


-- =====================================================================
-- 3. TOÀN BỘ HỒ SƠ KHAI TỬ
-- =====================================================================
SELECT
    hs.SoGiayKhaiTu,
    nm.HoTen       AS NguoiDaMat,
    kt.HoTen       AS NguoiDangKy,
    hs.NgayDangKi  AS NgayDangKy,
    ub.TenUBND     AS DonViTiepNhan,
    hs.TrangThaiHoSo
FROM Ho_So_Khai_Tu hs
JOIN Giay_Bao_Tu gbt
    ON gbt.SoGiayBaoTu = hs.SoGiayBaoTu
JOIN Cong_Dan nm
    ON nm.CCCD = gbt.CCCD_NgMat
JOIN Cong_Dan kt
    ON kt.CCCD = hs.CCCD_NgKhaiTu
JOIN Can_Bo cb
    ON cb.MaCanBo = hs.MaCanBoTiepNhan
JOIN UBND ub
    ON ub.MaUBND = cb.MaUBND
ORDER BY hs.NgayDangKi, hs.SoGiayKhaiTu;


-- =====================================================================
-- 4. THỐNG KÊ SỐ HỒ SƠ KHAI TỬ THEO ĐỊA BÀN NƠI MẤT (XÃ/PHƯỜNG)
-- Số hồ sơ được đăng ký trong năm hiện tại (theo NgayDangKi).
-- Không tính hồ sơ bị từ chối.
-- LEFT JOIN để xã/phường không có ca nào vẫn được hiển thị.
-- =====================================================================
SELECT
    xp.MaXaPhuong,
    xp.TenXaPhuong,
    COUNT(hs.SoGiayKhaiTu) AS TongSoCaKhaiTu
FROM Noi_Mat xp
LEFT JOIN Giay_Bao_Tu gbt
    ON gbt.MaXaPhuong = xp.MaXaPhuong
LEFT JOIN Ho_So_Khai_Tu hs
    ON hs.SoGiayBaoTu = gbt.SoGiayBaoTu
    AND YEAR(hs.NgayDangKi) = YEAR(CURDATE())
    AND hs.TrangThaiHoSo <> 'Từ chối'
GROUP BY xp.MaXaPhuong, xp.TenXaPhuong
ORDER BY TongSoCaKhaiTu DESC, xp.TenXaPhuong;


-- =====================================================================
-- 5. THỐNG KÊ NGUYÊN NHÂN TỬ VONG THEO ĐỘ TUỔI (MySQL 8+)
-- Tuổi = tuổi tại thời điểm mất.
-- Nhóm: Dưới 18 | 18–60 | Trên 60.
-- Chỉ thống kê các hồ sơ khai tử đã được duyệt.
-- Nếu nhiều nguyên nhân đồng hạng nhất thì hiển thị tất cả.
-- =====================================================================
WITH nguoi_mat AS (
    SELECT
        nn.TenNguyenNhan,
        CASE
            WHEN TIMESTAMPDIFF(YEAR, cd.NgaySinh, gbt.NgayGioMat) < 18
                THEN 'Dưới 18'
            WHEN TIMESTAMPDIFF(YEAR, cd.NgaySinh, gbt.NgayGioMat) <= 60
                THEN '18–60'
            ELSE 'Trên 60'
        END AS NhomTuoi
    FROM Ho_So_Khai_Tu hs
    JOIN Giay_Bao_Tu gbt
        ON gbt.SoGiayBaoTu = hs.SoGiayBaoTu
    JOIN Cong_Dan cd
        ON cd.CCCD = gbt.CCCD_NgMat
    JOIN Nguyen_Nhan nn
        ON nn.MaNguyenNhan = gbt.MaNguyenNhan
    WHERE hs.TrangThaiHoSo = 'Đã duyệt'
),
tong_nhom AS (
    SELECT
        NhomTuoi,
        COUNT(*) AS SoNguoiMat
    FROM nguoi_mat
    GROUP BY NhomTuoi
),
dem_nguyen_nhan AS (
    SELECT
        NhomTuoi,
        TenNguyenNhan,
        COUNT(*) AS SoCa,
        RANK() OVER (
            PARTITION BY NhomTuoi
            ORDER BY COUNT(*) DESC
        ) AS xep_hang
    FROM nguoi_mat
    GROUP BY NhomTuoi, TenNguyenNhan
)
SELECT
    t.NhomTuoi,
    t.SoNguoiMat,
    d.TenNguyenNhan AS NguyenNhanPhoBienNhat,
    d.SoCa AS SoCaCuaNguyenNhanNay
FROM tong_nhom t
JOIN dem_nguyen_nhan d
    ON d.NhomTuoi = t.NhomTuoi
    AND d.xep_hang = 1
ORDER BY FIELD(t.NhomTuoi, 'Dưới 18', '18–60', 'Trên 60');


-- =====================================================================
-- 6. BÁO CÁO CƠ SỞ Y TẾ
-- CSYT cấp trên 50 giấy báo tử trong QUÝ GẦN NHẤT
-- (quý liền trước quý hiện tại).
--
-- Quy ước: ca mất tại CSYT khi NoiMatChiTiet chứa tên hoặc địa chỉ
-- của chính CSYT cấp giấy báo tử.
-- Tỷ lệ được xác định bằng đối chiếu chuỗi, phụ thuộc vào cách ghi
-- địa điểm trong dữ liệu mẫu, không phải quan hệ dữ liệu chuyên biệt.
-- =====================================================================
SET @dau_quy_nay = MAKEDATE(YEAR(CURDATE()), 1)
                   + INTERVAL (QUARTER(CURDATE()) - 1) QUARTER;

SET @dau_quy_truoc = @dau_quy_nay - INTERVAL 1 QUARTER;

SELECT
    cs.MaCSYT,
    cs.TenCSYT,
    COUNT(*) AS SoGiayBaoTuDaCap,
    SUM(
        CASE
            WHEN gbt.NoiMatChiTiet LIKE CONCAT('%', cs.TenCSYT, '%')
              OR gbt.NoiMatChiTiet LIKE CONCAT('%', cs.DiaChi, '%')
            THEN 1
            ELSE 0
        END
    ) AS SoCaMatTaiCSYT,
    ROUND(
        100 * SUM(
            CASE
                WHEN gbt.NoiMatChiTiet LIKE CONCAT('%', cs.TenCSYT, '%')
                  OR gbt.NoiMatChiTiet LIKE CONCAT('%', cs.DiaChi, '%')
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS TyLeMatTaiCSYT_PhanTram
FROM CSYT cs
JOIN Giay_Bao_Tu gbt
    ON gbt.MaCSYT = cs.MaCSYT
WHERE gbt.NgayCap >= @dau_quy_truoc
    AND gbt.NgayCap < @dau_quy_nay
GROUP BY cs.MaCSYT, cs.TenCSYT
HAVING COUNT(*) > 50;


-- =====================================================================
-- 7. THỐNG KÊ SỐ NGƯỜI ĐÃ MẤT THEO NĂM (THEO NĂM MẤT)
-- =====================================================================
SELECT
    YEAR(gbt.NgayGioMat) AS Nam,
    COUNT(*) AS SoNguoiDaMat
FROM Giay_Bao_Tu gbt
GROUP BY YEAR(gbt.NgayGioMat)
ORDER BY Nam;
