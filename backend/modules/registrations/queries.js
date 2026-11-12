const registrationQuery = `SELECT h.SoGiayKhaiTu AS id, h.NgayDangKi AS registeredAt,
  h.QuanHe AS relation, h.TrangThaiHoSo AS status,
  d.CCCD AS deceasedId, d.HoTen AS deceasedName, d.NgaySinh AS birthDate,
  a.CCCD AS applicantId, a.HoTen AS applicantName, g.NgayGioMat AS deathAt,
  n.TenNguyenNhan AS cause, g.MoTaNguyenNhan AS causeDescription,
  u.MaUBND AS officeId, u.TenUBND AS officeName, cb.HoTen AS officerName, h.MaCanBoTiepNhan AS officerId,
  g.SoGiayBaoTu AS certificateId, cs.TenCSYT AS hospitalName
  FROM Ho_So_Khai_Tu h
  JOIN Giay_Bao_Tu g ON g.SoGiayBaoTu = h.SoGiayBaoTu
  JOIN Cong_Dan d ON d.CCCD = g.CCCD_NgMat
  JOIN Cong_Dan a ON a.CCCD = h.CCCD_NgKhaiTu
  JOIN Nguyen_Nhan n ON n.MaNguyenNhan = g.MaNguyenNhan
  JOIN Can_Bo cb ON cb.MaCanBo = h.MaCanBoTiepNhan
  JOIN UBND u ON u.MaUBND = cb.MaUBND
  JOIN CSYT cs ON cs.MaCSYT = g.MaCSYT`;

module.exports = { registrationQuery };
