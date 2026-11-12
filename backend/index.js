require('dotenv').config();
const app = require('./app');
const { secret } = require('./config/runtime');

const port = Number(process.env.PORT || 3000);
const bindHost = process.env.BIND_HOST || '127.0.0.1';
if (!secret || secret.length < 32) console.warn('Hãy đặt JWT_SECRET dài tối thiểu 32 ký tự trong cấu hình máy chủ.');
app.listen(port, bindHost, () => console.log(`Ứng dụng đang chạy tại http://localhost:${port}`));
