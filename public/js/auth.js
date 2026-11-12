import { $, api, clearSessionData, showNotice } from './shared.js';

let localAdminRecoveryAvailable = false;
let authReady = false;
const sessionChangedKey = 'khaiTuSessionChanged';
let pageReloading = false;

function reloadSession(broadcast = true) {
  pageReloading = true; authReady = false;
  clearSessionData();
  if (broadcast) {
    try { localStorage.setItem(sessionChangedKey, `${Date.now()}:${Math.random()}`); } catch { /* A page reload still clears this tab when storage is unavailable. */ }
  }
  window.location.reload();
}

function showAuth(setup, recoveryAvailable = localAdminRecoveryAvailable) {
  clearSessionData();
  authReady = true; $('#authSubmit').disabled = false; $('#authRetryBtn').classList.add('hidden');
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

function showAuthUnavailable(message, loading = false) {
  authReady = false;
  $('#authScreen').classList.remove('hidden'); $('#appShell').classList.add('hidden');
  $('#authTitle').textContent = loading ? 'Đang kết nối' : 'Chưa sẵn sàng';
  ['authForm','registerForm','resetPasswordForm','adminRecoveryForm','forgotPasswordBtn','showRegisterBtn','backToLoginBtn','showAdminRecoveryBtn'].forEach(id => $(`#${id}`).classList.add('hidden'));
  $('#authSubmit').disabled = true;
  $('#authRetryBtn').classList.toggle('hidden', loading);
  $('#authRetryBtn').disabled = loading;
  $('#authError').textContent = message;
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
    event.preventDefault(); if (!authReady) return; const form = event.currentTarget; const values = new FormData(form);
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
    event.preventDefault(); if (!authReady) return; const form = event.currentTarget; const values = new FormData(form);
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
    event.preventDefault(); if (!authReady) return; const form = event.currentTarget; const values = Object.fromEntries(new FormData(form).entries());
    if (values.newPassword !== values.confirmPassword) { $('#authError').textContent = 'Hai mật khẩu mới chưa trùng khớp.'; return; }
    try {
      await api('/api/auth/local-admin-reset', { method:'POST', body:JSON.stringify(values) });
      const username = values.username; form.reset(); showAuth(false);
      $('#authForm [name=username]').value = username;
      $('#authError').textContent = 'Đã đặt lại mật khẩu. Đăng nhập rồi thiết lập câu hỏi khôi phục trong menu tài khoản.';
    } catch (error) { $('#authError').textContent = error.message; }
  });
  $('#authForm').addEventListener('submit', async event => {
    event.preventDefault(); if (!authReady) return; const form = event.currentTarget; const values = new FormData(form); const setup = form.dataset.setup === 'true';
    if (setup && values.get('password') !== values.get('confirmPassword')) { $('#authError').textContent = 'Hai mật khẩu chưa trùng khớp.'; return; }
    if (setup && !/^[\p{L}\p{N}_.-]{3,40}$/u.test(String(values.get('username') || '').trim())) { $('#authError').textContent = 'Tên đăng nhập cần dài 3–40 ký tự.'; return; }
    authReady = false; $('#authSubmit').disabled = true;
    let authUnavailable = false;
    try {
      const payload = setup
        ? Object.fromEntries(values.entries())
        : { username: values.get('username'), password: values.get('password') };
      await api(setup ? '/api/auth/setup' : '/api/auth/login', { method: 'POST', body: JSON.stringify(payload) });
      reloadSession();
    } catch (error) {
      if (setup && error.status === 409) {
        try {
          const status = await api('/api/auth/status');
          showAuth(status.setupRequired, Boolean(status.localAdminRecoveryAvailable));
          $('#authForm [name=username]').value = values.get('username');
          $('#authError').textContent = status.setupRequired ? error.message : 'Tài khoản quản trị đã được tạo. Hãy đăng nhập bằng tài khoản đã lập.';
        } catch (statusError) { authUnavailable = true; showAuthUnavailable(statusError.message); }
      } else $('#authError').textContent = error.message;
    } finally {
      if (!pageReloading && !authUnavailable) { authReady = true; $('#authSubmit').disabled = false; }
    }
  });
  $('#logoutBtn').addEventListener('click', async event => {
    const button = event.currentTarget; button.disabled = true;
    try {
      await api('/api/auth/logout', { method:'POST' });
      reloadSession();
    } catch (error) {
      button.disabled = false; showNotice(error.message || 'Chưa thể đăng xuất. Hãy thử lại.', true);
    }
  });
  window.addEventListener('pageshow', event => { if (event.persisted) reloadSession(false); });
  window.addEventListener('storage', event => { if (event.key === sessionChangedKey) reloadSession(false); });
  let statusLoading = false;
  async function checkAuthStatus() {
    if (statusLoading) return;
    statusLoading = true;
    showAuthUnavailable('', true);
    try {
      for (let attempt = 0; attempt < 10; attempt++) {
        try {
          const status = await api('/api/auth/status');
          localAdminRecoveryAvailable = Boolean(status.localAdminRecoveryAvailable);
          if (status.user) {
            authReady = true; $('#authRetryBtn').classList.add('hidden'); onLogin(status.user);
          } else showAuth(status.setupRequired, localAdminRecoveryAvailable);
          return;
        } catch (error) {
          const databaseStarting = error.status === 503 && error.message.includes('Không kết nối được MySQL');
          if (error.status >= 400 && !databaseStarting || attempt === 9) {
            showAuthUnavailable(error.message || 'Chưa kết nối được máy chủ.'); return;
          }
          showAuthUnavailable(databaseStarting ? 'Đang chờ MySQL khởi động…' : 'Đang chờ máy chủ khởi động…', true);
          await new Promise(resolve => setTimeout(resolve, 1500));
        }
      }
    } finally { statusLoading = false; $('#authRetryBtn').disabled = false; }
  }
  $('#authRetryBtn').addEventListener('click', checkAuthStatus);
  checkAuthStatus();
}
