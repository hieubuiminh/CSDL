const express = require('express');
const { pool } = require('../../config/database');
const { asyncRoute } = require('../../utils/http');
const { strictWrites, textValue } = require('../../utils/validation');
const { adminOnly } = require('../../middleware/auth');
const { loadWardMetadata, updateWardMetadata } = require('../../utils/ward-metadata');
const { validateCatalog, validateWardMetadata } = require('./validation');
const { recordOfficerId } = require('../../utils/record-scope');

const router = express.Router();

router.get('/lookups', asyncRoute(async (req, res) => {
  const officerId = recordOfficerId(req);
  const [csyt] = await pool.query('SELECT MaCSYT AS id, TenCSYT AS name FROM CSYT ORDER BY TenCSYT');
  const [causes] = await pool.query('SELECT MaNguyenNhan AS id, TenNguyenNhan AS name FROM Nguyen_Nhan ORDER BY TenNguyenNhan');
  const [wardRows] = await pool.query('SELECT MaXaPhuong AS id, TenXaPhuong AS name FROM Noi_Mat ORDER BY TenXaPhuong');
  const metadata = await loadWardMetadata();
  const wards = wardRows.map(ward => ({ ...ward, province: metadata[ward.id]?.province || null, unitType: metadata[ward.id]?.unitType || null }));
  const [officers] = await pool.execute(`SELECT cb.MaCanBo AS id, cb.HoTen AS name, cb.MaUBND AS officeId, u.TenUBND AS officeName FROM Can_Bo cb JOIN UBND u ON u.MaUBND=cb.MaUBND${officerId ? ' WHERE cb.MaCanBo=?' : ''} ORDER BY cb.HoTen`, officerId ? [officerId] : []);
  const [offices] = await pool.query('SELECT MaUBND AS id, TenUBND AS name FROM UBND ORDER BY TenUBND');
  res.json({ csyt, causes, wards, officers, offices });
}));

router.post('/master/:type', adminOnly, asyncRoute(async (req, res) => {
  const body = validateCatalog(req.params.type, req.body);
  const types = {
    cause: { fields: ['id', 'name'], sql: 'INSERT INTO Nguyen_Nhan (MaNguyenNhan,TenNguyenNhan) VALUES (?,?)' },
    hospital: { fields: ['id', 'name', 'address', 'phone'], sql: 'INSERT INTO CSYT (MaCSYT,TenCSYT,DiaChi,SDT) VALUES (?,?,?,?)' },
    ward: { fields: ['id', 'name'], sql: 'INSERT INTO Noi_Mat (MaXaPhuong,TenXaPhuong) VALUES (?,?)' },
    office: { fields: ['id', 'name', 'level', 'address', 'phone'], sql: 'INSERT INTO UBND (MaUBND,TenUBND,CapHanhChinh,DiaChi,SDT) VALUES (?,?,?,?,?)' },
    officer: { fields: ['id', 'identity', 'name', 'role', 'phone', 'officeId'], sql: 'INSERT INTO Can_Bo (MaCanBo,CCCD,HoTen,ChucVu,SDT,MaUBND) VALUES (?,?,?,?,?,?)' }
  };
  const config = types[req.params.type];
  const conn = await pool.getConnection();
  try {
    await strictWrites(conn);
    await conn.execute(config.sql, config.fields.map(key => body[key]));
  } finally { conn.release(); }
  if (req.params.type === 'ward' && body.province && body.unitType) {
    try { await updateWardMetadata(String(body.id).trim(), body); }
    catch (error) {
      console.error('Không thể lưu cấu hình địa bàn:', error.message);
      return res.status(201).json({ ok: true, warning: 'Đã tạo xã/phường. Chưa lưu được cấu hình tỉnh/thành; hãy cập nhật tại mục Phân loại địa bàn.' });
    }
  }
  res.status(201).json({ ok: true });
}));

router.patch('/master/ward/:id', adminOnly, asyncRoute(async (req, res) => {
  const body = validateWardMetadata(req.body);
  const id = textValue(req.params, 'id', 'mã xã/phường', 20);
  const [[ward]] = await pool.execute('SELECT MaXaPhuong FROM Noi_Mat WHERE MaXaPhuong=?', [id]);
  if (!ward) return res.status(404).json({ error: 'Không tìm thấy xã/phường.' });
  await updateWardMetadata(id, body);
  res.json({ ok: true });
}));

module.exports = router;
