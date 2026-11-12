function errorHandler(err, _req, res, _next) {
  if (err.type === 'entity.parse.failed') return res.status(400).json({ error: 'Dữ liệu JSON không hợp lệ.' });
  if (err.type === 'entity.too.large') return res.status(413).json({ error: 'Dữ liệu gửi lên quá lớn.' });
  console.error(err);
  if (err.statusCode) return res.status(err.statusCode).json({ error: err.message });
  if (err.code === 'ER_NO_SUCH_TABLE') return res.status(503).json({ error: 'Thiếu bảng dữ liệu tài khoản hoặc danh mục. Hãy chạy database/app_setup.sql và kiểm tra lại cấu hình cơ sở dữ liệu.' });
  if (['ER_ACCESS_DENIED_ERROR', 'ER_TABLEACCESS_DENIED_ERROR'].includes(err.code)) return res.status(503).json({ error: 'MySQL từ chối kết nối hoặc quyền truy cập bảng. Kiểm tra DB_USER, DB_PASSWORD và quyền trên cơ sở dữ liệu.' });
  if (err.code === 'ECONNREFUSED') return res.status(503).json({ error: 'Không kết nối được MySQL. Hãy kiểm tra Docker Desktop và trạng thái dịch vụ cơ sở dữ liệu.' });
  if (err.code === 'ER_DUP_ENTRY') return res.status(409).json({ error: 'Số giấy hoặc CCCD này đã được dùng cho hồ sơ khác.' });
  if (err.code === 'ER_NO_REFERENCED_ROW_2') return res.status(400).json({ error: 'Một mã lựa chọn không tồn tại. Hãy kiểm tra danh mục UBND, cán bộ, nguyên nhân, xã/phường và cơ sở y tế.' });
  if (err.code === 'ER_CHECK_CONSTRAINT_VIOLATED') return res.status(400).json({ error: 'Dữ liệu vi phạm ràng buộc nghiệp vụ.' });
  if (['ER_DATA_TOO_LONG', 'WARN_DATA_TRUNCATED', 'ER_TRUNCATED_WRONG_VALUE_FOR_FIELD', 'ER_TRUNCATED_WRONG_VALUE'].includes(err.code)) return res.status(400).json({ error: 'Dữ liệu vượt độ dài hoặc không phù hợp với cột dữ liệu hiện có. Hãy kiểm tra giá trị nhập và cấu trúc CSDL đang sử dụng.' });
  res.status(500).json({ error: process.env.NODE_ENV === 'production' ? 'Có lỗi máy chủ. Vui lòng thử lại.' : (err.message || 'Lỗi máy chủ.') });
}

module.exports = { errorHandler };
