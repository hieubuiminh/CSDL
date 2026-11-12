import { $, api } from './shared.js';

let localAdminRecoveryAvailable = false;

function showAuth(setup, recoveryAvailable = localAdminRecoveryAvailable) {
  localAdminRecoveryAvailable = recoveryAvailable;
  $('#authScreen').classList.remove('hidden'); $('#appShell').classList.add('hidden');
  $('#authTitle').textContent = setup ? 'Tạo tài khoản quản trị' : 'Đăng nhập';
  $('#authForm').classList.remove('hidden'); $('#resetPasswordForm').classList.add('hidden'); $('#registerForm').classList.add('hidden'); $('#adminRecoveryForm').classList.add('hidden');
  $('#forgotPasswordBtn').classList.toggle('hidden', setup); $('#showRegisterBtn').classList.toggle('hidden', setup); $('#backToLoginBtn').classList.add('hidden');
  $('#showAdminRecoveryBtn').classList.toggle('hidden', setup || !localAdminRecoveryAvailable);
  $('#displayNameWrap').classList.toggle('hidden', !setup); $('#initialConfirmWrap').classList.toggle('hidden', !setup);
  $('#initialQuestionWrap').classList.toggle('hidden', !setup); $('#initialAnswerWrap').classList.toggle('hidden', !setup);
  $('#authForm [name=securityQuestion]').required = setup; $('#authForm [name=securityAnswer]').required = setup;
  $('#authForm [name=confirmPassword]').required = setup;
  $('#authSubmit').textContent = setup ? 'Tạo tài khoản quản trị' : 'Đăng nhập';
  $('#authForm [name=password]').autocomplete = setup ? 'new-password' : 'current-password'; $('#authForm [name=displayName]').required = setup;
  $('#authForm').dataset.setup = setup ? 'true' : 'false'; $('#authError').textContent = '';
}

export function initAuth(onLogin) {
  let recoveryQuestionData = null;
  const renderRecoveryMethod = () => {
    if (!recoveryQuestionData) return;
    const useAdminName = recoveryQuestionData.allowAdminNameFallback && (!recoveryQuestionData.hasConfiguredQuestion || $('#recoveryMethod').value === 'admin_name');
    $('#recoveryQuestionText').textContent = useAdminName ? 'Tên người quản trị là gì?' : recoveryQuestionData.question;
    $('#resetPasswordForm [name=securityQuestion]').value = useAdminName ? '__admin_name__' : recoveryQuestionData.questionId;
    $('#adminNameRecoveryNote').classList.toggle('hidden', !useAdminName);
  };
  $('#showRegisterBtn').addEventListener('click', () => {
    $('#authForm').classList.add('hidden'); $('#forgotPasswordBtn').classList.add('hidden'); $('#showRegisterBtn').classList.add('hidden'); $('#showAdminRecoveryBtn').classList.add('hidden');
    $('#registerForm').classList.remove('hidden'); $('#backToLoginBtn').classList.remove('hidden');
    $('#authTitle').textContent = 'Đăng ký tài khoản cán bộ'; $('#authError').textContent = '';
  });
  $('#backToLoginBtn').addEventListener('click', () => {
    $('#registerForm').reset(); $('#registerForm').classList.add('hidden'); $('#backToLoginBtn').classList.add('hidden');
    $('#authForm').classList.remove('hidden'); $('#forgotPasswordBtn').classList.remove('hidden'); $('#showRegisterBtn').classList.remove('hidden');
    $('#showAdminRecoveryBtn').classList.toggle('hidden', !localAdminRecoveryAvailable);
    $('#authTitle').textContent = 'Đăng nhập'; $('#authError').textContent = '';
  });
  $('#registerForm').addEventListener('submit', async event => {
    event.preventDefault(); const form = event.currentTarget; const values = new FormData(form);
    if (values.get('password') !== values.get('confirmPassword')) { $('#authError').textContent = 'Hai mật khẩu chưa trùng khớp.'; return; }
    try {
      await api('/api/auth/register', { method: 'POST', body: JSON.stringify(Object.fromEntries(values.entries())) });
      const username = values.get('username'); form.reset(); $('#backToLoginBtn').click();
      $('#authForm [name=username]').value = username; $('#authError').textContent = 'Đăng ký thành công. Hãy đăng nhập bằng tài khoản vừa tạo.';
    } catch (error) { $('#authError').textContent = error.message; }
  });
  $('#forgotPasswordBtn').addEventListener('click', () => {
    $('#authForm').classList.add('hidden'); $('#forgotPasswordBtn').classList.add('hidden'); $('#registerForm').classList.add('hidden'); $('#showRegisterBtn').classList.add('hidden'); $('#showAdminRecoveryBtn').classList.add('hidden');
    $('#resetPasswordForm').classList.remove('hidden'); $('#authError').textContent = '';
    $('#resetPasswordForm [name=username]').value = $('#authForm [name=username]').value;
    $('#recoveryQuestionWrap').classList.add('hidden'); $('#recoveryAnswerWrap').classList.add('hidden'); $('#resetPasswordSubmit').disabled = true;
  });
  $('#loadRecoveryQuestionBtn').addEventListener('click', async () => {
    const username = $('#resetPasswordForm [name=username]').value.trim(); $('#authError').textContent = '';
    if (!username) { $('#authError').textContent = 'Nhập tên đăng nhập trước.'; return; }
    try {
      const item = await api('/api/auth/recovery-question', { method:'POST', body:JSON.stringify({ username }) });
      recoveryQuestionData = item;
      $('#recoveryMethod').value = item.hasConfiguredQuestion ? 'question' : 'admin_name';
      $('#recoveryMethodWrap').classList.toggle('hidden', !item.hasConfiguredQuestion || !item.allowAdminNameFallback);
      $('#recoveryQuestionWrap').classList.remove('hidden'); $('#recoveryAnswerWrap').classList.remove('hidden');
      $('#resetPasswordForm [name=securityAnswer]').required = true; $('#resetPasswordSubmit').disabled = false;
      renderRecoveryMethod();
    } catch (error) { $('#authError').textContent = error.message; }
  });
  $('#recoveryMethod').addEventListener('change', renderRecoveryMethod);
  $('#resetPasswordForm [name=username]').addEventListener('input', () => {
    $('#recoveryQuestionWrap').classList.add('hidden'); $('#recoveryAnswerWrap').classList.add('hidden'); $('#recoveryQuestionText').textContent = '';
    $('#recoveryMethodWrap').classList.add('hidden'); $('#adminNameRecoveryNote').classList.add('hidden'); recoveryQuestionData = null;
    $('#resetPasswordForm [name=securityQuestion]').value = '';
    $('#resetPasswordForm [name=securityAnswer]').required = false; $('#resetPasswordSubmit').disabled = true;
  });
  $('#cancelResetBtn').addEventListener('click', () => { recoveryQuestionData = null; $('#resetPasswordForm').reset(); $('#recoveryMethodWrap').classList.add('hidden'); $('#adminNameRecoveryNote').classList.add('hidden'); $('#resetPasswordForm').classList.add('hidden'); $('#authForm').classList.remove('hidden'); $('#forgotPasswordBtn').classList.remove('hidden'); $('#showRegisterBtn').classList.remove('hidden'); $('#showAdminRecoveryBtn').classList.toggle('hidden', !localAdminRecoveryAvailable); $('#authError').textContent = ''; });
  $('#resetPasswordForm').addEventListener('submit', async event => {
    event.preventDefault(); const form = event.currentTarget; const values = new FormData(form);
    if (values.get('password') !== values.get('confirmPassword')) { $('#authError').textContent = 'Hai mật khẩu chưa trùng khớp.'; return; }
    try {
      await api('/api/auth/reset-password', { method: 'POST', body: JSON.stringify(Object.fromEntries(values.entries())) });
      recoveryQuestionData = null; $('#authForm [name=username]').value = values.get('username'); form.reset(); $('#recoveryMethodWrap').classList.add('hidden'); $('#adminNameRecoveryNote').classList.add('hidden'); form.classList.add('hidden'); $('#authForm').classList.remove('hidden'); $('#forgotPasswordBtn').classList.remove('hidden'); $('#showRegisterBtn').classList.remove('hidden'); $('#showAdminRecoveryBtn').classList.toggle('hidden', !localAdminRecoveryAvailable);
      $('#authError').textContent = 'Đã đổi mật khẩu. Bạn có thể đăng nhập ngay.';
    } catch (error) { $('#authError').textContent = error.message; }
  });
  $('#showAdminRecoveryBtn').addEventListener('click', () => {
    $('#authForm').classList.add('hidden'); $('#resetPasswordForm').classList.add('hidden'); $('#registerForm').classList.add('hidden');
    $('#forgotPasswordBtn').classList.add('hidden'); $('#showRegisterBtn').classList.add('hidden'); $('#showAdminRecoveryBtn').classList.add('hidden'); $('#backToLoginBtn').classList.add('hidden');
    $('#adminRecoveryForm').reset(); $('#adminRecoveryForm').classList.remove('hidden');
    $('#authTitle').textContent = 'Khôi phục tài khoản quản trị';
    $('#authError').textContent = '';
  });
  $('#cancelAdminRecoveryBtn').addEventListener('click', () => { $('#adminRecoveryForm').reset(); showAuth(false); });
  $('#adminRecoveryForm').addEventListener('submit', async event => {
    event.preventDefault(); const form = event.currentTarget; const values = Object.fromEntries(new FormData(form).entries());
    if (values.newPassword !== values.confirmPassword) { $('#authError').textContent = 'Hai mật khẩu mới chưa trùng khớp.'; return; }
    try {
      await api('/api/auth/local-admin-reset', { method:'POST', body:JSON.stringify(values) });
      const username = values.username; form.reset(); showAuth(false);
      $('#authForm [name=username]').value = username;
      $('#authError').textContent = 'Đã đặt lại mật khẩu. Đăng nhập rồi thiết lập câu hỏi khôi phục trong menu tài khoản.';
    } catch (error) { $('#authError').textContent = error.message; }
  });
  $('#authForm').addEventListener('submit', async event => {
    event.preventDefault(); const form = event.currentTarget; const values = new FormData(form); const setup = form.dataset.setup === 'true';
    if (setup && values.get('password') !== values.get('confirmPassword')) { $('#authError').textContent = 'Hai mật khẩu chưa trùng khớp.'; return; }
    if (setup && !/^[\p{L}\p{N}_.-]{3,40}$/u.test(String(values.get('username') || '').trim())) { $('#authError').textContent = 'Tên đăng nhập cần dài 3–40 ký tự.'; return; }
    try {
      const payload = setup
        ? Object.fromEntries(values.entries())
        : { username: values.get('username'), password: values.get('password') };
      const user = await api(setup ? '/api/auth/setup' : '/api/auth/login', { method: 'POST', body: JSON.stringify(payload) });
      form.reset(); onLogin(user.user);
    } catch (error) {
      if (setup && error.status === 409) { showAuth(false); $('#authForm [name=username]').value = values.get('username'); $('#authError').textContent = 'Tài khoản quản trị đã được tạo. Hãy đăng nhập bằng tài khoản đã lập.'; }
      else $('#authError').textContent = error.message;
    }
  });
  $('#logoutBtn').addEventListener('click', async () => { await api('/api/auth/logout', { method: 'POST' }).catch(() => {}); showAuth(false); });
  (async function boot() {
    for (let attempt = 0; attempt < 10; attempt++) {
      try {
        const auth = await api('/api/auth/status');
        localAdminRecoveryAvailable = Boolean(auth.localAdminRecoveryAvailable);
        if (auth.user) onLogin(auth.user); else showAuth(auth.setupRequired, localAdminRecoveryAvailable);
        return;
      }
      catch (error) {
        const databaseStarting = error.status === 503 && error.message.includes('Không kết nối được MySQL');
        if (error.status >= 400 && !databaseStarting) { $('#authScreen').classList.remove('hidden'); $('#appShell').classList.add('hidden'); $('#authError').textContent = error.message; return; }
        $('#authScreen').classList.remove('hidden'); $('#appShell').classList.add('hidden');
        $('#authError').textContent = attempt < 9 ? (databaseStarting ? 'Đang chờ MySQL khởi động…' : 'Đang chờ máy chủ và cơ sở dữ liệu khởi động…') : error.message || 'Chưa kết nối được. Hãy kiểm tra Docker Desktop và thử tải lại trang sau ít phút.';
        if (attempt < 9) await new Promise(resolve => setTimeout(resolve, 1500));
      }
    }
  })();
}
