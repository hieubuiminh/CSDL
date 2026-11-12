const genderQuery = `SELECT c.GioiTinh AS name, COUNT(*) AS value
  FROM Cong_Dan c WHERE c.TrangThai='Đã mất'
  GROUP BY c.GioiTinh ORDER BY value DESC, c.GioiTinh`;
const yearQuery = `SELECT YEAR(g.NgayGioMat) AS year, COUNT(*) AS value
  FROM Giay_Bao_Tu g GROUP BY YEAR(g.NgayGioMat) ORDER BY year`;
const areaQuery = `SELECT nm.MaXaPhuong AS id, nm.TenXaPhuong AS name,
  COUNT(h.SoGiayKhaiTu) AS value
  FROM Noi_Mat nm
  LEFT JOIN Giay_Bao_Tu g ON g.MaXaPhuong=nm.MaXaPhuong
  LEFT JOIN Ho_So_Khai_Tu h ON h.SoGiayBaoTu=g.SoGiayBaoTu
    AND h.NgayDangKi >= ? AND h.NgayDangKi < ? AND h.TrangThaiHoSo <> 'Từ chối'
  GROUP BY nm.MaXaPhuong, nm.TenXaPhuong ORDER BY value DESC, nm.TenXaPhuong`;
const ageCauseQuery = `SELECT CASE
    WHEN TIMESTAMPDIFF(YEAR, d.NgaySinh, g.NgayGioMat) IS NULL THEN '__unknown__'
    WHEN g.NgayGioMat < d.NgaySinh THEN '__invalid__'
    WHEN TIMESTAMPDIFF(YEAR, d.NgaySinh, g.NgayGioMat) < 18 THEN 'Dưới 18'
    WHEN TIMESTAMPDIFF(YEAR, d.NgaySinh, g.NgayGioMat) <= 60 THEN '18–60'
    ELSE 'Trên 60' END AS ageGroup,
    n.TenNguyenNhan AS cause, COUNT(*) AS value
  FROM Ho_So_Khai_Tu h
  JOIN Giay_Bao_Tu g ON g.SoGiayBaoTu=h.SoGiayBaoTu
  JOIN Cong_Dan d ON d.CCCD=g.CCCD_NgMat
  JOIN Nguyen_Nhan n ON n.MaNguyenNhan=g.MaNguyenNhan
  WHERE h.TrangThaiHoSo='Đã duyệt'
  GROUP BY ageGroup, n.TenNguyenNhan`;
const hospitalQuery = `SELECT c.MaCSYT AS id, c.TenCSYT AS name, COUNT(*) AS value,
  SUM(CASE WHEN g.NoiMatChiTiet LIKE CONCAT('%',c.TenCSYT,'%')
    OR g.NoiMatChiTiet LIKE CONCAT('%',c.DiaChi,'%') THEN 1 ELSE 0 END) AS estimatedDeaths,
  ROUND(100 * SUM(CASE WHEN g.NoiMatChiTiet LIKE CONCAT('%',c.TenCSYT,'%')
    OR g.NoiMatChiTiet LIKE CONCAT('%',c.DiaChi,'%') THEN 1 ELSE 0 END) / COUNT(*), 2) AS estimatedPercent
  FROM Giay_Bao_Tu g JOIN CSYT c ON c.MaCSYT=g.MaCSYT
  WHERE g.NgayCap >= ? AND g.NgayCap < ?
  GROUP BY c.MaCSYT, c.TenCSYT HAVING COUNT(*) > 50 ORDER BY value DESC, c.TenCSYT`;
// ADMIN uses the original queries above. Staff queries add a receiving-officer
// predicate without changing the reporting date, status or threshold rules.
function scopedReport(name, officerId, params = []) {
  const queries = { gender: genderQuery, years: yearQuery, areas: areaQuery, ageCauses: ageCauseQuery, hospitals: hospitalQuery };
  let sql = queries[name];
  if (!sql) throw new Error('Báo cáo không hợp lệ.');
  if (!officerId) return { sql, params };
  const ownCertificate = `EXISTS (SELECT 1 FROM Ho_So_Khai_Tu own_h
    WHERE own_h.SoGiayBaoTu=g.SoGiayBaoTu AND own_h.MaCanBoTiepNhan=?)`;
  switch (name) {
    case 'gender':
      sql = sql.replace('\n  GROUP BY', ` AND EXISTS (SELECT 1 FROM Giay_Bao_Tu own_g
        JOIN Ho_So_Khai_Tu own_h ON own_h.SoGiayBaoTu=own_g.SoGiayBaoTu
        WHERE own_g.CCCD_NgMat=c.CCCD AND own_h.MaCanBoTiepNhan=?)\n  GROUP BY`);
      break;
    case 'years':
      sql = sql.replace(' GROUP BY', ` WHERE ${ownCertificate} GROUP BY`);
      break;
    case 'areas':
      // Keep the condition inside LEFT JOIN so wards with no own records stay 0.
      sql = sql.replace('\n  GROUP BY', ' AND h.MaCanBoTiepNhan=?\n  GROUP BY');
      break;
    case 'ageCauses':
      sql = sql.replace('\n  GROUP BY', ' AND h.MaCanBoTiepNhan=?\n  GROUP BY');
      break;
    case 'hospitals':
      sql = sql.replace('\n  GROUP BY', ` AND ${ownCertificate}\n  GROUP BY`);
      break;
  }
  if (sql === queries[name] || !sql.includes('MaCanBoTiepNhan=?')) {
    throw new Error('Không thể áp dụng phạm vi cán bộ cho báo cáo.');
  }
  return { sql, params: [...params, officerId] };
}

module.exports = { genderQuery, yearQuery, areaQuery, ageCauseQuery, hospitalQuery, scopedReport };
