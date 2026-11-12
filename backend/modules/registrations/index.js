const express = require('express');
const { pool } = require('../../config/database');
const { asyncRoute } = require('../../utils/http');
const { badRequest, strictWrites, textValue } = require('../../utils/validation');
const { adminOnly } = require('../../middleware/auth');
const { registrationQuery } = require('./queries');
const { validCccd, validateRegistration } = require('./validation');
const { normalizeStatus, statusSql, normalizeRecord } = require('./status');
const { recordScope, recordOfficerId, forbidden } = require('../../utils/record-scope');
const router = express.Router();

router.get('/', asyncRoute(async (req,res) => {
  const scope = recordScope(req);
  const search = `%${String(req.query.search || '').trim()}%`;
  const rawStatus = String(req.query.status || '').trim();
  const status = rawStatus ? normalizeStatus(rawStatus) : '';
  if (rawStatus && !status) throw badRequest('Trạng thái hồ sơ không hợp lệ.');
  const [rows] = await pool.execute(`${registrationQuery} WHERE (?='' OR (${statusSql('h.TrangThaiHoSo')})=?) AND (?='%%' OR h.SoGiayKhaiTu LIKE ? OR g.SoGiayBaoTu LIKE ? OR d.HoTen LIKE ? OR d.CCCD LIKE ? OR a.HoTen LIKE ? OR a.CCCD LIKE ?)${scope.sql} ORDER BY h.NgayDangKi, h.SoGiayKhaiTu`, [status,status,search,search,search,search,search,search,search,...scope.params]);
  res.json(rows.map(normalizeRecord));
}));
router.get('/:cccd', asyncRoute(async (req,res) => {
  const scope = recordScope(req);
  if (!validCccd(req.params.cccd)) return res.status(400).json({ error: 'CCCD của người mất phải gồm đúng 12 chữ số.' });
  const [rows] = await pool.execute(`${registrationQuery} WHERE d.CCCD=?${scope.sql} ORDER BY h.NgayDangKi DESC, h.SoGiayKhaiTu DESC LIMIT 1`, [req.params.cccd,...scope.params]);
  if (!rows.length) return res.status(404).json({ error: 'Chưa tìm thấy hồ sơ theo CCCD này.' });
  res.json(normalizeRecord(rows[0]));
}));
router.post('/', asyncRoute(async (req,res) => {
  const officerId = recordOfficerId(req);
  const b = validateRegistration(req.body);
  if (officerId && b.registration.officerId !== officerId) throw forbidden('Chỉ được lập hồ sơ do chính cán bộ của tài khoản tiếp nhận.');
  const conn = await pool.getConnection();
  try {
    await strictWrites(conn);
    await conn.beginTransaction();
    // Reuse an existing citizen without replacing their registered information.
    const citizenSql = `INSERT INTO Cong_Dan (CCCD,HoTen,NgaySinh,GioiTinh,QueQuan,DanToc,SDT,TrangThai)
      VALUES (?,?,?,?,?,?,?,'Còn sống') ON DUPLICATE KEY UPDATE CCCD=Cong_Dan.CCCD`;
    for (const person of [b.deceased,b.applicant]) await conn.execute(citizenSql, [person.cccd,person.name,person.birthDate,person.gender,person.hometown,person.ethnicity,person.phone]);
    await conn.execute('INSERT INTO Giay_Bao_Tu (SoGiayBaoTu,NgayCap,NgayGioMat,NoiMatChiTiet,MoTaNguyenNhan,CCCD_NgMat,MaNguyenNhan,MaXaPhuong,MaCSYT) VALUES (?,?,?,?,?,?,?,?,?)', [b.certificate.id,b.certificate.issuedAt,b.certificate.deathAt,b.certificate.placeDetail,b.certificate.causeDescription,b.deceased.cccd,b.certificate.causeId,b.certificate.wardId,b.certificate.hospitalId]);
    await conn.execute('INSERT INTO Ho_So_Khai_Tu (SoGiayKhaiTu,NgayDangKi,QuanHe,TrangThaiHoSo,SoGiayBaoTu,CCCD_NgKhaiTu,MaCanBoTiepNhan) VALUES (?,?,?,?,?,?,?)', [b.registration.id,b.registration.registeredAt,b.registration.relation,b.registration.status,b.certificate.id,b.applicant.cccd,b.registration.officerId]);
    if (b.burial) {
      await conn.execute('INSERT INTO An_Tang (MaAnTang,HinhThuc,TenNghiaTrang,NgayAnTang,SoGiayKhaiTu) VALUES (?,?,?,?,?)', [b.burial.id,b.burial.form,b.burial.cemetery,b.burial.date,b.registration.id]);
    }
    if (b.registration.status !== 'Từ chối') await conn.execute("UPDATE Cong_Dan SET TrangThai='Đã mất' WHERE CCCD=?", [b.deceased.cccd]);
    await conn.commit();
    res.status(201).json({ id: b.registration.id, status: b.registration.status, message: 'Đã tạo hồ sơ khai tử.' });
  } catch (error) { await conn.rollback(); throw error; } finally { conn.release(); }
}));
router.patch('/:id/status', asyncRoute(async (req,res) => {
  const scope = recordScope(req);
  const status = normalizeStatus(req.body?.status);
  if (!status) throw badRequest('Trạng thái hồ sơ không hợp lệ.');
  const id = textValue(req.params, 'id', 'số hồ sơ', 20);
  const conn = await pool.getConnection();
  try {
    await strictWrites(conn);
    await conn.beginTransaction();
    const [[record]] = await conn.execute(`SELECT g.CCCD_NgMat FROM Ho_So_Khai_Tu h JOIN Giay_Bao_Tu g ON g.SoGiayBaoTu=h.SoGiayBaoTu WHERE h.SoGiayKhaiTu=?${scope.sql} FOR UPDATE`, [id,...scope.params]);
    if (!record) {
      await conn.rollback();
      return res.status(404).json({ error: 'Không tìm thấy hồ sơ.' });
    }
    await conn.execute(`UPDATE Ho_So_Khai_Tu h SET h.TrangThaiHoSo=? WHERE h.SoGiayKhaiTu=?${scope.sql}`, [status,id,...scope.params]);
    if (status !== 'Từ chối') await conn.execute("UPDATE Cong_Dan SET TrangThai='Đã mất' WHERE CCCD=?", [record.CCCD_NgMat]);
    await conn.commit();
    res.json({ ok: true, status });
  } catch (error) { await conn.rollback(); throw error; } finally { conn.release(); }
}));


router.delete('/:id', adminOnly, asyncRoute(async (req,res) => {
  const id = textValue(req.params, 'id', 'số hồ sơ', 20);
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    const [[record]] = await conn.execute('SELECT h.SoGiayBaoTu, g.CCCD_NgMat, h.CCCD_NgKhaiTu FROM Ho_So_Khai_Tu h JOIN Giay_Bao_Tu g ON g.SoGiayBaoTu=h.SoGiayBaoTu WHERE h.SoGiayKhaiTu=? FOR UPDATE', [id]);
    if (!record) {
      await conn.rollback();
      return res.status(404).json({ error: 'Không tìm thấy hồ sơ cần xóa.' });
    }
    await conn.execute('DELETE FROM An_Tang WHERE SoGiayKhaiTu=?', [id]);
    await conn.execute('DELETE FROM Ho_So_Khai_Tu WHERE SoGiayKhaiTu=?', [id]);
    await conn.execute('DELETE FROM Giay_Bao_Tu WHERE SoGiayBaoTu=? AND NOT EXISTS (SELECT 1 FROM Ho_So_Khai_Tu WHERE SoGiayBaoTu=?)', [record.SoGiayBaoTu, record.SoGiayBaoTu]);
    await conn.commit();
    res.json({ ok: true, deletedCitizens: 0, message: 'Đã xóa hồ sơ khai tử.' });
  } catch (error) {
    await conn.rollback();
    throw error;
  } finally { conn.release(); }
}));
module.exports = router;
